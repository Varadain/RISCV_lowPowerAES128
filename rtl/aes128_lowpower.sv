//==============================================================
// File: AES128_lowPower.sv
// Description:
// Top-level AES-128 encryption module with low-power clock gating
// and an 8-bit external interface to keep FPGA pin usage low.
//==============================================================

module AES128_lowPower (
    input  wire       clk,            // System clock
    input  wire       reset,          // Asynchronous reset
    input  wire       clk_en,         // Clock enable (power optimization)
    input  wire       test_mode,      // DFT test mode: bypasses clock gating
    input  wire       scan_enable,    // DFT scan shift enable
    input  wire       scan_in,        // Serial scan input
    input  wire       load,           // Load one byte into plaintext/key
    input  wire       load_sel,       // 0 = plaintext, 1 = key
    input  wire [3:0] load_index,     // Byte index, 0 = MSB byte
    input  wire [7:0] data_in,        // Byte input data
    input  wire       start,          // Start encryption
    input  wire [3:0] data_out_index, // Ciphertext byte index, 0 = MSB byte
    output wire [7:0] data_out,       // Selected ciphertext byte
    output wire       done,           // Completion flag
    output wire       scan_out,       // Serial scan output
    output wire       gated_clk_dbg   // Debug view of internal gated clock
);

    reg [127:0] plaintext_reg;
    reg [127:0] key_reg;
    wire [127:0] ciphertext;
    wire        core_scan_in;
    wire        core_scan_out;

    AES128_lowPower_core CORE (
        .clk(clk),
        .reset(reset),
        .clk_en(clk_en),
        .test_mode(test_mode),
        .scan_enable(scan_enable),
        .scan_in(core_scan_in),
        .start(start),
        .plaintext(plaintext_reg),
        .key(key_reg),
        .ciphertext(ciphertext),
        .done(done),
        .scan_out(core_scan_out),
        .gated_clk_dbg(gated_clk_dbg)
    );

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            plaintext_reg <= 128'd0;
            key_reg       <= 128'd0;
        end else if (test_mode && scan_enable) begin
            // DFT scan hook for top-level interface registers. During scan
            // shift, the ungated system clock is used so scan chains cannot be
            // blocked by functional low-power clock gating.
            {key_reg, plaintext_reg} <= {key_reg[126:0], plaintext_reg, scan_in};
        end else if (clk_en && load) begin
            if (load_sel) begin
                key_reg[127 - (load_index * 8) -: 8] <= data_in;
            end else begin
                plaintext_reg[127 - (load_index * 8) -: 8] <= data_in;
            end
        end
    end

    assign data_out = ciphertext[127 - (data_out_index * 8) -: 8];
    assign core_scan_in = key_reg[127];
    assign scan_out = core_scan_out;

endmodule

//==============================================================
// Module: aes_clock_gate
// Description:
// Latch-based integrated-clock-gate style model for ASIC-oriented
// verification. The enable is captured while clk is low, preventing
// enable changes near the active edge from creating runt pulses.
//
// In FPGA synthesis flows, vendors often map clock enables to dedicated
// register CE pins rather than physically gating the clock tree. This model
// is included to make low-power intent, DFT bypass, and verification targets
// explicit for ASIC-style research.
//==============================================================
module aes_clock_gate (
    input  wire clk,
    input  wire reset,
    input  wire enable,
    input  wire test_mode,
    output wire gated_clk
);
    reg enable_latched;

    always @(*) begin
        if (reset) begin
            enable_latched = 1'b0;
        end else if (!clk) begin
            enable_latched = enable;
        end
    end

    // test_mode bypass keeps the scan clock controllable during ATPG/scan.
    assign gated_clk = test_mode ? clk : (clk & enable_latched);
endmodule

module AES128_lowPower_core (
    input  wire         clk,        // System clock
    input  wire         reset,      // Asynchronous reset
    input  wire         clk_en,     // Clock enable (power optimization)
    input  wire         test_mode,  // DFT test mode bypasses clock gating
    input  wire         scan_enable,// Scan shift enable
    input  wire         scan_in,    // Serial scan input
    input  wire         start,      // Start encryption
    input  wire [127:0] plaintext,  // Input data
    input  wire [127:0] key,        // Encryption key
    output reg  [127:0] ciphertext, // Output data
    output reg          done,       // Completion flag
    output wire         scan_out,   // Serial scan output
    output wire         gated_clk_dbg
);

    // Internal state register (AES state matrix flattened)
    reg [127:0] state;

    // Current round key
    reg [127:0] round_key;

    // Round counter (AES-128 has 10 rounds)
    reg [3:0] round;

    // Intermediate transformation outputs
    wire [127:0] sb_out;           // SubBytes output
    wire [127:0] sr_out;           // ShiftRows output
    wire [127:0] mc_out;           // MixColumns output
    wire [127:0] next_round_key;   // Next key from key expansion
    wire         gated_clk;
    wire         functional_enable;

    assign functional_enable = clk_en && (start || (round != 4'd0));
    assign gated_clk_dbg = gated_clk;
    assign scan_out = done;

    //================ Submodules =================//

    // Byte substitution (non-linear transformation)
    sub_bytes SB (.in(state), .out(sb_out));

    // Row shifting (permutation)
    shift_rows SR (.in(sb_out), .out(sr_out));

    // Column mixing (diffusion)
    mix_columns MC (.in(sr_out), .out(mc_out));

    // Key expansion (generates round keys)
    key_expand KE (.key(round_key), .round(round), .next_key(next_round_key));

    // Low-power clock gate. During functional mode it only clocks the core
    // while an encryption is active or being started. During test_mode the
    // ungated clock is passed through so scan shifting remains controllable.
    aes_clock_gate CG_CORE (
        .clk(clk),
        .reset(reset),
        .enable(functional_enable),
        .test_mode(test_mode),
        .gated_clk(gated_clk)
    );

    //================ AES Control =================//

    always @(posedge gated_clk or posedge reset) begin
        if (reset) begin
            // Reset all internal registers
            state      <= 128'd0;
            round_key  <= 128'd0;
            round      <= 4'd0;
            ciphertext <= 128'd0;
            done       <= 1'b0;
        end

        else if (test_mode && scan_enable) begin
            // DFT scan chain for core observability/controllability:
            // scan_in -> state -> round_key -> ciphertext -> round -> done.
            // This is a scan hook model; ASIC implementation can replace
            // these muxes with library scan flops during synthesis/DFT.
            {done, round, ciphertext, round_key, state} <=
                {round, ciphertext, round_key, state, scan_in};
        end

        // Functional operation is reached only when the gated clock pulses.
        else begin

            // Initial step: AddRoundKey
            if (start) begin
                state     <= plaintext ^ key;
                round_key <= key;
                round     <= 4'd1;
                done      <= 1'b0;
            end

            // Rounds 1 to 9 (full AES round)
            else if ((round != 4'd0) && (round < 4'd10)) begin
                state     <= mc_out ^ next_round_key;
                round_key <= next_round_key;
                round     <= round + 4'd1;
            end

            // Final round (no MixColumns)
            else if (round == 4'd10) begin
                state      <= sr_out ^ next_round_key;
                ciphertext <= sr_out ^ next_round_key;
                done       <= 1'b1;
                round      <= 4'd0;
            end
        end
    end

endmodule

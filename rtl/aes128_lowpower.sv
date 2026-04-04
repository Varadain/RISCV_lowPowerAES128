//==============================================================
// File: aes128_lowpower.sv
// Description:
// Top-level AES-128 encryption module with low-power clock gating
//==============================================================

module aes128_lowpower (
    input  wire         clk,        // System clock
    input  wire         reset,      // Asynchronous reset
    input  wire         clk_en,     // Clock enable (power optimization)
    input  wire         start,      // Start encryption
    input  wire [127:0] plaintext,  // Input data
    input  wire [127:0] key,        // Encryption key
    output reg  [127:0] ciphertext, // Output data
    output reg          done        // Completion flag
);

    // Internal state register (AES state matrix flattened)
    reg [127:0] state;

    // Current round key
    reg [127:0] round_key;

    // Round counter (AES-128 → 10 rounds)
    reg [3:0] round;

    // Intermediate transformation outputs
    wire [127:0] sb_out;           // SubBytes output
    wire [127:0] sr_out;           // ShiftRows output
    wire [127:0] mc_out;           // MixColumns output
    wire [127:0] next_round_key;   // Next key from key expansion

    //================ Submodules =================//

    // Byte substitution (non-linear transformation)
    sub_bytes SB (.in(state), .out(sb_out));

    // Row shifting (permutation)
    shift_rows SR (.in(sb_out), .out(sr_out));

    // Column mixing (diffusion)
    mix_columns MC (.in(sr_out), .out(mc_out));

    // Key expansion (generates round keys)
    key_expand KE (.key(round_key), .round(round), .next_key(next_round_key));

    //================ AES Control =================//

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset all internal registers
            state      <= 0;
            round_key  <= 0;
            round      <= 0;
            ciphertext <= 0;
            done       <= 0;
        end

        // Only operate when clock enable is active (low-power feature)
        else if (clk_en) begin

            // Initial step: AddRoundKey
            if (start) begin
                state     <= plaintext ^ key;
                round_key <= key;
                round     <= 1;
                done      <= 0;
            end

            // Rounds 1 to 9 (full AES round)
            else if (round < 10) begin
                state     <= mc_out ^ next_round_key;
                round_key <= next_round_key;
                round     <= round + 1;
            end

            // Final round (no MixColumns)
            else if (round == 10) begin
                state      <= sr_out ^ next_round_key;
                ciphertext <= sr_out ^ next_round_key;
                done       <= 1;
                round      <= 0;
            end
        end
    end

endmodule

// -----------------------------------------------------------------------------
// Top-level AES-128 sequential encryption core.
// File order starts here so readers see the external interface and FSM first.
// -----------------------------------------------------------------------------

module AES128_updated_new (
    input  wire         clk,
    input  wire         reset,
    input  wire         start,
    output reg          busy,
    output reg          done,
    input  wire [127:0] plaintext,
    input  wire [127:0] key,
    output reg  [127:0] ciphertext
);

localparam S_IDLE       = 4'd0;
localparam S_SUB_START  = 4'd1;
localparam S_SUB_WAIT   = 4'd2;
localparam S_MIX_START  = 4'd3;
localparam S_MIX_WAIT   = 4'd4;
localparam S_KEY_START  = 4'd5;
localparam S_KEY_WAIT   = 4'd6;
localparam S_DONE       = 4'd7;

(* preserve = 1 *) reg [3:0]   state;
(* preserve = 1 *) reg [127:0] state_reg;
(* preserve = 1 *) reg [127:0] round_key;
(* preserve = 1 *) reg [3:0]   round;

wire [127:0] sb_out;
wire [127:0] mix_out;
wire [127:0] new_key;
wire         sbox_done;
wire         mix_done;
wire         key_done;

reg sbox_start;
reg mix_start;
reg key_start;

// AES state is stored as four 32-bit columns: b0..b3, b4..b7, b8..b11, b12..b15.
// ShiftRows rotates row 1 by 1 byte, row 2 by 2 bytes, and row 3 by 3 bytes.
function [127:0] shift_rows;
    input [127:0] s;
    reg [7:0] b0;  reg [7:0] b1;  reg [7:0] b2;  reg [7:0] b3;
    reg [7:0] b4;  reg [7:0] b5;  reg [7:0] b6;  reg [7:0] b7;
    reg [7:0] b8;  reg [7:0] b9;  reg [7:0] b10; reg [7:0] b11;
    reg [7:0] b12; reg [7:0] b13; reg [7:0] b14; reg [7:0] b15;
    begin
        {b0, b1, b2, b3, b4, b5, b6, b7, b8, b9, b10, b11, b12, b13, b14, b15} = s;
        shift_rows = {b0, b5, b10, b15, b4, b9, b14, b3, b8, b13, b2, b7, b12, b1, b6, b11};
    end
endfunction

(* keep = 1 *) wire [127:0] initial_addroundkey;
(* keep = 1 *) wire [127:0] state_after_shiftrows;
(* keep = 1 *) wire [127:0] state_after_roundkey;
(* keep = 1 *) wire         final_round;

assign initial_addroundkey  = plaintext ^ key;
assign state_after_shiftrows = shift_rows(sb_out);
assign state_after_roundkey = state_reg ^ new_key;
assign final_round          = (round == 4'd10);

AES_SBOX_SEQ   u_sbox (.clk(clk), .reset(reset), .start(sbox_start), .in_block(state_reg), .out_block(sb_out),  .done(sbox_done));
AES_MIXCOL_SEQ u_mix  (.clk(clk), .reset(reset), .start(mix_start),  .in_block(state_reg), .out_block(mix_out), .done(mix_done));
AES_KEYEXP_SEQ u_key  (.clk(clk), .reset(reset), .start(key_start),  .round(round), .in_key(round_key), .out_key(new_key), .done(key_done));

always @(posedge clk or posedge reset) begin
    if (reset) begin
        state       <= S_IDLE;
        busy        <= 1'b0;
        done        <= 1'b0;
        round       <= 4'd1;
        state_reg   <= 128'd0;
        round_key   <= 128'd0;
        ciphertext  <= 128'd0;
        sbox_start  <= 1'b0;
        mix_start   <= 1'b0;
        key_start   <= 1'b0;
    end else begin
        // Starts are one-cycle pulses unless a state below asserts one.
        sbox_start <= 1'b0;
        mix_start  <= 1'b0;
        key_start  <= 1'b0;

        case (state)
            S_IDLE: begin
                busy <= 1'b0;
                done <= 1'b0;
                if (start) begin
                    state_reg <= initial_addroundkey;
                    round_key <= key;
                    round     <= 4'd1;
                    busy      <= 1'b1;
                    state     <= S_SUB_START;
                end
            end

            S_SUB_START: begin
                sbox_start <= 1'b1;
                state      <= S_SUB_WAIT;
            end

            S_SUB_WAIT: begin
                if (sbox_done) begin
                    state_reg <= state_after_shiftrows;
                    state     <= S_KEY_START;
                    if (!final_round) begin
                        state <= S_MIX_START;
                    end
                end
            end

            S_MIX_START: begin
                mix_start <= 1'b1;
                state     <= S_MIX_WAIT;
            end

            S_MIX_WAIT: begin
                if (mix_done) begin
                    state_reg <= mix_out;
                    state     <= S_KEY_START;
                end
            end

            S_KEY_START: begin
                key_start <= 1'b1;
                state     <= S_KEY_WAIT;
            end

            S_KEY_WAIT: begin
                if (key_done) begin
                    round_key <= new_key;
                    state_reg <= state_after_roundkey;

                    if (final_round) begin
                        ciphertext <= state_after_roundkey;
                        state      <= S_DONE;
                    end else begin
                        round <= round + 4'd1;
                        state <= S_SUB_START;
                    end
                end
            end

            S_DONE: begin
                done  <= 1'b1;
                busy  <= 1'b0;
                state <= S_IDLE;
            end

            default: begin
                state <= S_IDLE;
            end
        endcase
    end
end
endmodule

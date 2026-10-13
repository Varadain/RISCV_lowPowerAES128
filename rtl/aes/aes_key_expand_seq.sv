// -----------------------------------------------------------------------------
// AES-128 round-key expansion block.
//
// AES-128 starts with four 32-bit key words. Each round derives four new words:
//   W0' = W0 XOR SubWord(RotWord(W3)) XOR Rcon
//   W1' = W1 XOR W0'
//   W2' = W2 XOR W1'
//   W3' = W3 XOR W2'
//
// The equations below are written in expanded form but implement this standard
// recurrence. One request produces one complete 128-bit round key.
// -----------------------------------------------------------------------------

module AES_KEYEXP_SEQ (
    input  wire         clk,
    input  wire         reset,
    input  wire         start,
    input  wire [3:0]   round,
    input  wire [127:0] in_key,
    output reg  [127:0] out_key,
    output reg          done
);

// running turns the external start pulse into a small two-step transaction.
(* preserve = 1 *) reg        running;
wire [7:0] b0;
wire [7:0] b1;
wire [7:0] b2;
wire [7:0] b3;
(* keep = 1 *) reg [31:0] temp;

// RotWord followed by SubWord on the previous key's last word.
AES_SBOX_ROM s0 (.a(in_key[23:16]), .c(b0));
AES_SBOX_ROM s1 (.a(in_key[15:8]),  .c(b1));
AES_SBOX_ROM s2 (.a(in_key[7:0]),   .c(b2));
AES_SBOX_ROM s3 (.a(in_key[31:24]), .c(b3));

// AES round constant placed in the most-significant byte of a 32-bit word.
function [31:0] RCON;
    input [3:0] r;
    begin
        case (r)
            4'd1:  RCON = 32'h01000000;
            4'd2:  RCON = 32'h02000000;
            4'd3:  RCON = 32'h04000000;
            4'd4:  RCON = 32'h08000000;
            4'd5:  RCON = 32'h10000000;
            4'd6:  RCON = 32'h20000000;
            4'd7:  RCON = 32'h40000000;
            4'd8:  RCON = 32'h80000000;
            4'd9:  RCON = 32'h1b000000;
            4'd10: RCON = 32'h36000000;
            default: RCON = 32'h00000000;
        endcase
    end
endfunction

// Round-key handshake and output register.
always @(posedge clk or posedge reset) begin
    if (reset) begin
        running <= 1'b0;
        done    <= 1'b0;
        out_key <= 128'd0;
    end else begin
        done <= 1'b0;

        if (start && !running) begin
            // Accept the request; combinational S-box outputs settle for use on
            // the following running cycle.
            running <= 1'b1;
        end else if (running) begin
            // g(W3) = SubWord(RotWord(W3)) XOR Rcon.
            temp = {b0, b1, b2, b3} ^ RCON(round);

            // Generate the four chained words of the next round key.
            out_key[127:96] <= in_key[127:96] ^ temp;
            out_key[95:64]  <= in_key[95:64]  ^ in_key[127:96] ^ temp;
            out_key[63:32]  <= in_key[63:32]  ^ in_key[95:64]  ^ in_key[127:96] ^ temp;
            out_key[31:0]   <= in_key[31:0]   ^ in_key[63:32]  ^ in_key[95:64]  ^ in_key[127:96] ^ temp;

            // The complete next-round key becomes valid with done.
            running <= 1'b0;
            done    <= 1'b1;
        end
    end
end
endmodule

//==============================================================
// File: key_expand.sv
// Description:
// AES-128 key expansion (generates next round key)
//==============================================================

module key_expand(
    input  [127:0] key,
    input  [3:0]   round,
    output [127:0] next_key
);

    // Split into 4 words (32-bit each)
    wire [31:0] w0 = key[127:96];
    wire [31:0] w1 = key[95:64];
    wire [31:0] w2 = key[63:32];
    wire [31:0] w3 = key[31:0];

    wire [31:0] subword;

    // RotWord + SubWord (core AES key schedule step)
    aes_sbox s0(w3[23:16], subword[31:24]);
    aes_sbox s1(w3[15:8],  subword[23:16]);
    aes_sbox s2(w3[7:0],   subword[15:8]);
    aes_sbox s3(w3[31:24], subword[7:0]);

    // Round constant
    wire [31:0] rcon = rcon_lut(round);

    // Generate next words
    wire [31:0] nw0 = w0 ^ subword ^ rcon;
    wire [31:0] nw1 = w1 ^ nw0;
    wire [31:0] nw2 = w2 ^ nw1;
    wire [31:0] nw3 = w3 ^ nw2;

    assign next_key = {nw0, nw1, nw2, nw3};

    // RCON lookup table
    function [31:0] rcon_lut(input [3:0] r);
        case (r)
            4'd1:  rcon_lut = 32'h01_00_00_00;
            4'd2:  rcon_lut = 32'h02_00_00_00;
            4'd3:  rcon_lut = 32'h04_00_00_00;
            4'd4:  rcon_lut = 32'h08_00_00_00;
            4'd5:  rcon_lut = 32'h10_00_00_00;
            4'd6:  rcon_lut = 32'h20_00_00_00;
            4'd7:  rcon_lut = 32'h40_00_00_00;
            4'd8:  rcon_lut = 32'h80_00_00_00;
            4'd9:  rcon_lut = 32'h1B_00_00_00;
            4'd10: rcon_lut = 32'h36_00_00_00;
            default: rcon_lut = 32'h0;
        endcase
    endfunction

endmodule

//==============================================================
// File: mix_col.sv
// Description:
// Performs Galois Field multiplication for one column
//==============================================================

module mix_col(
    input  [31:0] a,
    output [31:0] y
);

    // Multiply by 2 in GF(2^8)
    function [7:0] xtime(input [7:0] b);
        xtime = {b[6:0],1'b0} ^ (8'h1b & {8{b[7]}});
    endfunction

    // Split into 4 bytes
    wire [7:0] s0 = a[31:24];
    wire [7:0] s1 = a[23:16];
    wire [7:0] s2 = a[15:8];
    wire [7:0] s3 = a[7:0];

    // MixColumns transformation matrix multiplication
    assign y = {
        xtime(s0)^xtime(s1)^s1^s2^s3,
        s0^xtime(s1)^xtime(s2)^s2^s3,
        s0^s1^xtime(s2)^xtime(s3)^s3,
        xtime(s0)^s0^s1^s2^xtime(s3)
    };

endmodule

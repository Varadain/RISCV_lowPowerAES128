//==============================================================
// File: sub_bytes.sv
// Description:
// Applies AES S-box substitution to all 16 bytes
//==============================================================

module sub_bytes(
    input  [127:0] in,   // 16 bytes input
    output [127:0] out   // 16 bytes output
);

    genvar i;

    // Generate 16 parallel S-box instances (one per byte)
    generate
        for (i = 0; i < 16; i = i + 1) begin : SBOX_GEN
            aes_sbox S (
                .a(in[8*i +: 8]),   // Extract byte
                .d(out[8*i +: 8])   // Replace with S-box output
            );
        end
    endgenerate

endmodule

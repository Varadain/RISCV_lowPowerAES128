//==============================================================
// File: mix_columns.sv
// Description:
// Applies MixColumns transformation on 4 columns
//==============================================================

module mix_columns(
    input  [127:0] in,
    output [127:0] out
);

    genvar i;

    // Each 32-bit block is one AES column
    generate
        for (i = 0; i < 4; i = i + 1) begin : MIX_GEN
            mix_col MC (
                .a(in[32*i +: 32]),
                .y(out[32*i +: 32])
            );
        end
    endgenerate

endmodule

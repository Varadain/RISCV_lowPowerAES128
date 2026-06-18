// -----------------------------------------------------------------------------
// Sequential SubBytes block: substitutes one byte per clock for 16 clocks.
//
// Reusing one S-box ROM instead of sixteen parallel S-boxes greatly reduces
// combinational area. idx selects which input byte is being transformed.
// out_block is filled from the most-significant byte toward the least-
// significant byte, preserving the project's AES state ordering.
// -----------------------------------------------------------------------------

module AES_SBOX_SEQ (
    input  wire         clk,
    input  wire         reset,
    input  wire         start,
    input  wire [127:0] in_block,
    output reg  [127:0] out_block,
    output reg          done
);

// running prevents a second start from restarting an active substitution.
(* preserve = 1 *) reg        running;
(* preserve = 1 *) reg [3:0]  idx;
(* keep = 1 *) wire [7:0] s_in;
wire [7:0] s_out;

AES_SBOX_ROM rom (.a(s_in), .c(s_out));

// Select one byte per clock from MSB to LSB.
assign s_in = in_block[127 - (idx * 8) -: 8];

// Sequential controller for the 16 byte lookups.
always @(posedge clk or posedge reset) begin
    if (reset) begin
        idx       <= 4'd0;
        done      <= 1'b0;
        running   <= 1'b0;
        out_block <= 128'd0;
    end else begin
        done <= 1'b0;

        if (start && !running) begin
            // Begin at byte zero. The first substitution is stored on the next
            // running cycle.
            idx     <= 4'd0;
            running <= 1'b1;
        end else if (running) begin
            // Store this cycle's S-box result in the matching byte position.
            out_block[127 - (idx * 8) -: 8] <= s_out;

            if (idx == 4'd15) begin
                // All sixteen bytes have been replaced.
                running <= 1'b0;
                done    <= 1'b1;
            end else begin
                idx <= idx + 4'd1;
            end
        end
    end
end
endmodule

// ============================================================
// UART Transmitter
// 8-N-1 transmitter with a programmable baud divisor.
// The bit tick occurs every baud_div_i + 1 clock cycles.
//
// 8-N-1 means:
//   - one low start bit,
//   - eight data bits, least-significant bit first,
//   - no parity bit,
//   - one high stop bit.
//
// Example:
//   For a 50 MHz clock and 115200 baud, the ideal number of clock cycles per
//   UART bit is 50,000,000 / 115,200 = 434. Since this counter includes zero,
//   software normally programs baud_div_i to 433.
// ============================================================
module uart_tx (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        clk_en_i,
    input  logic        start_i,
    input  logic [7:0]  data_i,
    input  logic [15:0] baud_div_i,
    output logic        tx_o,
    output logic        busy_o,
    output logic        done_o
);

    // Ten-bit frame register: {stop, data[7:0], start}.
    logic [9:0]  shifter;

    // Number of frame bits still waiting to be transmitted.
    logic [3:0]  bit_count;

    // Divides the system clock down to one update per UART bit period.
    logic [15:0] baud_count;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // UART is idle high by convention.
            tx_o        <= 1'b1;
            busy_o      <= 1'b0;
            done_o      <= 1'b0;
            shifter     <= 10'h3ff;
            bit_count   <= 4'd0;
            baud_count  <= 16'd0;
        end else begin
            // done_o is a one-clock completion pulse.
            done_o <= 1'b0;

            if (clk_en_i) begin
                if (start_i && !busy_o) begin
                    // Load the complete frame. tx_o is driven low immediately
                    // so the receiver sees the start bit without an extra tick.
                    shifter    <= {1'b1, data_i, 1'b0}; // stop, data, start
                    bit_count  <= 4'd10;
                    baud_count <= baud_div_i;
                    busy_o     <= 1'b1;
                    tx_o       <= 1'b0;
                end else if (busy_o) begin
                    if (baud_count != 16'd0) begin
                        // Hold the current serial bit for its full baud period.
                        baud_count <= baud_count - 16'd1;
                    end else begin
                        // Advance to the next frame bit.
                        baud_count <= baud_div_i;
                        shifter    <= {1'b1, shifter[9:1]};
                        bit_count  <= bit_count - 4'd1;

                        if (bit_count == 4'd1) begin
                            // The stop bit has completed; return to idle high.
                            busy_o <= 1'b0;
                            done_o <= 1'b1;
                            tx_o   <= 1'b1;
                        end else begin
                            // shifter[1] becomes the next output after shifting.
                            tx_o <= shifter[1];
                        end
                    end
                end
            end
        end
    end

endmodule

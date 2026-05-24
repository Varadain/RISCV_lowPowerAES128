// ============================================================
// UART Transmitter
// 8-N-1 transmitter with a programmable baud divisor.
// The bit tick occurs every baud_div_i + 1 clock cycles.
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

    logic [9:0]  shifter;
    logic [3:0]  bit_count;
    logic [15:0] baud_count;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_o        <= 1'b1;
            busy_o      <= 1'b0;
            done_o      <= 1'b0;
            shifter     <= 10'h3ff;
            bit_count   <= 4'd0;
            baud_count  <= 16'd0;
        end else begin
            done_o <= 1'b0;

            if (clk_en_i) begin
                if (start_i && !busy_o) begin
                    shifter    <= {1'b1, data_i, 1'b0}; // stop, data, start
                    bit_count  <= 4'd10;
                    baud_count <= baud_div_i;
                    busy_o     <= 1'b1;
                    tx_o       <= 1'b0;
                end else if (busy_o) begin
                    if (baud_count != 16'd0) begin
                        baud_count <= baud_count - 16'd1;
                    end else begin
                        baud_count <= baud_div_i;
                        shifter    <= {1'b1, shifter[9:1]};
                        bit_count  <= bit_count - 4'd1;

                        if (bit_count == 4'd1) begin
                            busy_o <= 1'b0;
                            done_o <= 1'b1;
                            tx_o   <= 1'b1;
                        end else begin
                            tx_o <= shifter[1];
                        end
                    end
                end
            end
        end
    end

endmodule

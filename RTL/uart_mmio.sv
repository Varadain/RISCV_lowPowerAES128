// ============================================================
// UART MMIO Peripheral
//
// Base address: 0x0000_0500
//   0x00 TXDATA     [7:0] byte to transmit; write starts TX when idle
//   0x04 STATUS     [0] busy, [1] done
//   0x08 CONTROL    [0] enable, [1] clear done
//   0x0C BAUD_DIV   [15:0] baud divisor
// ============================================================
module uart_mmio (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        clk_en_i,
    input  logic [31:0] addr_i,
    input  logic [31:0] write_data_i,
    input  logic        write_en_i,
    input  logic        read_en_i,
    output logic [31:0] read_data_o,
    output logic        uart_tx_o,
    output logic        tx_busy_o,
    output logic        tx_done_o,
    output logic        tx_done_irq_o,
    output logic        active_o
);

    localparam logic [5:0] OFF_TXDATA   = 6'h00;
    localparam logic [5:0] OFF_STATUS   = 6'h04;
    localparam logic [5:0] OFF_CONTROL  = 6'h08;
    localparam logic [5:0] OFF_BAUD_DIV = 6'h0C;

    logic [5:0]  reg_offset;
    logic [7:0]  tx_data_reg;
    logic [15:0] baud_div_reg;
    logic        enable_reg;
    logic        done_latched;
    logic        tx_start_pulse;
    logic        tx_done_pulse;

    assign reg_offset = addr_i[5:0];
    assign tx_done_o = done_latched;
    assign tx_done_irq_o = done_latched;
    assign active_o = tx_busy_o;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_data_reg    <= 8'h00;
            baud_div_reg   <= 16'd15;
            enable_reg     <= 1'b1;
            done_latched   <= 1'b0;
            tx_start_pulse <= 1'b0;
        end else begin
            tx_start_pulse <= 1'b0;

            if (clk_en_i) begin
                if (tx_done_pulse) begin
                    done_latched <= 1'b1;
                end

                if (write_en_i) begin
                    case (reg_offset)
                        OFF_TXDATA: begin
                            tx_data_reg <= write_data_i[7:0];
                            if (enable_reg && !tx_busy_o) begin
                                tx_start_pulse <= 1'b1;
                                done_latched   <= 1'b0;
                            end
                        end
                        OFF_CONTROL: begin
                            enable_reg <= write_data_i[0];
                            if (write_data_i[1]) begin
                                done_latched <= 1'b0;
                            end
                        end
                        OFF_BAUD_DIV: baud_div_reg <= write_data_i[15:0];
                        default: ;
                    endcase
                end
            end
        end
    end

    always_comb begin
        read_data_o = 32'h0;
        if (read_en_i) begin
            case (reg_offset)
                OFF_TXDATA:   read_data_o = {24'h0, tx_data_reg};
                OFF_STATUS:   read_data_o = {30'h0, done_latched, tx_busy_o};
                OFF_CONTROL:  read_data_o = {31'h0, enable_reg};
                OFF_BAUD_DIV: read_data_o = {16'h0, baud_div_reg};
                default:      read_data_o = 32'h0;
            endcase
        end
    end

    uart_tx u_uart_tx (
        .clk       (clk),
        .rst_n     (rst_n),
        .clk_en_i  (clk_en_i && enable_reg),
        .start_i   (tx_start_pulse),
        .data_i    (tx_data_reg),
        .baud_div_i(baud_div_reg),
        .tx_o      (uart_tx_o),
        .busy_o    (tx_busy_o),
        .done_o    (tx_done_pulse)
    );

endmodule

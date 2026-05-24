// ============================================================
// Simple Interrupt Controller
//
// Base address: 0x0000_0600
//   0x00 IRQ_PENDING [0] AES, [1] UART TX done, [2] sensor ready, [3] DMA done
//   0x04 IRQ_ENABLE  same bit layout
//   0x08 IRQ_CLEAR   write 1 to clear pending bits
// ============================================================
module simple_intc (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        clk_en_i,
    input  logic [31:0] addr_i,
    input  logic [31:0] write_data_i,
    input  logic        write_en_i,
    input  logic        read_en_i,
    input  logic        aes_done_irq_i,
    input  logic        uart_tx_done_irq_i,
    input  logic        sensor_data_ready_irq_i,
    input  logic        dma_done_irq_i,
    output logic [31:0] read_data_o,
    output logic        irq_o
);

    localparam logic [5:0] OFF_PENDING = 6'h00;
    localparam logic [5:0] OFF_ENABLE  = 6'h04;
    localparam logic [5:0] OFF_CLEAR   = 6'h08;

    logic [5:0] reg_offset;
    logic [3:0] pending_reg;
    logic [3:0] enable_reg;
    logic [3:0] irq_sources;

    assign reg_offset = addr_i[5:0];
    assign irq_sources = {
        dma_done_irq_i,
        sensor_data_ready_irq_i,
        uart_tx_done_irq_i,
        aes_done_irq_i
    };
    assign irq_o = |(pending_reg & enable_reg);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pending_reg <= 4'h0;
            enable_reg  <= 4'h0;
        end else if (clk_en_i) begin
            pending_reg <= pending_reg | irq_sources;

            if (write_en_i) begin
                case (reg_offset)
                    OFF_ENABLE: enable_reg <= write_data_i[3:0];
                    OFF_CLEAR:  pending_reg <= (pending_reg | irq_sources) & ~write_data_i[3:0];
                    default: ;
                endcase
            end
        end
    end

    always_comb begin
        read_data_o = 32'h0;
        if (read_en_i) begin
            case (reg_offset)
                OFF_PENDING: read_data_o = {28'h0, pending_reg};
                OFF_ENABLE:  read_data_o = {28'h0, enable_reg};
                default:     read_data_o = 32'h0;
            endcase
        end
    end

endmodule

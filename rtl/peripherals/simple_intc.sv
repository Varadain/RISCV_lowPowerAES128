// ============================================================
// Simple Interrupt Controller
//
// Base address: 0x0000_0600
//   0x00 IRQ_PENDING [0] AES, [1] UART TX done, [2] sensor ready, [3] DMA done
//   0x04 IRQ_ENABLE  same bit layout
//   0x08 IRQ_CLEAR   write 1 to clear pending bits
//
// Each incoming source is converted into a sticky pending bit. This prevents
// short peripheral events from being lost before software reads them.
// irq_o becomes high when any pending source is also enabled.
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

    // pending_reg records events; enable_reg controls which events contribute
    // to the combined interrupt output.
    logic [5:0] reg_offset;
    logic [3:0] pending_reg;
    logic [3:0] enable_reg;
    logic [3:0] irq_sources;

    assign reg_offset = addr_i[5:0];
    // Keep the bit ordering identical to the documented register map.
    assign irq_sources = {
        dma_done_irq_i,
        sensor_data_ready_irq_i,
        uart_tx_done_irq_i,
        aes_done_irq_i
    };
    // Reduction OR creates one combined interrupt line.
    assign irq_o = |(pending_reg & enable_reg);

    // Capture new events and process software writes.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pending_reg <= 4'h0;
            enable_reg  <= 4'h0;
        end else if (clk_en_i) begin
            // OR operation makes every observed event sticky.
            pending_reg <= pending_reg | irq_sources;

            if (write_en_i) begin
                case (reg_offset)
                    // A zero in enable_reg masks the source from irq_o but does
                    // not prevent its pending bit from being recorded.
                    OFF_ENABLE: enable_reg <= write_data_i[3:0];

                    // Write-one-to-clear. irq_sources is ORed first so an event
                    // arriving in the clear cycle is handled deterministically.
                    OFF_CLEAR:  pending_reg <= (pending_reg | irq_sources) & ~write_data_i[3:0];
                    default: ;
                endcase
            end
        end
    end

    // CPU-visible pending and enable registers.
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

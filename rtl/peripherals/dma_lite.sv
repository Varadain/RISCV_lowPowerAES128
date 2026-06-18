// ============================================================
// DMA-lite MMIO Engine
//
// Base address: 0x0000_0700
//   0x00 DMA_SRC_ADDR
//   0x04 DMA_DST_ADDR
//   0x08 DMA_LEN       word count
//   0x0C DMA_CTRL      [0] start, [1] clear done
//   0x10 DMA_STATUS    [0] busy, [1] done
//
// This is a one-word-per-cycle memory-copy accelerator. It exposes a
// lightweight second port for data_mem so the CPU pipeline does not become
// a full bus-mastering design.
//
// Transfer model:
//   source address = SRC + 4*index
//   destination    = DST + 4*index
//   one 32-bit word is written on each enabled busy cycle
//   transfer completes after LEN words
// ============================================================
module dma_lite (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        clk_en_i,
    input  logic [31:0] addr_i,
    input  logic [31:0] write_data_i,
    input  logic        write_en_i,
    input  logic        read_en_i,
    input  logic [31:0] dma_read_data_i,
    output logic [31:0] read_data_o,
    output logic [31:0] dma_read_addr_o,
    output logic [31:0] dma_write_addr_o,
    output logic [31:0] dma_write_data_o,
    output logic        dma_write_en_o,
    output logic        busy_o,
    output logic        done_o,
    output logic        done_irq_o,
    output logic        active_o
);

    localparam logic [5:0] OFF_SRC    = 6'h00;
    localparam logic [5:0] OFF_DST    = 6'h04;
    localparam logic [5:0] OFF_LEN    = 6'h08;
    localparam logic [5:0] OFF_CTRL   = 6'h0C;
    localparam logic [5:0] OFF_STATUS = 6'h10;

    // Configuration registers programmed by CPU stores.
    logic [5:0]  reg_offset;
    logic [31:0] src_addr_reg;
    logic [31:0] dst_addr_reg;
    logic [31:0] len_reg;
    // Current word number within the active transfer.
    logic [31:0] index_reg;

    assign reg_offset = addr_i[5:0];
    assign done_irq_o = done_o;
    assign active_o = busy_o;

    // Appending two zero bits multiplies the word index by four bytes.
    assign dma_read_addr_o  = src_addr_reg + {index_reg[29:0], 2'b00};
    assign dma_write_addr_o = dst_addr_reg + {index_reg[29:0], 2'b00};
    // The engine directly forwards the word returned by the read port.
    assign dma_write_data_o = dma_read_data_i;

    // One destination write occurs for every enabled cycle while busy.
    assign dma_write_en_o   = clk_en_i && busy_o;

    // Configuration, start, and progress state.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            src_addr_reg <= 32'h0;
            dst_addr_reg <= 32'h0;
            len_reg      <= 32'h0;
            index_reg    <= 32'h0;
            busy_o       <= 1'b0;
            done_o       <= 1'b0;
        end else if (clk_en_i) begin
            if (write_en_i) begin
                case (reg_offset)
                    OFF_SRC: src_addr_reg <= write_data_i;
                    OFF_DST: dst_addr_reg <= write_data_i;
                    OFF_LEN: len_reg      <= write_data_i;
                    OFF_CTRL: begin
                        // CTRL[1] acknowledges a completed transfer.
                        if (write_data_i[1]) begin
                            done_o <= 1'b0;
                        end
                        // CTRL[0] starts from index zero. A zero-length request
                        // completes immediately without entering busy state.
                        if (write_data_i[0] && !busy_o) begin
                            index_reg <= 32'h0;
                            busy_o    <= (len_reg != 32'h0);
                            done_o    <= (len_reg == 32'h0);
                        end
                    end
                    default: ;
                endcase
            end

            if (busy_o) begin
                // The current combinational addresses and data are written this
                // cycle. Afterwards, update completion state and next index.
                if (index_reg + 32'd1 >= len_reg) begin
                    busy_o <= 1'b0;
                    done_o <= 1'b1;
                end
                index_reg <= index_reg + 32'd1;
            end
        end
    end

    // CPU readback of programmed addresses, length, and transfer status.
    always_comb begin
        read_data_o = 32'h0;
        if (read_en_i) begin
            case (reg_offset)
                OFF_SRC:    read_data_o = src_addr_reg;
                OFF_DST:    read_data_o = dst_addr_reg;
                OFF_LEN:    read_data_o = len_reg;
                OFF_STATUS: read_data_o = {30'h0, done_o, busy_o};
                default:    read_data_o = 32'h0;
            endcase
        end
    end

endmodule

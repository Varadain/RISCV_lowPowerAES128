// ============================================================
// MEM STAGE / Lightweight IoT Security SoC Interconnect
//
// Normal RAM remains at low memory. MMIO ranges:
//   0x0000_0300 AES / AES-CTR
//   0x0000_0400 Sensor MMIO + Intel Avalon SPI sensor I/O window
//   0x0000_0500 UART MMIO
//   0x0000_0600 Interrupt controller
//   0x0000_0700 DMA-lite
//   0x0000_0800 Power/activity control
// ============================================================
module mem_stage (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [31:0] addr_i,
    input  logic [31:0] write_data_i,
    input  logic        mem_read_i,
    input  logic        mem_write_i,
    output logic [31:0] read_data_o,

    output logic        uart_tx_o,
    input  logic        spi_miso_i,
    output logic        spi_mosi_o,
    output logic        spi_sclk_o,
    output logic        spi_ss_n_o,
    output logic        irq_o,
    output logic        sleep_o,
    output logic        aes_done_o,
    output logic [31:0] aes_ciphertext_debug_o,
    output logic [31:0] activity_counter_debug_o
);

    logic [2:0]  ls_tag;
    logic [31:0] eff_addr;

    logic [31:0] raw_mem_word;
    logic [31:0] merged_store_word;
    logic [31:0] mem_read_data;

    logic aes_sel;
    logic sensor_sel;
    logic uart_sel;
    logic intc_sel;
    logic dma_sel;
    logic power_sel;
    logic mmio_sel;

    logic aes_write_en;
    logic aes_read_en;
    logic sensor_write_en;
    logic sensor_read_en;
    logic uart_write_en;
    logic uart_read_en;
    logic intc_write_en;
    logic intc_read_en;
    logic dma_write_en;
    logic dma_read_en;
    logic power_write_en;
    logic power_read_en;

    logic data_mem_read_en;
    logic data_mem_write_en;

    logic [31:0] aes_read_data;
    logic [31:0] sensor_read_data;
    logic [31:0] uart_read_data;
    logic [31:0] intc_read_data;
    logic [31:0] dma_read_data;
    logic [31:0] power_read_data;

    logic aes_done_irq;
    logic aes_active;
    logic sensor_ready_irq;
    logic sensor_active;
    logic uart_busy;
    logic uart_done;
    logic uart_done_irq;
    logic uart_active;
    logic dma_busy;
    logic dma_done;
    logic dma_done_irq;
    logic dma_active;

    logic [31:0] dma_mem_read_addr;
    logic [31:0] dma_mem_write_addr;
    logic [31:0] dma_mem_write_data;
    logic        dma_mem_write_en;
    logic [31:0] dma_mem_read_data;

    assign ls_tag   = addr_i[31:29];
    assign eff_addr = {3'b000, addr_i[28:0]};

    assign aes_sel    = (eff_addr[31:8] == 24'h000003);
    assign sensor_sel = (eff_addr[31:8] == 24'h000004);
    assign uart_sel   = (eff_addr[31:8] == 24'h000005);
    assign intc_sel   = (eff_addr[31:8] == 24'h000006);
    assign dma_sel    = (eff_addr[31:8] == 24'h000007);
    assign power_sel  = (eff_addr[31:8] == 24'h000008);
    assign mmio_sel   = aes_sel | sensor_sel | uart_sel | intc_sel | dma_sel | power_sel;

    assign aes_write_en    = mem_write_i & aes_sel;
    assign aes_read_en     = mem_read_i  & aes_sel;
    assign sensor_write_en = mem_write_i & sensor_sel;
    assign sensor_read_en  = mem_read_i  & sensor_sel;
    assign uart_write_en   = mem_write_i & uart_sel;
    assign uart_read_en    = mem_read_i  & uart_sel;
    assign intc_write_en   = mem_write_i & intc_sel;
    assign intc_read_en    = mem_read_i  & intc_sel;
    assign dma_write_en    = mem_write_i & dma_sel;
    assign dma_read_en     = mem_read_i  & dma_sel;
    assign power_write_en  = mem_write_i & power_sel;
    assign power_read_en   = mem_read_i  & power_sel;

    assign data_mem_read_en  = (mem_read_i | mem_write_i) & ~mmio_sel;
    assign data_mem_write_en = mem_write_i & ~mmio_sel;

    load_store_unit u_load_store_unit (
        .ls_tag_i           (ls_tag),
        .byte_off_i         (eff_addr[1:0]),
        .mem_word_i         (raw_mem_word),
        .store_data_i       (write_data_i),
        .load_data_o        (mem_read_data),
        .merged_store_word_o(merged_store_word)
    );

    data_mem u_data_mem (
        .clk             (clk),
        .rst_n           (rst_n),
        .addr_i          (eff_addr),
        .write_data_i    ((ls_tag == 3'b000) ? write_data_i : merged_store_word),
        .mem_read_i      (data_mem_read_en),
        .mem_write_i     (data_mem_write_en),
        .read_data_o     (raw_mem_word),
        .dma_read_addr_i (dma_mem_read_addr),
        .dma_write_addr_i(dma_mem_write_addr),
        .dma_write_data_i(dma_mem_write_data),
        .dma_write_en_i  (dma_mem_write_en),
        .dma_read_data_o (dma_mem_read_data)
    );

    aes_mmio u_aes_mmio (
        .clk           (clk),
        .rst_n         (rst_n),
        .clk_en_i      (!sleep_o),
        .addr_i        (eff_addr),
        .write_data_i  (write_data_i),
        .write_en_i    (aes_write_en),
        .read_en_i     (aes_read_en),
        .read_data_o   (aes_read_data),
        .aes_done_irq_o(aes_done_irq),
        .ciphertext_debug_o(aes_ciphertext_debug_o),
        .active_o      (aes_active)
    );

    sensor_spi_mmio u_sensor_spi_mmio (
        .clk                 (clk),
        .rst_n               (rst_n),
        .clk_en_i            (!sleep_o),
        .addr_i              (eff_addr),
        .write_data_i        (write_data_i),
        .write_en_i          (sensor_write_en),
        .read_en_i           (sensor_read_en),
        .spi_miso_i          (spi_miso_i),
        .spi_mosi_o          (spi_mosi_o),
        .spi_sclk_o          (spi_sclk_o),
        .spi_ss_n_o          (spi_ss_n_o),
        .read_data_o         (sensor_read_data),
        .data_ready_irq_o    (sensor_ready_irq),
        .active_o            (sensor_active)
    );

    uart_mmio u_uart_mmio (
        .clk          (clk),
        .rst_n        (rst_n),
        .clk_en_i     (!sleep_o),
        .addr_i       (eff_addr),
        .write_data_i (write_data_i),
        .write_en_i   (uart_write_en),
        .read_en_i    (uart_read_en),
        .read_data_o  (uart_read_data),
        .uart_tx_o    (uart_tx_o),
        .tx_busy_o    (uart_busy),
        .tx_done_o    (uart_done),
        .tx_done_irq_o(uart_done_irq),
        .active_o     (uart_active)
    );

    simple_intc u_simple_intc (
        .clk                    (clk),
        .rst_n                  (rst_n),
        .clk_en_i               (1'b1),
        .addr_i                 (eff_addr),
        .write_data_i           (write_data_i),
        .write_en_i             (intc_write_en),
        .read_en_i              (intc_read_en),
        .aes_done_irq_i         (aes_done_irq),
        .uart_tx_done_irq_i     (uart_done_irq),
        .sensor_data_ready_irq_i(sensor_ready_irq),
        .dma_done_irq_i         (dma_done_irq),
        .read_data_o            (intc_read_data),
        .irq_o                  (irq_o)
    );

    dma_lite u_dma_lite (
        .clk             (clk),
        .rst_n           (rst_n),
        .clk_en_i        (!sleep_o),
        .addr_i          (eff_addr),
        .write_data_i    (write_data_i),
        .write_en_i      (dma_write_en),
        .read_en_i       (dma_read_en),
        .dma_read_data_i (dma_mem_read_data),
        .read_data_o     (dma_read_data),
        .dma_read_addr_o (dma_mem_read_addr),
        .dma_write_addr_o(dma_mem_write_addr),
        .dma_write_data_o(dma_mem_write_data),
        .dma_write_en_o  (dma_mem_write_en),
        .busy_o          (dma_busy),
        .done_o          (dma_done),
        .done_irq_o      (dma_done_irq),
        .active_o        (dma_active)
    );

    power_mgmt_mmio u_power_mgmt_mmio (
        .clk                     (clk),
        .rst_n                   (rst_n),
        .addr_i                  (eff_addr),
        .write_data_i            (write_data_i),
        .write_en_i              (power_write_en),
        .read_en_i               (power_read_en),
        .cpu_active_i            (1'b1),
        .aes_active_i            (aes_active),
        .uart_active_i           (uart_active),
        .dma_active_i            (dma_active),
        .sensor_active_i         (sensor_active),
        .read_data_o             (power_read_data),
        .sleep_o                 (sleep_o),
        .activity_counter_debug_o(activity_counter_debug_o)
    );

    always_comb begin
        read_data_o = 32'h0;
        if (mem_read_i) begin
            case (1'b1)
                aes_sel:    read_data_o = aes_read_data;
                sensor_sel: read_data_o = sensor_read_data;
                uart_sel:   read_data_o = uart_read_data;
                intc_sel:   read_data_o = intc_read_data;
                dma_sel:    read_data_o = dma_read_data;
                power_sel:  read_data_o = power_read_data;
                default:    read_data_o = mmio_sel ? 32'hDEAD_BAAD : mem_read_data;
            endcase
        end
    end

    assign aes_done_o = aes_done_irq;
endmodule

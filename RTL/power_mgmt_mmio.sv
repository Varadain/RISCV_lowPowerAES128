// ============================================================
// Power and Activity Monitor MMIO
//
// Base address: 0x0000_0800
//   0x00 POWER_CTRL          [0] sleep_request, [1] clear counters
//   0x04 CPU_ACTIVE_CYCLES
//   0x08 AES_ACTIVE_CYCLES
//   0x0C UART_ACTIVE_CYCLES
//   0x10 SLEEP_CYCLES
//   0x14 DMA_ACTIVE_CYCLES
//   0x18 SENSOR_ACTIVE_CYCLES
// ============================================================
module power_mgmt_mmio (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [31:0] addr_i,
    input  logic [31:0] write_data_i,
    input  logic        write_en_i,
    input  logic        read_en_i,
    input  logic        cpu_active_i,
    input  logic        aes_active_i,
    input  logic        uart_active_i,
    input  logic        dma_active_i,
    input  logic        sensor_active_i,
    output logic [31:0] read_data_o,
    output logic        sleep_o,
    output logic [31:0] activity_counter_debug_o
);

    localparam logic [5:0] OFF_CTRL   = 6'h00;
    localparam logic [5:0] OFF_CPU    = 6'h04;
    localparam logic [5:0] OFF_AES    = 6'h08;
    localparam logic [5:0] OFF_UART   = 6'h0C;
    localparam logic [5:0] OFF_SLEEP  = 6'h10;
    localparam logic [5:0] OFF_DMA    = 6'h14;
    localparam logic [5:0] OFF_SENSOR = 6'h18;

    logic [5:0]  reg_offset;
    logic [31:0] cpu_active_cycles;
    logic [31:0] aes_active_cycles;
    logic [31:0] uart_active_cycles;
    logic [31:0] sleep_cycles;
    logic [31:0] dma_active_cycles;
    logic [31:0] sensor_active_cycles;
    logic        clear_counters;

    assign reg_offset = addr_i[5:0];
    assign activity_counter_debug_o = aes_active_cycles ^ uart_active_cycles ^ sleep_cycles ^ dma_active_cycles;
    assign clear_counters = write_en_i && (reg_offset == OFF_CTRL) && write_data_i[1];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sleep_o              <= 1'b0;
            cpu_active_cycles    <= 32'h0;
            aes_active_cycles    <= 32'h0;
            uart_active_cycles   <= 32'h0;
            sleep_cycles         <= 32'h0;
            dma_active_cycles    <= 32'h0;
            sensor_active_cycles <= 32'h0;
        end else begin
            if (write_en_i && (reg_offset == OFF_CTRL)) begin
                sleep_o <= write_data_i[0];
            end

            if (clear_counters) begin
                cpu_active_cycles    <= 32'h0;
                aes_active_cycles    <= 32'h0;
                uart_active_cycles   <= 32'h0;
                sleep_cycles         <= 32'h0;
                dma_active_cycles    <= 32'h0;
                sensor_active_cycles <= 32'h0;
            end else begin
                if (cpu_active_i && !sleep_o) cpu_active_cycles <= cpu_active_cycles + 32'd1;
                if (aes_active_i)             aes_active_cycles <= aes_active_cycles + 32'd1;
                if (uart_active_i)            uart_active_cycles <= uart_active_cycles + 32'd1;
                if (sleep_o)                  sleep_cycles <= sleep_cycles + 32'd1;
                if (dma_active_i)             dma_active_cycles <= dma_active_cycles + 32'd1;
                if (sensor_active_i)          sensor_active_cycles <= sensor_active_cycles + 32'd1;
            end
        end
    end

    always_comb begin
        read_data_o = 32'h0;
        if (read_en_i) begin
            case (reg_offset)
                OFF_CTRL:   read_data_o = {31'h0, sleep_o};
                OFF_CPU:    read_data_o = cpu_active_cycles;
                OFF_AES:    read_data_o = aes_active_cycles;
                OFF_UART:   read_data_o = uart_active_cycles;
                OFF_SLEEP:  read_data_o = sleep_cycles;
                OFF_DMA:    read_data_o = dma_active_cycles;
                OFF_SENSOR: read_data_o = sensor_active_cycles;
                default:    read_data_o = 32'h0;
            endcase
        end
    end

endmodule

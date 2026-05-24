// ============================================================
// Sensor SPI MMIO Peripheral
//
// Base address: 0x0000_0400
//   0x00 SENSOR_DATA       readable sample register
//   0x04 SENSOR_STATUS     [0] data_ready
//   0x08 SENSOR_CONTROL    [0] enable, [1] clear data_ready
//   0x10 SPI_RXDATA        Intel altera_avalon_spi RXDATA
//   0x14 SPI_TXDATA        Intel altera_avalon_spi TXDATA
//   0x18 SPI_STATUS        Intel altera_avalon_spi STATUS
//   0x1C SPI_CONTROL       Intel altera_avalon_spi CONTROL
//   0x24 SPI_SLAVE_SELECT  Intel altera_avalon_spi SLAVE_SEL
// ============================================================
module sensor_spi_mmio (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        clk_en_i,
    input  logic [31:0] addr_i,
    input  logic [31:0] write_data_i,
    input  logic        write_en_i,
    input  logic        read_en_i,
    input  logic        spi_miso_i,
    output logic        spi_mosi_o,
    output logic        spi_sclk_o,
    output logic        spi_ss_n_o,
    output logic [31:0] read_data_o,
    output logic        data_ready_irq_o,
    output logic        active_o
);

    localparam logic [5:0] OFF_DATA       = 6'h00;
    localparam logic [5:0] OFF_STATUS     = 6'h04;
    localparam logic [5:0] OFF_CONTROL    = 6'h08;
    localparam logic [5:0] OFF_SPI_RXDATA = 6'h10;
    localparam logic [5:0] OFF_SPI_TXDATA = 6'h14;
    localparam logic [5:0] OFF_SPI_STATUS = 6'h18;
    localparam logic [5:0] OFF_SPI_CTRL   = 6'h1c;
    localparam logic [5:0] OFF_SPI_SS     = 6'h24;

    logic [5:0]  reg_offset;
    logic [31:0] sensor_data_reg;
    logic        data_ready_reg;
    logic        enable_reg;
    logic [7:0]  sample_tick;

    logic        spi_reg_sel;
    logic [2:0]  spi_addr;
    logic [15:0] spi_data_to_cpu;
    logic        spi_dataavailable;
    logic        spi_readyfordata;
    logic        spi_irq;

    assign reg_offset = addr_i[5:0];
    assign data_ready_irq_o = data_ready_reg;
    assign active_o = enable_reg | spi_reg_sel;

    always_comb begin
        spi_reg_sel = 1'b0;
        spi_addr    = 3'd0;
        case (reg_offset)
            OFF_SPI_RXDATA: begin
                spi_reg_sel = 1'b1;
                spi_addr    = 3'd0;
            end
            OFF_SPI_TXDATA: begin
                spi_reg_sel = 1'b1;
                spi_addr    = 3'd1;
            end
            OFF_SPI_STATUS: begin
                spi_reg_sel = 1'b1;
                spi_addr    = 3'd2;
            end
            OFF_SPI_CTRL: begin
                spi_reg_sel = 1'b1;
                spi_addr    = 3'd3;
            end
            OFF_SPI_SS: begin
                spi_reg_sel = 1'b1;
                spi_addr    = 3'd5;
            end
            default: ;
        endcase
    end

    sensor_spi_ip u_sensor_spi_ip (
        .clk          (clk),
        .reset_n      (rst_n),
        .spi_select   (spi_reg_sel & clk_en_i),
        .mem_addr     (spi_addr),
        .data_from_cpu(write_data_i[15:0]),
        .read_n       (~(read_en_i  & spi_reg_sel & clk_en_i)),
        .write_n      (~(write_en_i & spi_reg_sel & clk_en_i)),
        .MISO         (spi_miso_i),
        .MOSI         (spi_mosi_o),
        .SCLK         (spi_sclk_o),
        .SS_n         (spi_ss_n_o),
        .data_to_cpu  (spi_data_to_cpu),
        .dataavailable(spi_dataavailable),
        .endofpacket  (),
        .irq          (spi_irq),
        .readyfordata (spi_readyfordata)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sensor_data_reg <= 32'h1234_5678;
            data_ready_reg  <= 1'b1;
            enable_reg      <= 1'b1;
            sample_tick     <= 8'h0;
        end else if (clk_en_i) begin
            if (enable_reg) begin
                sample_tick <= sample_tick + 8'd1;
                if (sample_tick == 8'hff) begin
                    sensor_data_reg <= sensor_data_reg + 32'h0001_0101;
                    data_ready_reg  <= 1'b1;
                end
            end

            if (spi_dataavailable) begin
                sensor_data_reg <= {24'h0, spi_data_to_cpu[7:0]};
                data_ready_reg  <= 1'b1;
            end

            if (write_en_i && !spi_reg_sel) begin
                case (reg_offset)
                    OFF_DATA: sensor_data_reg <= write_data_i;
                    OFF_CONTROL: begin
                        enable_reg <= write_data_i[0];
                        if (write_data_i[1]) begin
                            data_ready_reg <= 1'b0;
                        end
                    end
                    default: ;
                endcase
            end

            if (read_en_i && (reg_offset == OFF_DATA)) begin
                data_ready_reg <= 1'b0;
            end
        end
    end

    always_comb begin
        read_data_o = 32'h0;
        if (read_en_i) begin
            case (reg_offset)
                OFF_DATA:       read_data_o = sensor_data_reg;
                OFF_STATUS:     read_data_o = {31'h0, data_ready_reg};
                OFF_CONTROL:    read_data_o = {31'h0, enable_reg};
                OFF_SPI_RXDATA,
                OFF_SPI_STATUS,
                OFF_SPI_CTRL,
                OFF_SPI_SS:     read_data_o = {16'h0, spi_data_to_cpu};
                default:        read_data_o = 32'h0;
            endcase
        end
    end

endmodule

module aes_mmio (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [31:0] addr_i,
    input  logic [31:0] write_data_i,
    input  logic        write_en_i,
    input  logic        read_en_i,
    output logic [31:0] read_data_o
);

    localparam logic [31:0] AES_BASE_ADDR = 32'h0000_0300;

    localparam logic [5:0] OFF_CTRL   = 6'h00;
    localparam logic [5:0] OFF_STATUS = 6'h04;
    localparam logic [5:0] OFF_KEY0   = 6'h08;
    localparam logic [5:0] OFF_KEY1   = 6'h0C;
    localparam logic [5:0] OFF_KEY2   = 6'h10;
    localparam logic [5:0] OFF_KEY3   = 6'h14;
    localparam logic [5:0] OFF_PT0    = 6'h18;
    localparam logic [5:0] OFF_PT1    = 6'h1C;
    localparam logic [5:0] OFF_PT2    = 6'h20;
    localparam logic [5:0] OFF_PT3    = 6'h24;
    localparam logic [5:0] OFF_CT0    = 6'h28;
    localparam logic [5:0] OFF_CT1    = 6'h2C;
    localparam logic [5:0] OFF_CT2    = 6'h30;
    localparam logic [5:0] OFF_CT3    = 6'h34;

    logic [5:0]  reg_offset;
    logic [127:0] key_reg;
    logic [127:0] pt_reg;
    logic [127:0] ct_reg;

    logic busy_reg;
    logic done_reg;

    logic aes_start_pulse;
    logic aes_clk_en;
    logic aes_done;
    logic [127:0] aes_ciphertext;

    assign reg_offset = addr_i[5:0] - AES_BASE_ADDR[5:0];
    assign aes_clk_en = busy_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_reg          <= '0;
            pt_reg           <= '0;
            ct_reg           <= '0;
            busy_reg         <= 1'b0;
            done_reg         <= 1'b0;
            aes_start_pulse  <= 1'b0;
        end else begin
            aes_start_pulse <= 1'b0;

            if (write_en_i) begin
                unique case (reg_offset)
                    OFF_CTRL: begin
                        if (write_data_i[0] && !busy_reg) begin
                            aes_start_pulse <= 1'b1;
                            busy_reg        <= 1'b1;
                            done_reg        <= 1'b0;
                        end
                        if (write_data_i[1]) begin
                            done_reg <= 1'b0;
                        end
                    end
                    OFF_KEY0: key_reg[31:0]    <= write_data_i;
                    OFF_KEY1: key_reg[63:32]   <= write_data_i;
                    OFF_KEY2: key_reg[95:64]   <= write_data_i;
                    OFF_KEY3: key_reg[127:96]  <= write_data_i;
                    OFF_PT0:  pt_reg[31:0]     <= write_data_i;
                    OFF_PT1:  pt_reg[63:32]    <= write_data_i;
                    OFF_PT2:  pt_reg[95:64]    <= write_data_i;
                    OFF_PT3:  pt_reg[127:96]   <= write_data_i;
                    default: ;
                endcase
            end

            if (aes_done) begin
                ct_reg   <= aes_ciphertext;
                busy_reg <= 1'b0;
                done_reg <= 1'b1;
            end
        end
    end

    always_comb begin
        read_data_o = 32'h0;
        if (read_en_i) begin
            unique case (reg_offset)
                OFF_CTRL:   read_data_o = {30'h0, done_reg, busy_reg};
                OFF_STATUS: read_data_o = {30'h0, done_reg, busy_reg};
                OFF_KEY0:   read_data_o = key_reg[31:0];
                OFF_KEY1:   read_data_o = key_reg[63:32];
                OFF_KEY2:   read_data_o = key_reg[95:64];
                OFF_KEY3:   read_data_o = key_reg[127:96];
                OFF_PT0:    read_data_o = pt_reg[31:0];
                OFF_PT1:    read_data_o = pt_reg[63:32];
                OFF_PT2:    read_data_o = pt_reg[95:64];
                OFF_PT3:    read_data_o = pt_reg[127:96];
                OFF_CT0:    read_data_o = ct_reg[31:0];
                OFF_CT1:    read_data_o = ct_reg[63:32];
                OFF_CT2:    read_data_o = ct_reg[95:64];
                OFF_CT3:    read_data_o = ct_reg[127:96];
                default:    read_data_o = 32'h0;
            endcase
        end
    end

    aes128_lowpower u_aes128_lowpower (
        .clk(clk),
        .reset(~rst_n),
        .clk_en(aes_clk_en),
        .start(aes_start_pulse),
        .plaintext(pt_reg),
        .key(key_reg),
        .ciphertext(aes_ciphertext),
        .done(aes_done)
    );

endmodule

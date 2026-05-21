// ============================================================
// AES / AES-CTR MMIO Peripheral
//
// Base address: 0x0000_0300
// Existing ECB-compatible map is preserved:
//   0x00 CTRL      write [0] start, [1] clear done, [2] mode_ctr
//   0x04 STATUS    read  [0] busy, [1] done, [2] mode_ctr
//   0x08-0x14 KEY0..KEY3
//   0x18-0x24 PT0..PT3
//   0x28-0x34 CT0..CT3
//
// CTR additions:
//   0x38 NONCE0    nonce[31:0]
//   0x3C NONCE1    nonce[63:32]
//   0x40 COUNT0    counter[31:0]
//   0x44 COUNT1    counter[63:32]
//
// ECB: ciphertext = AES_encrypt(plaintext)
// CTR: ciphertext = plaintext XOR AES_encrypt(nonce[63:0] || counter[63:0])
//      counter auto-increments after each block.
// ============================================================
module aes_mmio (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        clk_en_i,
    input  logic [31:0] addr_i,
    input  logic [31:0] write_data_i,
    input  logic        write_en_i,
    input  logic        read_en_i,
    output logic [31:0] read_data_o,
    output logic        aes_done_irq_o,
    output logic [31:0] ciphertext_debug_o,
    output logic        active_o
);

    localparam logic [7:0] OFF_CTRL   = 8'h00;
    localparam logic [7:0] OFF_STATUS = 8'h04;
    localparam logic [7:0] OFF_KEY0   = 8'h08;
    localparam logic [7:0] OFF_KEY1   = 8'h0C;
    localparam logic [7:0] OFF_KEY2   = 8'h10;
    localparam logic [7:0] OFF_KEY3   = 8'h14;
    localparam logic [7:0] OFF_PT0    = 8'h18;
    localparam logic [7:0] OFF_PT1    = 8'h1C;
    localparam logic [7:0] OFF_PT2    = 8'h20;
    localparam logic [7:0] OFF_PT3    = 8'h24;
    localparam logic [7:0] OFF_CT0    = 8'h28;
    localparam logic [7:0] OFF_CT1    = 8'h2C;
    localparam logic [7:0] OFF_CT2    = 8'h30;
    localparam logic [7:0] OFF_CT3    = 8'h34;
    localparam logic [7:0] OFF_NONCE0 = 8'h38;
    localparam logic [7:0] OFF_NONCE1 = 8'h3C;
    localparam logic [7:0] OFF_COUNT0 = 8'h40;
    localparam logic [7:0] OFF_COUNT1 = 8'h44;

    logic [7:0]   reg_offset;
    logic [127:0] key_reg;
    logic [127:0] pt_reg;
    logic [127:0] ct_reg;
    logic [63:0]  nonce_reg;
    logic [63:0]  counter_reg;

    logic busy_reg;
    logic done_reg;
    logic mode_ctr_reg;

    logic aes_start_pulse;
    logic aes_clk_en;
    logic aes_done;
    logic [127:0] aes_input_block;
    logic [127:0] aes_ciphertext;

    assign reg_offset = addr_i[7:0];
    assign aes_clk_en = clk_en_i && busy_reg;
    assign aes_done_irq_o = done_reg;
    assign ciphertext_debug_o = ct_reg[31:0];
    assign active_o = busy_reg;
    assign aes_input_block = mode_ctr_reg ? {nonce_reg, counter_reg} : pt_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_reg          <= '0;
            pt_reg           <= '0;
            ct_reg           <= '0;
            nonce_reg        <= '0;
            counter_reg      <= '0;
            busy_reg         <= 1'b0;
            done_reg         <= 1'b0;
            mode_ctr_reg     <= 1'b0;
            aes_start_pulse  <= 1'b0;
        end else begin
            aes_start_pulse <= 1'b0;

            if (clk_en_i && write_en_i) begin
                case (reg_offset)
                    OFF_CTRL: begin
                        mode_ctr_reg <= write_data_i[2];
                        if (write_data_i[0] && !busy_reg) begin
                            aes_start_pulse <= 1'b1;
                            busy_reg        <= 1'b1;
                            done_reg        <= 1'b0;
                        end
                        if (write_data_i[1]) begin
                            done_reg <= 1'b0;
                        end
                    end
                    OFF_KEY0:   key_reg[31:0]    <= write_data_i;
                    OFF_KEY1:   key_reg[63:32]   <= write_data_i;
                    OFF_KEY2:   key_reg[95:64]   <= write_data_i;
                    OFF_KEY3:   key_reg[127:96]  <= write_data_i;
                    OFF_PT0:    pt_reg[31:0]     <= write_data_i;
                    OFF_PT1:    pt_reg[63:32]    <= write_data_i;
                    OFF_PT2:    pt_reg[95:64]    <= write_data_i;
                    OFF_PT3:    pt_reg[127:96]   <= write_data_i;
                    OFF_NONCE0: nonce_reg[31:0]  <= write_data_i;
                    OFF_NONCE1: nonce_reg[63:32] <= write_data_i;
                    OFF_COUNT0: counter_reg[31:0]  <= write_data_i;
                    OFF_COUNT1: counter_reg[63:32] <= write_data_i;
                    default: ;
                endcase
            end

            if (clk_en_i && aes_done && busy_reg) begin
                ct_reg   <= mode_ctr_reg ? (pt_reg ^ aes_ciphertext) : aes_ciphertext;
                busy_reg <= 1'b0;
                done_reg <= 1'b1;
                if (mode_ctr_reg) begin
                    counter_reg <= counter_reg + 64'd1;
                end
            end
        end
    end

    always_comb begin
        read_data_o = 32'h0;
        if (read_en_i) begin
            case (reg_offset)
                OFF_CTRL:   read_data_o = {29'h0, mode_ctr_reg, done_reg, busy_reg};
                OFF_STATUS: read_data_o = {29'h0, mode_ctr_reg, done_reg, busy_reg};
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
                OFF_NONCE0: read_data_o = nonce_reg[31:0];
                OFF_NONCE1: read_data_o = nonce_reg[63:32];
                OFF_COUNT0: read_data_o = counter_reg[31:0];
                OFF_COUNT1: read_data_o = counter_reg[63:32];
                default:    read_data_o = 32'h0;
            endcase
        end
    end

    aes128_lowpower u_aes128_lowpower (
        .clk       (clk),
        .reset     (~rst_n),
        .clk_en    (aes_clk_en),
        .start     (aes_start_pulse),
        .plaintext (aes_input_block),
        .key       (key_reg),
        .ciphertext(aes_ciphertext),
        .done      (aes_done)
    );

endmodule

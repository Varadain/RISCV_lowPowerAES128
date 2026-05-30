`timescale 1ns/1ps
// ============================================================
// RISC-V 5-STAGE PIPELINE OVERVIEW
// ============================================================
//
// Each instruction flows through 5 stages:
//
//   ┌──────┐   ┌──────┐   ┌──────┐   ┌──────┐   ┌──────┐
//   │  IF  │→→ │  ID   │→→│  EX  │→→ │ MEM  │→→ │  WB  │
//   └──────┘   └──────┘   └──────┘   └──────┘   └──────┘
//
// IF  (Instruction Fetch)   : Fetch instruction from memory
// ID  (Instruction Decode)  : Decode + read registers
// EX  (Execute)             : Perform ALU operation
// MEM (Memory Access)       : Load/store memory
// WB  (Write Back)          : Write result to register
//
// Example (ADD x3, x1, x2):
//
// Cycle 1: IF  → fetch ADD
// Cycle 2: ID  → read x1, x2
// Cycle 3: EX  → compute x1 + x2
// Cycle 4: MEM → (not used)
// Cycle 5: WB  → write result into x3
//
// Multiple instructions run in parallel (pipeline overlap)
// ============================================================
module riscv_core_tb;
`ifdef SYNTHESIS
    // Quartus-friendly stub (no behavioral stimulus in synthesis/elaboration mode).
    logic clk;
    logic rst_n;
    logic [31:0] current_pc_debug_tb;
    logic        aes_done_debug_tb;
    logic [31:0] aes_ciphertext_debug_tb;
    logic        uart_tx_tb;
    logic        spi_miso_tb;
    logic        spi_mosi_tb;
    logic        spi_sclk_tb;
    logic        spi_ss_n_tb;
    logic        irq_debug_tb;
    logic        sleep_debug_tb;
    logic [31:0] activity_counter_debug_tb;

    assign clk   = 1'b0;
    assign rst_n = 1'b1;
    assign spi_miso_tb = 1'b0;

    riscv_aes_advancements dut (
        .clk                   (clk),
        .rst_n                 (rst_n),
        .spi_miso              (spi_miso_tb),
        .current_pc_debug      (current_pc_debug_tb),
        .aes_done_debug        (aes_done_debug_tb),
        .aes_ciphertext_debug  (aes_ciphertext_debug_tb),
        .uart_tx               (uart_tx_tb),
        .spi_mosi              (spi_mosi_tb),
        .spi_sclk              (spi_sclk_tb),
        .spi_ss_n              (spi_ss_n_tb),
        .irq_debug             (irq_debug_tb),
        .sleep_debug           (sleep_debug_tb),
        .activity_counter_debug(activity_counter_debug_tb)
    );
`else
    // -------------------------------------------------------------------------
    // Testbench controls
    // -------------------------------------------------------------------------
    logic clk;
    logic rst_n;
    logic [31:0] current_pc_debug_tb;
    logic        aes_done_debug_tb;
    logic [31:0] aes_ciphertext_debug_tb;
    logic        uart_tx_tb;
    logic        spi_miso_tb;
    logic        spi_mosi_tb;
    logic        spi_sclk_tb;
    logic        spi_ss_n_tb;
    logic        irq_debug_tb;
    logic        sleep_debug_tb;
    logic [31:0] activity_counter_debug_tb;

    int pass_count;
    int fail_count;
    int if_stall_seen_count;
    int if_flush_seen_count;
    int aes_sel_seen_count;
    int aes_write_seen_count;
    int aes_read_seen_count;
    int uart_done_seen_count;
    int irq_seen_count;
    int spi_sclk_toggle_count;
    logic spi_sclk_prev;

    localparam int CLK_HALF   = 5;
    localparam int PIPE_DRAIN = 12;

    assign spi_miso_tb = spi_mosi_tb; // simple loopback for SPI waveform visibility

    riscv_aes_advancements dut (
        .clk                   (clk),
        .rst_n                 (rst_n),
        .spi_miso              (spi_miso_tb),
        .current_pc_debug      (current_pc_debug_tb),
        .aes_done_debug        (aes_done_debug_tb),
        .aes_ciphertext_debug  (aes_ciphertext_debug_tb),
        .uart_tx               (uart_tx_tb),
        .spi_mosi              (spi_mosi_tb),
        .spi_sclk              (spi_sclk_tb),
        .spi_ss_n              (spi_ss_n_tb),
        .irq_debug             (irq_debug_tb),
        .sleep_debug           (sleep_debug_tb),
        .activity_counter_debug(activity_counter_debug_tb)
    );

    // -------------------------------------------------------------------------
    // Waveform observation aliases
    // -------------------------------------------------------------------------
    wire [31:0] obs_if_pc              = dut.pc_if;
    wire [31:0] obs_if_instr           = dut.instr_if;
    wire        obs_if_stall           = dut.stall_if;
    wire        obs_if_flush           = dut.flush_ifid;

    wire [31:0] obs_id_pc              = dut.pc_id;
    wire [31:0] obs_id_instr           = dut.instr_id;
    wire [4:0]  obs_id_rs1             = dut.rs1_id;
    wire [4:0]  obs_id_rs2             = dut.rs2_id;
    wire [4:0]  obs_id_rd              = dut.rd_id;
    wire [31:0] obs_id_rs1_data        = dut.rs1_data_id;
    wire [31:0] obs_id_rs2_data        = dut.rs2_data_id;
    wire [31:0] obs_id_imm             = dut.imm_id;
    wire        obs_id_reg_write       = dut.reg_write_id;
    wire        obs_id_mem_read        = dut.mem_read_id;
    wire        obs_id_mem_write       = dut.mem_write_id;
    wire        obs_id_mem_to_reg      = dut.mem_to_reg_id;
    wire        obs_id_alu_src         = dut.alu_src_id;
    wire        obs_id_branch          = dut.branch_id;
    wire [3:0]  obs_id_alu_ctrl        = dut.alu_ctrl_id;

    wire [31:0] obs_ex_pc              = dut.pc_ex;
    wire [4:0]  obs_ex_rs1             = dut.rs1_ex;
    wire [4:0]  obs_ex_rs2             = dut.rs2_ex;
    wire [4:0]  obs_ex_rd              = dut.rd_ex;
    wire [31:0] obs_ex_rs1_data        = dut.rs1_data_ex;
    wire [31:0] obs_ex_rs2_data        = dut.rs2_data_ex;
    wire [31:0] obs_ex_imm             = dut.imm_ex;
    wire        obs_ex_reg_write       = dut.reg_write_ex;
    wire        obs_ex_mem_read        = dut.mem_read_ex;
    wire        obs_ex_mem_write       = dut.mem_write_ex;
    wire        obs_ex_mem_to_reg      = dut.mem_to_reg_ex;
    wire        obs_ex_alu_src         = dut.alu_src_ex;
    wire        obs_ex_branch          = dut.branch_ex;
    wire [3:0]  obs_ex_alu_ctrl        = dut.alu_ctrl_ex;
    wire [1:0]  obs_forward_a          = dut.forward_a;
    wire [1:0]  obs_forward_b          = dut.forward_b;
    wire [31:0] obs_ex_op_a            = dut.u_ex_stage.op_a;
    wire [31:0] obs_ex_op_b            = dut.u_ex_stage.op_b;
    wire [31:0] obs_ex_alu_result_raw  = dut.u_ex_stage.alu_result_raw;
    wire [31:0] obs_ex_alu_result      = dut.alu_result_ex;
    wire [31:0] obs_ex_rs2_forwarded   = dut.rs2_forwarded_ex;
    wire [31:0] obs_ex_branch_target   = dut.branch_target_ex;
    wire        obs_ex_branch_taken    = dut.branch_taken_ex;

    wire [31:0] obs_mem_alu_result     = dut.alu_result_mem;
    wire [31:0] obs_mem_write_data     = dut.rs2_data_mem;
    wire [4:0]  obs_mem_rd             = dut.rd_mem;
    wire        obs_mem_reg_write      = dut.reg_write_mem;
    wire        obs_mem_read           = dut.mem_read_mem;
    wire        obs_mem_write          = dut.mem_write_mem;
    wire        obs_mem_to_reg         = dut.mem_to_reg_mem;
    wire [31:0] obs_mem_eff_addr       = dut.u_mem_stage.eff_addr;
    wire [2:0]  obs_mem_ls_tag         = dut.u_mem_stage.ls_tag;
    wire [31:0] obs_mem_raw_word       = dut.u_mem_stage.raw_mem_word;
    wire [31:0] obs_mem_merged_store   = dut.u_mem_stage.merged_store_word;
    wire [31:0] obs_mem_read_data      = dut.mem_read_data_mem;

    wire [31:0] obs_wb_alu_result      = dut.alu_result_wb;
    wire [31:0] obs_wb_mem_read_data   = dut.mem_read_data_wb;
    wire [4:0]  obs_wb_rd              = dut.rd_wb;
    wire        obs_wb_reg_write       = dut.reg_write_wb;
    wire        obs_wb_mem_to_reg      = dut.mem_to_reg_wb;
    wire [31:0] obs_wb_data            = dut.writeback_data;

    wire [31:0] obs_x0                 = dut.u_id_stage.u_reg_file.regs[0];
    wire [31:0] obs_x1                 = dut.u_id_stage.u_reg_file.regs[1];
    wire [31:0] obs_x2                 = dut.u_id_stage.u_reg_file.regs[2];
    wire [31:0] obs_x3                 = dut.u_id_stage.u_reg_file.regs[3];
    wire [31:0] obs_x4                 = dut.u_id_stage.u_reg_file.regs[4];
    wire [31:0] obs_x5                 = dut.u_id_stage.u_reg_file.regs[5];
    wire [31:0] obs_x6                 = dut.u_id_stage.u_reg_file.regs[6];
    wire [31:0] obs_x7                 = dut.u_id_stage.u_reg_file.regs[7];
    wire [31:0] obs_x8                 = dut.u_id_stage.u_reg_file.regs[8];
    wire [31:0] obs_x9                 = dut.u_id_stage.u_reg_file.regs[9];
    wire [31:0] obs_x10                = dut.u_id_stage.u_reg_file.regs[10];
    wire [31:0] obs_x11                = dut.u_id_stage.u_reg_file.regs[11];
    wire [31:0] obs_x12                = dut.u_id_stage.u_reg_file.regs[12];
    wire [31:0] obs_x13                = dut.u_id_stage.u_reg_file.regs[13];
    wire [31:0] obs_x14                = dut.u_id_stage.u_reg_file.regs[14];
    wire [31:0] obs_x15                = dut.u_id_stage.u_reg_file.regs[15];
    wire [31:0] obs_x16                = dut.u_id_stage.u_reg_file.regs[16];
    wire [31:0] obs_x17                = dut.u_id_stage.u_reg_file.regs[17];
    wire [31:0] obs_x18                = dut.u_id_stage.u_reg_file.regs[18];
    wire [31:0] obs_x19                = dut.u_id_stage.u_reg_file.regs[19];
    wire [31:0] obs_x20                = dut.u_id_stage.u_reg_file.regs[20];
    wire [31:0] obs_x21                = dut.u_id_stage.u_reg_file.regs[21];
    wire [31:0] obs_x22                = dut.u_id_stage.u_reg_file.regs[22];
    wire [31:0] obs_x23                = dut.u_id_stage.u_reg_file.regs[23];
    wire [31:0] obs_x24                = dut.u_id_stage.u_reg_file.regs[24];
    wire [31:0] obs_x25                = dut.u_id_stage.u_reg_file.regs[25];
    wire [31:0] obs_x26                = dut.u_id_stage.u_reg_file.regs[26];
    wire [31:0] obs_x27                = dut.u_id_stage.u_reg_file.regs[27];
    wire [31:0] obs_x28                = dut.u_id_stage.u_reg_file.regs[28];
    wire [31:0] obs_x29                = dut.u_id_stage.u_reg_file.regs[29];
    wire [31:0] obs_x30                = dut.u_id_stage.u_reg_file.regs[30];
    wire [31:0] obs_x31                = dut.u_id_stage.u_reg_file.regs[31];

    wire [31:0] obs_dmem0              = dut.u_mem_stage.u_data_mem.ram[0];
    wire [31:0] obs_dmem1              = dut.u_mem_stage.u_data_mem.ram[1];
    wire [31:0] obs_dmem2              = dut.u_mem_stage.u_data_mem.ram[2];
    wire [31:0] obs_dmem3              = dut.u_mem_stage.u_data_mem.ram[3];
    wire [31:0] obs_dmem4              = dut.u_mem_stage.u_data_mem.ram[4];
    wire [31:0] obs_dmem5              = dut.u_mem_stage.u_data_mem.ram[5];
    wire [31:0] obs_dmem6              = dut.u_mem_stage.u_data_mem.ram[6];
    wire [31:0] obs_dmem7              = dut.u_mem_stage.u_data_mem.ram[7];

    wire        obs_aes_sel            = dut.u_mem_stage.aes_sel;
    wire        obs_aes_write_en       = dut.u_mem_stage.aes_write_en;
    wire        obs_aes_read_en        = dut.u_mem_stage.aes_read_en;
    wire [5:0]  obs_aes_reg_offset     = dut.u_mem_stage.u_aes_mmio.reg_offset;
    wire        obs_aes_start          = dut.u_mem_stage.u_aes_mmio.aes_start_pulse;
    wire        obs_aes_busy           = dut.u_mem_stage.u_aes_mmio.busy_reg;
    wire        obs_aes_done           = dut.u_mem_stage.u_aes_mmio.done_reg;
    wire [127:0] obs_aes_key           = dut.u_mem_stage.u_aes_mmio.key_reg;
    wire [127:0] obs_aes_plaintext     = dut.u_mem_stage.u_aes_mmio.pt_reg;
    wire [127:0] obs_aes_ciphertext    = dut.u_mem_stage.u_aes_mmio.ct_reg;
    wire [3:0]  obs_aes_round          = dut.u_mem_stage.u_aes_mmio.u_aes128_lowpower.round;
    wire [127:0] obs_aes_state         = dut.u_mem_stage.u_aes_mmio.u_aes128_lowpower.state;
    wire [127:0] obs_aes_round_key     = dut.u_mem_stage.u_aes_mmio.u_aes128_lowpower.round_key;
    wire        obs_uart_busy          = dut.u_mem_stage.u_uart_mmio.tx_busy_o;
    wire        obs_uart_done          = dut.u_mem_stage.u_uart_mmio.done_latched;
    wire        obs_irq                = dut.irq_debug;
    wire        obs_sleep              = dut.sleep_debug;
    wire        obs_custom_id          = dut.custom_instr_id;
    wire        obs_custom_ex          = dut.custom_instr_ex;
    wire        obs_custom_mem         = dut.custom_instr_mem;
    wire [2:0]  obs_custom_cmd_mem     = dut.custom_cmd_mem;
    wire [31:0] obs_custom_result      = dut.u_mem_stage.custom_result;

    always @(posedge clk) begin
        if (dut.stall_if) begin
            if_stall_seen_count++;
        end
        if (dut.flush_ifid) begin
            if_flush_seen_count++;
        end
        if (dut.u_mem_stage.aes_sel) begin
            aes_sel_seen_count++;
        end
        if (dut.u_mem_stage.aes_write_en) begin
            aes_write_seen_count++;
        end
        if (dut.u_mem_stage.aes_read_en) begin
            aes_read_seen_count++;
        end
        if (dut.u_mem_stage.u_uart_mmio.done_latched) begin
            uart_done_seen_count++;
        end
        if (dut.irq_debug) begin
            irq_seen_count++;
        end
        if (spi_sclk_tb !== spi_sclk_prev) begin
            spi_sclk_toggle_count++;
            spi_sclk_prev <= spi_sclk_tb;
        end
    end

    // -------------------------------------------------------------------------
    // Clock and reset
    // -------------------------------------------------------------------------
    initial clk = 1'b0;
    always #CLK_HALF clk = ~clk;

    task automatic apply_reset();
        begin
            rst_n = 1'b0;
            repeat (3) @(posedge clk);
            rst_n = 1'b1;
            repeat (1) @(posedge clk);
        end
    endtask

    task automatic run_cycles(input int cycles);
        int i;
        begin
            for (i = 0; i < cycles; i++) begin
                @(posedge clk);
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // Encoders
    // -------------------------------------------------------------------------
    function automatic [31:0] enc_rtype(
        input [6:0] funct7,
        input [4:0] rs2,
        input [4:0] rs1,
        input [2:0] funct3,
        input [4:0] rd,
        input [6:0] opcode
    );
        enc_rtype = {funct7, rs2, rs1, funct3, rd, opcode};
    endfunction

    function automatic [31:0] enc_custom(
        input [2:0] cmd,
        input [4:0] rs2,
        input [4:0] rs1,
        input [4:0] rd
    );
        enc_custom = {7'b0000000, rs2, rs1, cmd, rd, 7'b0001011};
    endfunction

    function automatic [31:0] enc_itype(
        input signed [11:0] imm,
        input [4:0] rs1,
        input [2:0] funct3,
        input [4:0] rd,
        input [6:0] opcode
    );
        enc_itype = {imm[11:0], rs1, funct3, rd, opcode};
    endfunction

    function automatic [31:0] enc_stype(
        input signed [11:0] imm,
        input [4:0] rs2,
        input [4:0] rs1,
        input [2:0] funct3,
        input [6:0] opcode
    );
        enc_stype = {imm[11:5], rs2, rs1, funct3, imm[4:0], opcode};
    endfunction

    function automatic [31:0] enc_btype(
        input signed [12:0] imm,
        input [4:0] rs2,
        input [4:0] rs1,
        input [2:0] funct3,
        input [6:0] opcode
    );
        enc_btype = {imm[12], imm[10:5], rs2, rs1, funct3, imm[4:1], imm[11], opcode};
    endfunction

    function automatic [31:0] enc_utype(
        input [19:0] imm20,
        input [4:0] rd,
        input [6:0] opcode
    );
        enc_utype = {imm20, rd, opcode};
    endfunction

    function automatic [31:0] enc_jtype(
        input signed [20:0] imm,
        input [4:0] rd,
        input [6:0] opcode
    );
        enc_jtype = {imm[20], imm[10:1], imm[11], imm[19:12], rd, opcode};
    endfunction

    // -------------------------------------------------------------------------
    // Test utilities
    // -------------------------------------------------------------------------
    task automatic clear_mem_and_regs();
        int i;
        begin
            // Fill instruction memory with NOP
            for (i = 0; i < 256; i++) begin
                dut.u_if_stage.u_instr_mem.rom[i] = 32'h00000013; // addi x0,x0,0
                dut.u_mem_stage.u_data_mem.ram[i] = 32'h0;
            end

            // Clear architectural register file
            for (i = 0; i < 32; i++) begin
                dut.u_id_stage.u_reg_file.regs[i] = 32'h0;
            end
        end
    endtask

    task automatic check_and_report(
        input string itype,
        input string mnemonic,
        input string op_text,
        input logic [31:0] got,
        input logic [31:0] exp
    );
        begin
            if (got !== exp) begin
                $display("[%s] %s: %s -> got=0x%08x expected=0x%08x -> FAIL", itype, mnemonic, op_text, got, exp);
                fail_count++;
            end else begin
                $display("[%s] %s: %s -> got=0x%08x expected=0x%08x -> PASS", itype, mnemonic, op_text, got, exp);
                pass_count++;
            end
        end
    endtask

    task automatic check_seen(
        input string signal_name,
        input int seen_count
    );
        begin
            if (seen_count <= 0) begin
                $display("[SIGNAL] %s: expected at least one assertion -> count=%0d -> FAIL", signal_name, seen_count);
                fail_count++;
            end else begin
                $display("[SIGNAL] %s: observed assertion count=%0d -> PASS", signal_name, seen_count);
                pass_count++;
            end
        end
    endtask

    task automatic reset_activity_counters();
        begin
            if_stall_seen_count = 0;
            if_flush_seen_count = 0;
            aes_sel_seen_count = 0;
            aes_write_seen_count = 0;
            aes_read_seen_count = 0;
            uart_done_seen_count = 0;
            irq_seen_count = 0;
            spi_sclk_toggle_count = 0;
            spi_sclk_prev = spi_sclk_tb;
        end
    endtask

    function automatic [7:0] hex_ascii(input logic [3:0] value);
        begin
            hex_ascii = (value < 4'd10) ? (8'h30 + {4'h0, value}) : (8'h41 + ({4'h0, value} - 8'd10));
        end
    endfunction

    task automatic aes_ctr_encrypt_direct(
        input  logic [127:0] key,
        input  logic [127:0] plaintext,
        input  logic [63:0]  nonce,
        input  logic [63:0]  counter,
        output logic [127:0] ciphertext
    );
        int timeout;
        begin
            dut.u_mem_stage.u_aes_mmio.key_reg      = key;
            dut.u_mem_stage.u_aes_mmio.pt_reg       = plaintext;
            dut.u_mem_stage.u_aes_mmio.nonce_reg    = nonce;
            dut.u_mem_stage.u_aes_mmio.counter_reg  = counter;
            dut.u_mem_stage.u_aes_mmio.mode_ctr_reg = 1'b1;

            @(negedge clk);
            dut.u_mem_stage.u_aes_mmio.aes_start_pulse = 1'b1;
            dut.u_mem_stage.u_aes_mmio.busy_reg        = 1'b1;
            dut.u_mem_stage.u_aes_mmio.done_reg        = 1'b0;
            @(negedge clk);
            dut.u_mem_stage.u_aes_mmio.aes_start_pulse = 1'b0;

            timeout = 0;
            while ((dut.u_mem_stage.u_aes_mmio.done_reg !== 1'b1) && (timeout < 60)) begin
                @(posedge clk);
                timeout++;
            end
            ciphertext = dut.u_mem_stage.u_aes_mmio.ct_reg;
        end
    endtask

    task automatic uart_send_byte_direct(input logic [7:0] value);
        int timeout;
        begin
            while (dut.u_mem_stage.u_uart_mmio.tx_busy_o) begin
                @(posedge clk);
            end

            @(negedge clk);
            dut.u_mem_stage.u_uart_mmio.tx_data_reg      = value;
            dut.u_mem_stage.u_uart_mmio.tx_start_pulse   = 1'b1;
            dut.u_mem_stage.u_uart_mmio.done_latched     = 1'b0;
            dut.u_mem_stage.u_uart_mmio.enable_reg       = 1'b1;
            dut.u_mem_stage.u_uart_mmio.baud_div_reg     = 16'd1;
            @(negedge clk);
            dut.u_mem_stage.u_uart_mmio.tx_start_pulse   = 1'b0;

            timeout = 0;
            while ((dut.u_mem_stage.u_uart_mmio.done_latched !== 1'b1) && (timeout < 80)) begin
                @(posedge clk);
                timeout++;
            end
            $write("%c", value);
        end
    endtask

    task automatic uart_print_string(input string msg);
        int i;
        begin
            for (i = 0; i < msg.len(); i++) begin
                uart_send_byte_direct(msg[i]);
            end
        end
    endtask

    task automatic uart_print_hex128(input logic [127:0] value);
        int nib;
        begin
            for (nib = 31; nib >= 0; nib--) begin
                uart_send_byte_direct(hex_ascii(value[nib*4 +: 4]));
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // R-type group (10 instructions)
    // -------------------------------------------------------------------------
    task automatic run_rtype_tests();
        begin
            $display("\n=== R-type tests ===");
            clear_mem_and_regs();

            // Input setup: x1=20, x2=6
            dut.u_if_stage.u_instr_mem.rom[0]  = enc_itype(12'd20, 5'd0, 3'b000, 5'd1, 7'b0010011);
            dut.u_if_stage.u_instr_mem.rom[1]  = enc_itype(12'd6,  5'd0, 3'b000, 5'd2, 7'b0010011);

            // RV32I R-type operations
            dut.u_if_stage.u_instr_mem.rom[2]  = enc_rtype(7'b0000000,5'd2,5'd1,3'b000,5'd3, 7'b0110011); // ADD
            dut.u_if_stage.u_instr_mem.rom[3]  = enc_rtype(7'b0100000,5'd2,5'd1,3'b000,5'd4, 7'b0110011); // SUB
            dut.u_if_stage.u_instr_mem.rom[4]  = enc_rtype(7'b0000000,5'd2,5'd1,3'b001,5'd5, 7'b0110011); // SLL
            dut.u_if_stage.u_instr_mem.rom[5]  = enc_rtype(7'b0000000,5'd1,5'd2,3'b010,5'd6, 7'b0110011); // SLT
            dut.u_if_stage.u_instr_mem.rom[6]  = enc_rtype(7'b0000000,5'd1,5'd2,3'b011,5'd7, 7'b0110011); // SLTU
            dut.u_if_stage.u_instr_mem.rom[7]  = enc_rtype(7'b0000000,5'd2,5'd1,3'b100,5'd8, 7'b0110011); // XOR
            dut.u_if_stage.u_instr_mem.rom[8]  = enc_rtype(7'b0000000,5'd2,5'd1,3'b101,5'd9, 7'b0110011); // SRL
            dut.u_if_stage.u_instr_mem.rom[9]  = enc_rtype(7'b0100000,5'd2,5'd1,3'b101,5'd10,7'b0110011); // SRA
            dut.u_if_stage.u_instr_mem.rom[10] = enc_rtype(7'b0000000,5'd2,5'd1,3'b110,5'd11,7'b0110011); // OR
            dut.u_if_stage.u_instr_mem.rom[11] = enc_rtype(7'b0000000,5'd2,5'd1,3'b111,5'd12,7'b0110011); // AND

            apply_reset();
            run_cycles(30);

            check_and_report("R-TYPE", "ADD",  "x3 = x1 + x2; 20 + 6 = 26",        dut.u_id_stage.u_reg_file.regs[3],  32'd26);
            check_and_report("R-TYPE", "SUB",  "x4 = x1 - x2; 20 - 6 = 14",        dut.u_id_stage.u_reg_file.regs[4],  32'd14);
            check_and_report("R-TYPE", "SLL",  "x5 = x1 << x2[4:0]; 20 << 6 = 1280",dut.u_id_stage.u_reg_file.regs[5],  32'd1280);
            check_and_report("R-TYPE", "SLT",  "x6 = (x2 < x1) signed; 6<20 => 1", dut.u_id_stage.u_reg_file.regs[6],  32'd1);
            check_and_report("R-TYPE", "SLTU", "x7 = (x2 < x1) unsigned; 6<20 =>1",dut.u_id_stage.u_reg_file.regs[7],  32'd1);
            check_and_report("R-TYPE", "XOR",  "x8 = x1 ^ x2; 0x14 ^ 0x06 = 0x12", dut.u_id_stage.u_reg_file.regs[8],  32'h12);
            check_and_report("R-TYPE", "SRL",  "x9 = x1 >> x2[4:0]; 20 >> 6 = 0",   dut.u_id_stage.u_reg_file.regs[9],  32'd0);
            check_and_report("R-TYPE", "SRA",  "x10 = x1 >>> x2[4:0]; 20>>>6 = 0",  dut.u_id_stage.u_reg_file.regs[10], 32'd0);
            check_and_report("R-TYPE", "OR",   "x11 = x1 | x2; 0x14 | 0x06 = 0x16",dut.u_id_stage.u_reg_file.regs[11], 32'h16);
            check_and_report("R-TYPE", "AND",  "x12 = x1 & x2; 0x14 & 0x06 = 0x04",dut.u_id_stage.u_reg_file.regs[12], 32'h04);
        end
    endtask

    // -------------------------------------------------------------------------
    // I-type ALU/immediate group (9 instructions)
    // -------------------------------------------------------------------------
    task automatic run_itype_tests();
        begin
            $display("\n=== I-type tests ===");
            clear_mem_and_regs();

            dut.u_if_stage.u_instr_mem.rom[0] = enc_itype(12'd9, 5'd0, 3'b000, 5'd1, 7'b0010011); // ADDI base
            dut.u_if_stage.u_instr_mem.rom[1] = enc_itype(12'd7, 5'd1, 3'b010, 5'd2, 7'b0010011); // SLTI
            dut.u_if_stage.u_instr_mem.rom[2] = enc_itype(12'd7, 5'd1, 3'b011, 5'd3, 7'b0010011); // SLTIU
            dut.u_if_stage.u_instr_mem.rom[3] = enc_itype(12'h0F0,5'd1, 3'b100, 5'd4, 7'b0010011); // XORI
            dut.u_if_stage.u_instr_mem.rom[4] = enc_itype(12'h003,5'd1, 3'b110, 5'd5, 7'b0010011); // ORI
            dut.u_if_stage.u_instr_mem.rom[5] = enc_itype(12'h003,5'd1, 3'b111, 5'd6, 7'b0010011); // ANDI
            dut.u_if_stage.u_instr_mem.rom[6] = enc_itype(12'b000000000010,5'd1,3'b001,5'd7,7'b0010011); // SLLI
            dut.u_if_stage.u_instr_mem.rom[7] = enc_itype(12'b000000000001,5'd1,3'b101,5'd8,7'b0010011); // SRLI
            dut.u_if_stage.u_instr_mem.rom[8] = enc_itype(12'b010000000001,5'd1,3'b101,5'd9,7'b0010011); // SRAI

            apply_reset();
            run_cycles(25);

            check_and_report("I-TYPE", "ADDI",  "x1 = x0 + 9; 0 + 9 = 9",            dut.u_id_stage.u_reg_file.regs[1], 32'd9);
            check_and_report("I-TYPE", "SLTI",  "x2 = (x1 < 7) signed; 9<7 => 0",     dut.u_id_stage.u_reg_file.regs[2], 32'd0);
            check_and_report("I-TYPE", "SLTIU", "x3 = (x1 < 7) unsigned; 9<7 => 0",   dut.u_id_stage.u_reg_file.regs[3], 32'd0);
            check_and_report("I-TYPE", "XORI",  "x4 = x1 ^ 0xF0; 0x09^0xF0 = 0xF9",   dut.u_id_stage.u_reg_file.regs[4], 32'hF9);
            check_and_report("I-TYPE", "ORI",   "x5 = x1 | 0x3; 0x09|0x03 = 0x0B",    dut.u_id_stage.u_reg_file.regs[5], 32'h0B);
            check_and_report("I-TYPE", "ANDI",  "x6 = x1 & 0x3; 0x09&0x03 = 0x01",    dut.u_id_stage.u_reg_file.regs[6], 32'h01);
            check_and_report("I-TYPE", "SLLI",  "x7 = x1 << 2; 9 << 2 = 36",          dut.u_id_stage.u_reg_file.regs[7], 32'd36);
            check_and_report("I-TYPE", "SRLI",  "x8 = x1 >> 1; 9 >> 1 = 4",           dut.u_id_stage.u_reg_file.regs[8], 32'd4);
            check_and_report("I-TYPE", "SRAI",  "x9 = x1 >>> 1; 9 >>> 1 = 4",         dut.u_id_stage.u_reg_file.regs[9], 32'd4);
        end
    endtask

    // -------------------------------------------------------------------------
    // Load/Store group
    // 5 loads + 3 stores = 8 instructions
    // -------------------------------------------------------------------------
    task automatic run_load_store_tests();
        begin
            $display("\n=== S-type/I-type load-store tests ===");
            clear_mem_and_regs();

            // x1 = base address 0, x7 = store data 0x55
            dut.u_if_stage.u_instr_mem.rom[0] = enc_itype(12'd0,  5'd0,3'b000,5'd1,7'b0010011);
            dut.u_if_stage.u_instr_mem.rom[1] = enc_itype(12'h55, 5'd0,3'b000,5'd7,7'b0010011);

            // Loads
            dut.u_if_stage.u_instr_mem.rom[2] = enc_itype(12'd0,5'd1,3'b000,5'd2,7'b0000011); // LB
            dut.u_if_stage.u_instr_mem.rom[3] = enc_itype(12'd0,5'd1,3'b001,5'd3,7'b0000011); // LH
            dut.u_if_stage.u_instr_mem.rom[4] = enc_itype(12'd0,5'd1,3'b010,5'd4,7'b0000011); // LW
            dut.u_if_stage.u_instr_mem.rom[5] = enc_itype(12'd0,5'd1,3'b100,5'd5,7'b0000011); // LBU
            dut.u_if_stage.u_instr_mem.rom[6] = enc_itype(12'd0,5'd1,3'b101,5'd6,7'b0000011); // LHU

            // Stores to addresses 4,8,12 (RAM[1], RAM[2], RAM[3])
            dut.u_if_stage.u_instr_mem.rom[7] = enc_stype(12'd4, 5'd7,5'd1,3'b000,7'b0100011); // SB
            dut.u_if_stage.u_instr_mem.rom[8] = enc_stype(12'd8, 5'd7,5'd1,3'b001,7'b0100011); // SH
            dut.u_if_stage.u_instr_mem.rom[9] = enc_stype(12'd12,5'd7,5'd1,3'b010,7'b0100011); // SW

            apply_reset();

            // Data pattern at RAM[0]; preload after reset because data_mem clears RAM.
            dut.u_mem_stage.u_data_mem.ram[0] = 32'hAABBCCDD;

            run_cycles(40);

            check_and_report("I-TYPE", "LB",  "x2 = signext(mem8[0]);  0xDD -> 0xFFFFFFDD",  dut.u_id_stage.u_reg_file.regs[2], 32'hFFFFFFDD);
            check_and_report("I-TYPE", "LH",  "x3 = signext(mem16[0]); 0xCCDD -> 0xFFFFCCDD",dut.u_id_stage.u_reg_file.regs[3], 32'hFFFFCCDD);
            check_and_report("I-TYPE", "LW",  "x4 = mem32[0]; 0xAABBCCDD",                     dut.u_id_stage.u_reg_file.regs[4], 32'hAABBCCDD);
            check_and_report("I-TYPE", "LBU", "x5 = zeroext(mem8[0]); 0xDD -> 0x000000DD",     dut.u_id_stage.u_reg_file.regs[5], 32'h000000DD);
            check_and_report("I-TYPE", "LHU", "x6 = zeroext(mem16[0]);0xCCDD->0x0000CCDD",     dut.u_id_stage.u_reg_file.regs[6], 32'h0000CCDD);

            check_and_report("S-TYPE", "SB",  "mem8 [4]  = x7[7:0];  0x55",                    dut.u_mem_stage.u_data_mem.ram[1], 32'h00000055);
            check_and_report("S-TYPE", "SH",  "mem16[8]  = x7[15:0]; 0x0055",                  dut.u_mem_stage.u_data_mem.ram[2], 32'h00000055);
            check_and_report("S-TYPE", "SW",  "mem32[12] = x7;       0x00000055",              dut.u_mem_stage.u_data_mem.ram[3], 32'h00000055);
        end
    endtask

    // -------------------------------------------------------------------------
    // B-type branch group (6 instructions)
    // -------------------------------------------------------------------------
    task automatic run_branch_tests();
        begin
            $display("\n=== B-type tests ===");
            clear_mem_and_regs();

            dut.u_if_stage.u_instr_mem.rom[0]  = enc_itype(12'd1,5'd0,3'b000,5'd1,7'b0010011); // x1=1
            dut.u_if_stage.u_instr_mem.rom[1]  = enc_itype(12'd2,5'd0,3'b000,5'd2,7'b0010011); // x2=2

            dut.u_if_stage.u_instr_mem.rom[2]  = enc_btype(13'd8,5'd2,5'd1,3'b000,7'b1100011); // BEQ (not taken)
            dut.u_if_stage.u_instr_mem.rom[3]  = enc_itype(12'd1,5'd0,3'b000,5'd20,7'b0010011);

            dut.u_if_stage.u_instr_mem.rom[4]  = enc_btype(13'd8,5'd2,5'd1,3'b001,7'b1100011); // BNE (taken)
            dut.u_if_stage.u_instr_mem.rom[5]  = enc_itype(12'd1,5'd0,3'b000,5'd21,7'b0010011);
            dut.u_if_stage.u_instr_mem.rom[6]  = enc_itype(12'd1,5'd0,3'b000,5'd22,7'b0010011);

            dut.u_if_stage.u_instr_mem.rom[7]  = enc_btype(13'd8,5'd2,5'd1,3'b100,7'b1100011); // BLT (taken)
            dut.u_if_stage.u_instr_mem.rom[8]  = enc_itype(12'd1,5'd0,3'b000,5'd23,7'b0010011);

            dut.u_if_stage.u_instr_mem.rom[9]  = enc_btype(13'd8,5'd2,5'd1,3'b101,7'b1100011); // BGE (not taken)
            dut.u_if_stage.u_instr_mem.rom[10] = enc_itype(12'd1,5'd0,3'b000,5'd24,7'b0010011);

            dut.u_if_stage.u_instr_mem.rom[11] = enc_btype(13'd8,5'd2,5'd1,3'b110,7'b1100011); // BLTU (taken)
            dut.u_if_stage.u_instr_mem.rom[12] = enc_itype(12'd1,5'd0,3'b000,5'd25,7'b0010011);

            dut.u_if_stage.u_instr_mem.rom[13] = enc_btype(13'd8,5'd2,5'd1,3'b111,7'b1100011); // BGEU (not taken)
            dut.u_if_stage.u_instr_mem.rom[14] = enc_itype(12'd1,5'd0,3'b000,5'd26,7'b0010011);

            apply_reset();
            run_cycles(55);

            check_and_report("B-TYPE", "BEQ",  "x1==x2? 1==2 false -> fall-through", dut.u_id_stage.u_reg_file.regs[20], 32'd1);
            check_and_report("B-TYPE", "BNE",  "x1!=x2? 1!=2 true  -> branch",       dut.u_id_stage.u_reg_file.regs[21], 32'd0);
            check_and_report("B-TYPE", "BLT",  "x1<x2 signed? 1<2 true -> branch",    dut.u_id_stage.u_reg_file.regs[23], 32'd0);
            check_and_report("B-TYPE", "BGE",  "x1>=x2 signed? 1>=2 false",           dut.u_id_stage.u_reg_file.regs[24], 32'd1);
            check_and_report("B-TYPE", "BLTU", "x1<x2 unsigned? 1<2 true -> branch",   dut.u_id_stage.u_reg_file.regs[25], 32'd0);
            check_and_report("B-TYPE", "BGEU", "x1>=x2 unsigned? 1>=2 false",         dut.u_id_stage.u_reg_file.regs[26], 32'd1);
        end
    endtask

    // -------------------------------------------------------------------------
    // U-type/J-type group
    // U: LUI, AUIPC (2)
    // J: JAL, JALR (2)
    // -------------------------------------------------------------------------
    task automatic run_u_jtype_tests();
        begin
            $display("\n=== U-type and J-type tests ===");
            clear_mem_and_regs();

            dut.u_if_stage.u_instr_mem.rom[0]  = enc_utype(20'h12345,5'd1,7'b0110111); // LUI
            dut.u_if_stage.u_instr_mem.rom[1]  = enc_utype(20'h00010,5'd2,7'b0010111); // AUIPC

            dut.u_if_stage.u_instr_mem.rom[2]  = enc_jtype(21'd8,5'd3,7'b1101111);      // JAL x3,+8
            dut.u_if_stage.u_instr_mem.rom[3]  = enc_itype(12'd1,5'd0,3'b000,5'd4,7'b0010011); // skipped
            dut.u_if_stage.u_instr_mem.rom[4]  = enc_itype(12'd2,5'd0,3'b000,5'd5,7'b0010011); // target

            dut.u_if_stage.u_instr_mem.rom[5]  = enc_itype(12'd32,5'd0,3'b000,5'd6,7'b1100111); // JALR x6,32(x0)
            dut.u_if_stage.u_instr_mem.rom[6]  = enc_itype(12'd99,5'd0,3'b000,5'd7,7'b0010011); // skipped
            dut.u_if_stage.u_instr_mem.rom[7]  = 32'h00000013;
            dut.u_if_stage.u_instr_mem.rom[8]  = enc_itype(12'd7,5'd0,3'b000,5'd29,7'b0010011); // landing pad

            apply_reset();
            run_cycles(60);

            check_and_report("U-TYPE", "LUI",   "x1 = 0x12345 << 12 = 0x12345000", dut.u_id_stage.u_reg_file.regs[1], 32'h12345000);
            check_and_report("U-TYPE", "AUIPC", "x2 = PC(0x4) + 0x00010<<12 = 0x00010004", dut.u_id_stage.u_reg_file.regs[2], 32'h00010004);
            check_and_report("J-TYPE", "JAL",   "x3 = return addr (PC+4) = 12",      dut.u_id_stage.u_reg_file.regs[3], 32'd12);
            check_and_report("J-TYPE", "JALR",  "x6 = return addr (PC+4) = 24",      dut.u_id_stage.u_reg_file.regs[6], 32'd24);
        end
    endtask

    // -------------------------------------------------------------------------
    // SYSTEM / FENCE / PSEUDO group
    // 2 + 2 + 6 = 10 instructions
    // -------------------------------------------------------------------------
    task automatic run_system_fence_pseudo_tests();
        begin
            $display("\n=== SYSTEM/FENCE/PSEUDO tests ===");
            clear_mem_and_regs();

            // Sentinel values to verify no destructive side effects
            dut.u_if_stage.u_instr_mem.rom[0]  = enc_itype(12'd7,5'd0,3'b000,5'd29,7'b0010011); // x29=7
            dut.u_if_stage.u_instr_mem.rom[1]  = enc_itype(12'd5,5'd0,3'b000,5'd31,7'b0010011); // x31=5

            // SYSTEM
            dut.u_if_stage.u_instr_mem.rom[2]  = 32'h00000073; // ECALL
            dut.u_if_stage.u_instr_mem.rom[3]  = 32'h00100073; // EBREAK

            // FENCE
            dut.u_if_stage.u_instr_mem.rom[4]  = 32'h0000000F; // FENCE
            dut.u_if_stage.u_instr_mem.rom[5]  = 32'h0000100F; // FENCE.I

            // Pseudo instruction forms
            dut.u_if_stage.u_instr_mem.rom[6]  = enc_itype(12'd0,5'd0,3'b000,5'd0,7'b0010011); // NOP
            dut.u_if_stage.u_instr_mem.rom[7]  = enc_itype(12'd2,5'd0,3'b000,5'd5,7'b0010011); // seed x5=2
            dut.u_if_stage.u_instr_mem.rom[8]  = enc_itype(12'd0,5'd5,3'b000,5'd8,7'b0010011); // MV x8,x5
            dut.u_if_stage.u_instr_mem.rom[8]  = enc_itype(12'd0,5'd5,3'b000,5'd8,7'b0010011); // MV x8,x5
            dut.u_if_stage.u_instr_mem.rom[9]  = enc_itype(12'd9,5'd0,3'b000,5'd9,7'b0010011); // LI x9,9
            dut.u_if_stage.u_instr_mem.rom[10] = enc_jtype(21'd8,5'd0,7'b1101111);             // J +8
            dut.u_if_stage.u_instr_mem.rom[11] = enc_itype(12'd1,5'd0,3'b000,5'd27,7'b0010011); // skipped
            dut.u_if_stage.u_instr_mem.rom[12] = enc_itype(12'd1,5'd0,3'b000,5'd28,7'b0010011); // target
            dut.u_if_stage.u_instr_mem.rom[13] = enc_itype(12'd0,5'd0,3'b000,5'd10,7'b0010011); // ADDI x10,x0,0
            dut.u_if_stage.u_instr_mem.rom[14] = enc_itype(12'd0,5'd10,3'b000,5'd11,7'b0010011); // ADDI x11,x10,0 (NOP-like)

            apply_reset();
            run_cycles(65);

            check_and_report("SYSTEM", "ECALL",  "environment call; sentinel x29 remains 7", dut.u_id_stage.u_reg_file.regs[29], 32'd7);
            check_and_report("SYSTEM", "EBREAK", "breakpoint; sentinel x29 remains 7",       dut.u_id_stage.u_reg_file.regs[29], 32'd7);
            check_and_report("FENCE",  "FENCE",  "memory ordering barrier; sentinel x31=5",   dut.u_id_stage.u_reg_file.regs[31], 32'd5);
            check_and_report("FENCE",  "FENCE.I","instruction barrier; sentinel x31=5",       dut.u_id_stage.u_reg_file.regs[31], 32'd5);

            check_and_report("I-TYPE", "NOP",    "addi x0,x0,0 leaves x0=0",                 dut.u_id_stage.u_reg_file.regs[0],  32'd0);
            check_and_report("I-TYPE", "MV",     "x8 = x5 + 0; 2 -> 2",                       dut.u_id_stage.u_reg_file.regs[8],  32'd2);
            check_and_report("I-TYPE", "LI",     "x9 = 9",                                    dut.u_id_stage.u_reg_file.regs[9],  32'd9);
            check_and_report("J-TYPE", "J",      "jump skips x27 write; x27 stays 0",         dut.u_id_stage.u_reg_file.regs[27], 32'd0);
            check_and_report("J-TYPE", "J",      "jump target executes x28=1",                dut.u_id_stage.u_reg_file.regs[28], 32'd1);
            check_and_report("I-TYPE", "NOP2",   "addi x11,x10,0 with x10=0 -> x11=0",        dut.u_id_stage.u_reg_file.regs[11], 32'd0);
        end
    endtask



    // -------------------------------------------------------------------------
    // AES-128 MMIO NIST test vector
    // NIST SP 800-38A F.1 ECB-AES128:
    //   KEY = 000102030405060708090A0B0C0D0E0F
    //   PT  = 00112233445566778899AABBCCDDEEFF
    //   CT  = 69C4E0D86A7B0430D8CDB78070B4C55A
    // -------------------------------------------------------------------------
    task automatic run_aes_nist_tests();
        int timeout;
        begin
            $display("\n=== AES-128 NIST MMIO tests ===");

            clear_mem_and_regs();
            apply_reset();

            // Program key words (little-endian word map into [127:0])
            dut.u_mem_stage.u_aes_mmio.key_reg[31:0]    = 32'h0C0D0E0F; // KEY0
            dut.u_mem_stage.u_aes_mmio.key_reg[63:32]   = 32'h08090A0B; // KEY1
            dut.u_mem_stage.u_aes_mmio.key_reg[95:64]   = 32'h04050607; // KEY2
            dut.u_mem_stage.u_aes_mmio.key_reg[127:96]  = 32'h00010203; // KEY3

            // Program plaintext words
            dut.u_mem_stage.u_aes_mmio.pt_reg[31:0]     = 32'hCCDDEEFF; // PT0
            dut.u_mem_stage.u_aes_mmio.pt_reg[63:32]    = 32'h8899AABB; // PT1
            dut.u_mem_stage.u_aes_mmio.pt_reg[95:64]    = 32'h44556677; // PT2
            dut.u_mem_stage.u_aes_mmio.pt_reg[127:96]   = 32'h00112233; // PT3

            // Start pulse through control path equivalent
            @(negedge clk);
            dut.u_mem_stage.u_aes_mmio.aes_start_pulse = 1'b1;
            dut.u_mem_stage.u_aes_mmio.busy_reg        = 1'b1;
            dut.u_mem_stage.u_aes_mmio.done_reg        = 1'b0;
            @(negedge clk);
            dut.u_mem_stage.u_aes_mmio.aes_start_pulse = 1'b0;

            // Wait for done with timeout
            timeout = 0;
            while ((dut.u_mem_stage.u_aes_mmio.done_reg !== 1'b1) && (timeout < 40)) begin
                @(posedge clk);
                timeout++;
            end

            check_and_report("AES", "DONE",   "done asserted within 40 cycles", {31'h0, dut.u_mem_stage.u_aes_mmio.done_reg}, 32'h1);
            check_and_report("AES", "BUSY",   "busy deasserted after completion", {31'h0, dut.u_mem_stage.u_aes_mmio.busy_reg}, 32'h0);

            // Check ciphertext against NIST expected vector
            check_and_report("AES", "CT0", "ciphertext[31:0]",    dut.u_mem_stage.u_aes_mmio.ct_reg[31:0],    32'h70B4C55A);
            check_and_report("AES", "CT1", "ciphertext[63:32]",   dut.u_mem_stage.u_aes_mmio.ct_reg[63:32],   32'hD8CDB780);
            check_and_report("AES", "CT2", "ciphertext[95:64]",   dut.u_mem_stage.u_aes_mmio.ct_reg[95:64],   32'h6A7B0430);
            check_and_report("AES", "CT3", "ciphertext[127:96]",  dut.u_mem_stage.u_aes_mmio.ct_reg[127:96],  32'h69C4E0D8);
        end
    endtask

    // -------------------------------------------------------------------------
    // AES-CTR wrapper test. Plaintext is zero, so ciphertext equals
    // AES_encrypt(nonce || counter). The block below reuses the NIST AES input
    // as the CTR counter block.
    // -------------------------------------------------------------------------
    task automatic run_aes_ctr_tests();
        int timeout;
        begin
            $display("\n=== AES-CTR tests ===");

            clear_mem_and_regs();
            apply_reset();

            dut.u_mem_stage.u_aes_mmio.key_reg[31:0]    = 32'h0C0D0E0F;
            dut.u_mem_stage.u_aes_mmio.key_reg[63:32]   = 32'h08090A0B;
            dut.u_mem_stage.u_aes_mmio.key_reg[95:64]   = 32'h04050607;
            dut.u_mem_stage.u_aes_mmio.key_reg[127:96]  = 32'h00010203;

            dut.u_mem_stage.u_aes_mmio.pt_reg           = 128'h0;
            dut.u_mem_stage.u_aes_mmio.nonce_reg        = 64'h0011223344556677;
            dut.u_mem_stage.u_aes_mmio.counter_reg      = 64'h8899AABBCCDDEEFF;
            dut.u_mem_stage.u_aes_mmio.mode_ctr_reg     = 1'b1;

            @(negedge clk);
            dut.u_mem_stage.u_aes_mmio.aes_start_pulse = 1'b1;
            dut.u_mem_stage.u_aes_mmio.busy_reg        = 1'b1;
            dut.u_mem_stage.u_aes_mmio.done_reg        = 1'b0;
            @(negedge clk);
            dut.u_mem_stage.u_aes_mmio.aes_start_pulse = 1'b0;

            timeout = 0;
            while ((dut.u_mem_stage.u_aes_mmio.done_reg !== 1'b1) && (timeout < 40)) begin
                @(posedge clk);
                timeout++;
            end

            check_and_report("AES-CTR", "DONE", "done asserted within 40 cycles", {31'h0, dut.u_mem_stage.u_aes_mmio.done_reg}, 32'h1);
            check_and_report("AES-CTR", "CT0",  "zero plaintext XOR keystream[31:0]",   dut.u_mem_stage.u_aes_mmio.ct_reg[31:0],   32'h70B4C55A);
            check_and_report("AES-CTR", "CT1",  "zero plaintext XOR keystream[63:32]",  dut.u_mem_stage.u_aes_mmio.ct_reg[63:32],  32'hD8CDB780);
            check_and_report("AES-CTR", "CT2",  "zero plaintext XOR keystream[95:64]",  dut.u_mem_stage.u_aes_mmio.ct_reg[95:64],  32'h6A7B0430);
            check_and_report("AES-CTR", "CT3",  "zero plaintext XOR keystream[127:96]", dut.u_mem_stage.u_aes_mmio.ct_reg[127:96], 32'h69C4E0D8);
            check_and_report("AES-CTR", "COUNT","counter auto-incremented", dut.u_mem_stage.u_aes_mmio.counter_reg[31:0], 32'hCCDDEF00);
        end
    endtask

    // -------------------------------------------------------------------------
    // IoT SoC peripheral tests
    // -------------------------------------------------------------------------
    task automatic run_sensor_mmio_tests();
        begin
            $display("\n=== Sensor MMIO tests ===");
            clear_mem_and_regs();
            dut.u_if_stage.u_instr_mem.rom[0] = enc_itype(12'h400, 5'd0, 3'b000, 5'd1, 7'b0010011); // x1 = sensor base
            dut.u_if_stage.u_instr_mem.rom[1] = enc_itype(12'd0,   5'd1, 3'b010, 5'd2, 7'b0000011); // LW x2,DATA
            dut.u_if_stage.u_instr_mem.rom[2] = enc_itype(12'd4,   5'd1, 3'b010, 5'd3, 7'b0000011); // LW x3,STATUS
            apply_reset();
            run_cycles(20);

            check_and_report("SENSOR", "DATA",   "sensor data read through MMIO", dut.u_id_stage.u_reg_file.regs[2], 32'h12345678);
            check_and_report("SENSOR", "STATUS", "status register is readable", dut.u_id_stage.u_reg_file.regs[3][0], 1'b0);
        end
    endtask

    task automatic run_sensor_spi_ip_tests();
        begin
            $display("\n=== Sensor SPI IP tests ===");
            clear_mem_and_regs();
            reset_activity_counters();

            dut.u_if_stage.u_instr_mem.rom[0] = enc_itype(12'h400, 5'd0, 3'b000, 5'd1, 7'b0010011); // x1 = sensor base
            dut.u_if_stage.u_instr_mem.rom[1] = enc_itype(12'h001, 5'd0, 3'b000, 5'd2, 7'b0010011); // x2 = slave-select bit
            dut.u_if_stage.u_instr_mem.rom[2] = enc_stype(12'd36,  5'd2, 5'd1, 3'b010, 7'b0100011); // SW x2,SPI_SLAVE_SELECT
            dut.u_if_stage.u_instr_mem.rom[3] = enc_itype(12'h400, 5'd0, 3'b000, 5'd2, 7'b0010011); // x2 = SSO control bit
            dut.u_if_stage.u_instr_mem.rom[4] = enc_stype(12'd28,  5'd2, 5'd1, 3'b010, 7'b0100011); // SW x2,SPI_CONTROL
            dut.u_if_stage.u_instr_mem.rom[5] = enc_itype(12'h05a, 5'd0, 3'b000, 5'd3, 7'b0010011); // x3 = test byte
            dut.u_if_stage.u_instr_mem.rom[6] = enc_stype(12'd20,  5'd3, 5'd1, 3'b010, 7'b0100011); // SW x3,SPI_TXDATA

            apply_reset();
            reset_activity_counters();
            run_cycles(900);

            check_and_report("SPI-IP", "SCLK", "Intel SPI IP generated serial clock activity", {31'h0, (spi_sclk_toggle_count > 0)}, 32'h1);
            check_and_report("SPI-IP", "SS_N", "slave select asserted by SPI control", {31'h0, spi_ss_n_tb}, 32'h0);
        end
    endtask

    task automatic run_uart_mmio_tests();
        begin
            $display("\n=== UART MMIO tests ===");
            clear_mem_and_regs();
            dut.u_mem_stage.u_uart_mmio.baud_div_reg = 16'd1;
            dut.u_if_stage.u_instr_mem.rom[0] = enc_itype(12'h500, 5'd0, 3'b000, 5'd1, 7'b0010011); // x1 = UART base
            dut.u_if_stage.u_instr_mem.rom[1] = enc_itype(12'h05A, 5'd0, 3'b000, 5'd2, 7'b0010011); // x2 = 0x5A
            dut.u_if_stage.u_instr_mem.rom[2] = enc_stype(12'd0,   5'd2, 5'd1, 3'b010, 7'b0100011); // SW x2,TXDATA
            apply_reset();
            dut.u_mem_stage.u_uart_mmio.baud_div_reg = 16'd1;
            run_cycles(45);

            check_and_report("UART", "DONE", "TX done after MMIO write", {31'h0, dut.u_mem_stage.u_uart_mmio.done_latched}, 32'h1);
            check_and_report("UART", "BUSY", "TX no longer busy", {31'h0, dut.u_mem_stage.u_uart_mmio.tx_busy_o}, 32'h0);
        end
    endtask

    task automatic run_end_to_end_uart_aes_ctr_tests();
        logic [127:0] e2e_key;
        logic [127:0] e2e_plaintext;
        logic [127:0] e2e_ciphertext;
        logic [127:0] e2e_decrypted;
        logic [63:0]  e2e_nonce;
        logic [63:0]  e2e_counter;
        begin
            $display("\n=== End-to-end AES-CTR UART print/decrypt tests ===");
            clear_mem_and_regs();
            apply_reset();

            e2e_key       = 128'h000102030405060708090A0B0C0D0E0F;
            e2e_plaintext = 128'h4845414C54485F485237385F53393721; // "HEALTH_HR78_S97!"
            e2e_nonce     = 64'h0011223344556677;
            e2e_counter   = 64'h8899AABBCCDDEEFF;

            aes_ctr_encrypt_direct(e2e_key, e2e_plaintext, e2e_nonce, e2e_counter, e2e_ciphertext);
            check_and_report("E2E", "ENC_DONE", "AES-CTR encryption completed", {31'h0, dut.u_mem_stage.u_aes_mmio.done_reg}, 32'h1);
            check_and_report("E2E", "CT_DIFF",  "ciphertext differs from plaintext", (e2e_ciphertext != e2e_plaintext), 1'b1);

            // CTR decryption uses the same AES encryption primitive. Feed the
            // ciphertext as input with the same key, nonce, and counter.
            aes_ctr_encrypt_direct(e2e_key, e2e_ciphertext, e2e_nonce, e2e_counter, e2e_decrypted);
            check_and_report("E2E", "DEC_MATCH", "AES-CTR decrypted data matches original input", e2e_decrypted, e2e_plaintext);

            $display("UART transcript below is emitted through the RTL UART transmitter:");
            $write("UART_PRINT: ");
            uart_print_string("INPUT=");
            uart_print_hex128(e2e_plaintext);
            uart_print_string(" KEY=");
            uart_print_hex128(e2e_key);
            uart_print_string(" CIPHER=");
            uart_print_hex128(e2e_ciphertext);
            uart_print_string(" DECRYPTED=");
            uart_print_hex128(e2e_decrypted);
            uart_print_string((e2e_decrypted == e2e_plaintext) ? " MATCH=PASS\n" : " MATCH=FAIL\n");

            check_and_report("E2E", "UART_DONE", "UART completed final transcript byte", {31'h0, dut.u_mem_stage.u_uart_mmio.done_latched}, 32'h1);
        end
    endtask

    task automatic run_interrupt_tests();
        begin
            $display("\n=== Interrupt controller tests ===");
            clear_mem_and_regs();
            dut.u_if_stage.u_instr_mem.rom[0] = enc_itype(12'h600, 5'd0, 3'b000, 5'd1, 7'b0010011); // x1 = INTC base
            dut.u_if_stage.u_instr_mem.rom[1] = enc_itype(12'h004, 5'd0, 3'b000, 5'd2, 7'b0010011); // enable sensor IRQ
            dut.u_if_stage.u_instr_mem.rom[2] = enc_stype(12'd4,   5'd2, 5'd1, 3'b010, 7'b0100011); // SW enable
            dut.u_if_stage.u_instr_mem.rom[3] = enc_itype(12'd0,   5'd1, 3'b010, 5'd3, 7'b0000011); // LW pending
            dut.u_if_stage.u_instr_mem.rom[4] = enc_stype(12'd8,   5'd2, 5'd1, 3'b010, 7'b0100011); // SW clear
            apply_reset();
            run_cycles(35);

            check_and_report("INTC", "PENDING", "sensor-ready pending bit observed", dut.u_id_stage.u_reg_file.regs[3] & 32'h4, 32'h4);
            check_and_report("INTC", "IRQ",     "combined irq line asserted when enabled", {31'h0, dut.irq_debug}, 32'h1);
        end
    endtask

    task automatic run_dma_lite_tests();
        begin
            $display("\n=== DMA-lite tests ===");
            clear_mem_and_regs();
            dut.u_mem_stage.u_data_mem.ram[4] = 32'hDEADBEEF;
            dut.u_if_stage.u_instr_mem.rom[0] = enc_itype(12'h700, 5'd0, 3'b000, 5'd1, 7'b0010011); // x1 = DMA base
            dut.u_if_stage.u_instr_mem.rom[1] = enc_itype(12'd16,  5'd0, 3'b000, 5'd2, 7'b0010011); // src
            dut.u_if_stage.u_instr_mem.rom[2] = enc_stype(12'd0,   5'd2, 5'd1, 3'b010, 7'b0100011);
            dut.u_if_stage.u_instr_mem.rom[3] = enc_itype(12'd20,  5'd0, 3'b000, 5'd2, 7'b0010011); // dst
            dut.u_if_stage.u_instr_mem.rom[4] = enc_stype(12'd4,   5'd2, 5'd1, 3'b010, 7'b0100011);
            dut.u_if_stage.u_instr_mem.rom[5] = enc_itype(12'd1,   5'd0, 3'b000, 5'd2, 7'b0010011); // len/start
            dut.u_if_stage.u_instr_mem.rom[6] = enc_stype(12'd8,   5'd2, 5'd1, 3'b010, 7'b0100011);
            dut.u_if_stage.u_instr_mem.rom[7] = enc_stype(12'd12,  5'd2, 5'd1, 3'b010, 7'b0100011);
            apply_reset();
            dut.u_mem_stage.u_data_mem.ram[4] = 32'hDEADBEEF;
            run_cycles(45);

            check_and_report("DMA", "COPY", "ram[4] copied to ram[5]", dut.u_mem_stage.u_data_mem.ram[5], 32'hDEADBEEF);
            check_and_report("DMA", "DONE", "done flag asserted", {31'h0, dut.u_mem_stage.u_dma_lite.done_o}, 32'h1);
        end
    endtask

    task automatic run_power_activity_tests();
        begin
            $display("\n=== Power/activity tests ===");
            clear_mem_and_regs();
            dut.u_if_stage.u_instr_mem.rom[0] = enc_itype(12'h7FF, 5'd0, 3'b000, 5'd1, 7'b0010011); // x1 = 0x7ff
            dut.u_if_stage.u_instr_mem.rom[1] = enc_itype(12'd1,   5'd1, 3'b000, 5'd1, 7'b0010011); // x1 = power base 0x800
            dut.u_if_stage.u_instr_mem.rom[2] = enc_itype(12'd2,   5'd0, 3'b000, 5'd2, 7'b0010011); // clear counters
            dut.u_if_stage.u_instr_mem.rom[3] = enc_stype(12'd0,   5'd2, 5'd1, 3'b010, 7'b0100011);
            dut.u_if_stage.u_instr_mem.rom[4] = enc_itype(12'd1,   5'd0, 3'b000, 5'd2, 7'b0010011); // sleep
            dut.u_if_stage.u_instr_mem.rom[5] = enc_stype(12'd0,   5'd2, 5'd1, 3'b010, 7'b0100011);
            apply_reset();
            run_cycles(35);

            check_and_report("POWER", "SLEEP", "sleep control bit set", {31'h0, dut.sleep_debug}, 32'h1);
            check_and_report("POWER", "COUNT", "sleep cycles incremented", (dut.u_mem_stage.u_power_mgmt_mmio.sleep_cycles > 0), 1'b1);
            check_and_report("POWER", "DEBUG", "activity debug output observable", dut.activity_counter_debug, dut.u_mem_stage.u_power_mgmt_mmio.activity_counter_debug_o);
        end
    endtask

    task automatic run_custom_isa_tests();
        int i;
        begin
            $display("\n=== Custom security ISA tests ===");
            clear_mem_and_regs();

            dut.u_if_stage.u_instr_mem.rom[0] = enc_itype(12'd15, 5'd0, 3'b000, 5'd1, 7'b0010011); // x1 = 0x0f
            dut.u_if_stage.u_instr_mem.rom[1] = enc_itype(12'd51, 5'd0, 3'b000, 5'd2, 7'b0010011); // x2 = 0x33
            dut.u_if_stage.u_instr_mem.rom[2] = enc_custom(3'b000, 5'd2, 5'd1, 5'd3); // CSEC_XOR
            dut.u_if_stage.u_instr_mem.rom[3] = enc_custom(3'b001, 5'd0, 5'd0, 5'd4); // CSEC_AES_STATUS
            dut.u_if_stage.u_instr_mem.rom[4] = enc_custom(3'b010, 5'd2, 5'd1, 5'd5); // CSEC_AES_START
            for (i = 5; i < 48; i++) begin
                dut.u_if_stage.u_instr_mem.rom[i] = 32'h00000013;
            end
            dut.u_if_stage.u_instr_mem.rom[48] = enc_custom(3'b001, 5'd0, 5'd0, 5'd6); // CSEC_AES_STATUS after done
            dut.u_if_stage.u_instr_mem.rom[49] = enc_custom(3'b011, 5'd0, 5'd0, 5'd7); // CSEC_AES_CT0
            dut.u_if_stage.u_instr_mem.rom[50] = enc_custom(3'b100, 5'd0, 5'd0, 5'd8); // CSEC_AES_CLEAR
            dut.u_if_stage.u_instr_mem.rom[51] = enc_custom(3'b001, 5'd0, 5'd0, 5'd9); // CSEC_AES_STATUS after clear

            rst_n = 1'b0;
            repeat (3) @(posedge clk);
            rst_n = 1'b1;
            dut.u_mem_stage.u_aes_mmio.key_reg[31:0]   = 32'h0C0D0E0F;
            dut.u_mem_stage.u_aes_mmio.key_reg[63:32]  = 32'h08090A0B;
            dut.u_mem_stage.u_aes_mmio.key_reg[95:64]  = 32'h04050607;
            dut.u_mem_stage.u_aes_mmio.key_reg[127:96] = 32'h00010203;
            dut.u_mem_stage.u_aes_mmio.nonce_reg       = 64'h0011223344556677;
            dut.u_mem_stage.u_aes_mmio.counter_reg     = 64'h8899AABBCCDDEEFF;
            dut.u_mem_stage.u_aes_mmio.mode_ctr_reg    = 1'b0;
            dut.u_mem_stage.u_aes_mmio.busy_reg        = 1'b0;
            dut.u_mem_stage.u_aes_mmio.done_reg        = 1'b0;
            repeat (1) @(posedge clk);
            run_cycles(115);

            check_and_report("CUSTOM", "CSEC_XOR", "rd = rs1 ^ rs2; 0x0f ^ 0x33", dut.u_id_stage.u_reg_file.regs[3], 32'h0000003c);
            check_and_report("CUSTOM", "STATUS0",  "AES idle before custom start", dut.u_id_stage.u_reg_file.regs[4], 32'h00000000);
            check_and_report("CUSTOM", "START",    "custom instruction selected CTR mode", {31'h0, dut.u_mem_stage.u_aes_mmio.mode_ctr_reg}, 32'h00000001);
            check_and_report("CUSTOM", "STATUS1",  "AES done after custom start", dut.u_id_stage.u_reg_file.regs[6], 32'h00000006);
            check_and_report("CUSTOM", "CT0",      "custom CT0 read returns plaintext XOR keystream", dut.u_id_stage.u_reg_file.regs[7], 32'h70B4C555);
            check_and_report("CUSTOM", "CLEAR",    "custom clear leaves mode set and done cleared", dut.u_id_stage.u_reg_file.regs[9], 32'h00000004);
        end
    endtask

    // -------------------------------------------------------------------------
    // Signal activity group
    // Exercises signals that may otherwise stay flat in the directed tests:
    // stall_if, flush_ifid, aes_sel, aes_write_en, and aes_read_en.
    // -------------------------------------------------------------------------
    task automatic run_signal_activity_tests();
        begin
            $display("\n=== Signal activity tests ===");
            reset_activity_counters();

            clear_mem_and_regs();
            dut.u_if_stage.u_instr_mem.rom[0] = enc_itype(12'd0, 5'd0, 3'b000, 5'd1, 7'b0010011); // x1 = 0
            dut.u_if_stage.u_instr_mem.rom[1] = enc_itype(12'd0, 5'd1, 3'b010, 5'd2, 7'b0000011); // LW x2,0(x1)
            dut.u_if_stage.u_instr_mem.rom[2] = enc_itype(12'd1, 5'd2, 3'b000, 5'd3, 7'b0010011); // ADDI x3,x2,1

            apply_reset();
            dut.u_mem_stage.u_data_mem.ram[0] = 32'h0000002a;
            run_cycles(18);

            clear_mem_and_regs();
            dut.u_if_stage.u_instr_mem.rom[0] = enc_itype(12'h300, 5'd0, 3'b000, 5'd1, 7'b0010011); // x1 = AES base
            dut.u_if_stage.u_instr_mem.rom[1] = enc_itype(12'd1,   5'd0, 3'b000, 5'd2, 7'b0010011); // x2 = start bit
            dut.u_if_stage.u_instr_mem.rom[2] = enc_stype(12'd0,   5'd2, 5'd1, 3'b010, 7'b0100011); // SW x2,CTRL(x1)
            dut.u_if_stage.u_instr_mem.rom[3] = enc_itype(12'd4,   5'd1, 3'b010, 5'd3, 7'b0000011); // LW x3,STATUS(x1)

            apply_reset();
            run_cycles(60);

            check_seen("stall_if", if_stall_seen_count);
            check_seen("flush_ifid", if_flush_seen_count);
            check_seen("aes_sel", aes_sel_seen_count);
            check_seen("aes_write_en", aes_write_seen_count);
            check_seen("aes_read_en", aes_read_seen_count);
        end
    endtask

    // -------------------------------------------------------------------------
    // Deterministic random coverage smoke test
    // Uses a fixed seed so regression remains repeatable while still exercising
    // non-constant data values and varied MMIO paths.
    // -------------------------------------------------------------------------
    task automatic run_random_coverage_tests();
        int unsigned seed;
        logic [31:0] rnd_a;
        logic [31:0] rnd_b;
        logic [31:0] rnd_sensor;
        logic [31:0] rnd_dma_data;
        logic [7:0]  rnd_uart_byte;
        int unsigned src_idx;
        int unsigned dst_idx;
        begin
            $display("\n=== Randomized coverage smoke tests ===");
            seed = 32'hC0DE_2026;
            rnd_a         = $urandom(seed);
            rnd_b         = $urandom();
            rnd_sensor    = $urandom();
            rnd_dma_data  = $urandom();
            rnd_uart_byte = $urandom();
            src_idx       = 8 + ($urandom() % 8);
            dst_idx       = 24 + ($urandom() % 8);

            // Random custom-ISA datapath check: CSEC_XOR rd, rs1, rs2.
            clear_mem_and_regs();
            dut.u_if_stage.u_instr_mem.rom[0] = 32'h00000013; // NOP
            dut.u_if_stage.u_instr_mem.rom[1] = 32'h00000013; // NOP
            dut.u_if_stage.u_instr_mem.rom[2] = enc_custom(3'b000, 5'd2, 5'd1, 5'd3);
            apply_reset();
            dut.u_id_stage.u_reg_file.regs[1] = rnd_a;
            dut.u_id_stage.u_reg_file.regs[2] = rnd_b;
            run_cycles(18);
            check_and_report("RANDOM", "CSEC_XOR", "random rs1 ^ rs2 through custom ISA", dut.u_id_stage.u_reg_file.regs[3], (rnd_a ^ rnd_b));

            // Random sensor MMIO read: inject a random sample, then read through CPU load.
            clear_mem_and_regs();
            dut.u_if_stage.u_instr_mem.rom[0] = enc_itype(12'h400, 5'd0, 3'b000, 5'd1, 7'b0010011); // x1 = sensor base
            dut.u_if_stage.u_instr_mem.rom[1] = enc_itype(12'd0,   5'd1, 3'b010, 5'd2, 7'b0000011); // LW x2,SENSOR_DATA
            apply_reset();
            dut.u_mem_stage.u_sensor_spi_mmio.sensor_data_reg = rnd_sensor;
            dut.u_mem_stage.u_sensor_spi_mmio.data_ready_reg  = 1'b1;
            run_cycles(20);
            check_and_report("RANDOM", "SENSOR", "random sensor sample read through MMIO", dut.u_id_stage.u_reg_file.regs[2], rnd_sensor);

            // Random DMA-lite copy: randomized source/destination word addresses.
            clear_mem_and_regs();
            dut.u_if_stage.u_instr_mem.rom[0] = enc_itype(12'h700,        5'd0, 3'b000, 5'd1, 7'b0010011); // x1 = DMA base
            dut.u_if_stage.u_instr_mem.rom[1] = enc_itype(src_idx * 4,    5'd0, 3'b000, 5'd2, 7'b0010011); // src byte addr
            dut.u_if_stage.u_instr_mem.rom[2] = enc_stype(12'd0,          5'd2, 5'd1, 3'b010, 7'b0100011); // SW SRC
            dut.u_if_stage.u_instr_mem.rom[3] = enc_itype(dst_idx * 4,    5'd0, 3'b000, 5'd2, 7'b0010011); // dst byte addr
            dut.u_if_stage.u_instr_mem.rom[4] = enc_stype(12'd4,          5'd2, 5'd1, 3'b010, 7'b0100011); // SW DST
            dut.u_if_stage.u_instr_mem.rom[5] = enc_itype(12'd1,          5'd0, 3'b000, 5'd2, 7'b0010011); // len = 1 word
            dut.u_if_stage.u_instr_mem.rom[6] = enc_stype(12'd8,          5'd2, 5'd1, 3'b010, 7'b0100011); // SW LEN
            dut.u_if_stage.u_instr_mem.rom[7] = enc_stype(12'd12,         5'd2, 5'd1, 3'b010, 7'b0100011); // SW CTRL start
            apply_reset();
            dut.u_mem_stage.u_data_mem.ram[src_idx] = rnd_dma_data;
            run_cycles(50);
            check_and_report("RANDOM", "DMA", "random word copied from randomized source to destination", dut.u_mem_stage.u_data_mem.ram[dst_idx], rnd_dma_data);

            // Random UART byte: verify MMIO stores the byte and transfer completes.
            clear_mem_and_regs();
            dut.u_if_stage.u_instr_mem.rom[0] = enc_itype(12'h500,          5'd0, 3'b000, 5'd1, 7'b0010011); // x1 = UART base
            dut.u_if_stage.u_instr_mem.rom[1] = enc_itype({4'h0, rnd_uart_byte}, 5'd0, 3'b000, 5'd2, 7'b0010011); // x2 = random byte
            dut.u_if_stage.u_instr_mem.rom[2] = enc_stype(12'd0,            5'd2, 5'd1, 3'b010, 7'b0100011); // SW TXDATA
            apply_reset();
            dut.u_mem_stage.u_uart_mmio.baud_div_reg = 16'd1;
            run_cycles(45);
            check_and_report("RANDOM", "UART_DATA", "random UART byte accepted through MMIO", {24'h0, dut.u_mem_stage.u_uart_mmio.tx_data_reg}, {24'h0, rnd_uart_byte});
            check_and_report("RANDOM", "UART_DONE", "random UART byte transmission completed", {31'h0, dut.u_mem_stage.u_uart_mmio.done_latched}, 32'h1);
        end
    endtask

    // -------------------------------------------------------------------------
    // Main test sequence
    // 47 checks total:
    // 10 (R) + 9 (I) + 8 (Load/Store) + 6 (B) + 4 (U/J) + 10 (System/Fence/Pseudo)
    // Existing 58 checks are preserved, then IoT-security SoC checks are added.
    // -------------------------------------------------------------------------
    initial begin
        pass_count = 0;
        fail_count = 0;
        reset_activity_counters();

        $dumpfile("riscv_core_tb.vcd");
        $dumpvars(0, riscv_core_tb);

        run_rtype_tests();
        run_itype_tests();
        run_load_store_tests();
        run_branch_tests();
        run_u_jtype_tests();
        run_system_fence_pseudo_tests();
        run_aes_nist_tests();
        run_aes_ctr_tests();
        run_sensor_mmio_tests();
        run_sensor_spi_ip_tests();
        run_uart_mmio_tests();
        run_end_to_end_uart_aes_ctr_tests();
        run_interrupt_tests();
        run_dma_lite_tests();
        run_power_activity_tests();
        run_custom_isa_tests();
        run_signal_activity_tests();
        run_random_coverage_tests();

        run_cycles(PIPE_DRAIN);

        $display("\n================================================");
        $display("RV32I-style directed verification summary: PASS=%0d FAIL=%0d", pass_count, fail_count);
        $display("Lightweight IoT Security Processor + Custom ISA verification summary: PASS=%0d FAIL=%0d", pass_count, fail_count);
        $display("================================================\n");

        if (fail_count == 0) begin
            $display("ALL TESTS PASSED");
        end else begin
            $display("SOME TESTS FAILED");
        end

        #20;
        $finish;
    end
`endif
endmodule

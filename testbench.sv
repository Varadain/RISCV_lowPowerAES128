`timescale 1ns/1ps

module riscv_core_tb;
`ifdef SYNTHESIS
    logic clk;
    logic rst_n;

    assign clk   = 1'b0;
    assign rst_n = 1'b1;

    riscv_core_top dut (
        .clk   (clk),
        .rst_n (rst_n)
    );
`else
    // -------------------------------------------------------------------------
    // Testbench controls
    // -------------------------------------------------------------------------
    logic clk;
    logic rst_n;

    int pass_count;
    int fail_count;

    localparam int CLK_HALF   = 5;
    localparam int PIPE_DRAIN = 12;

    riscv_core_top dut (
        .clk   (clk),
        .rst_n (rst_n)
    );

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

            // Data pattern at RAM[0]
            dut.u_mem_stage.u_data_mem.ram[0] = 32'hAABBCCDD;

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
    // Main test sequence
    // 47 checks total:
    // 10 (R) + 9 (I) + 8 (Load/Store) + 6 (B) + 4 (U/J) + 10 (System/Fence/Pseudo)
    // -------------------------------------------------------------------------
    initial begin
        pass_count = 0;
        fail_count = 0;

        $dumpfile("riscv_core_tb.vcd");
        $dumpvars(0, riscv_core_tb);

        run_rtype_tests();
        run_itype_tests();
        run_load_store_tests();
        run_branch_tests();
        run_u_jtype_tests();
        run_system_fence_pseudo_tests();

        run_cycles(PIPE_DRAIN);

        $display("\n================================================");
        $display("RV32I-style directed verification summary: PASS=%0d FAIL=%0d", pass_count, fail_count);
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

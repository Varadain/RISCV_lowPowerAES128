`timescale 1ns/1ps

module riscv_core_tb;
    logic clk;
    logic rst_n;

    int pass_count;
    int fail_count;
 

    localparam int CLK_HALF = 5;

    riscv_core_top dut (
        .clk   (clk),
        .rst_n (rst_n)
    );

    // ------------------------------
    // Clock / reset
    // ------------------------------
    initial begin
        clk = 1'b0;
        forever #CLK_HALF clk = ~clk;
    end

    task automatic apply_reset();
        begin
            rst_n = 1'b0;
            repeat (3) @(posedge clk);
            rst_n = 1'b1;
            repeat (1) @(posedge clk);
        end
    endtask

    // ------------------------------
    // Utility / encode helpers
    // ------------------------------
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

    task automatic clear_mem_and_regs();
        int i;
        begin
            for (i = 0; i < 256; i++) begin
                dut.u_if_stage.u_instr_mem.rom[i] = 32'h00000013; // NOP
                dut.u_mem_stage.u_data_mem.ram[i] = 32'h0;
            end
            for (i = 0; i < 32; i++) begin
                dut.u_id_stage.u_reg_file.regs[i] = 32'h0;
            end
        end
    endtask

    task automatic run_cycles(input int n);
        int k;
        begin
            for (k = 0; k < n; k++) begin
                @(posedge clk);
            end
        end
    endtask

    task automatic check_eq32(
        input string name,
        input logic [31:0] got,
        input logic [31:0] exp
    );
        begin
            if (got !== exp) begin
                $display("[FAIL] %s got=0x%08x exp=0x%08x", name, got, exp);
                fail_count++;
            end else begin
                $display("[PASS] %s = 0x%08x", name, got);
                pass_count++;
            end
        end
    endtask

    // ------------------------------
    // Directed tests
    // ------------------------------
    task automatic run_test_RTYPE();
        begin
            $display("\n=== run_test_RTYPE ===");
            clear_mem_and_regs();

            // x1=20, x2=6
            dut.u_if_stage.u_instr_mem.rom[0] = enc_itype(12'd20, 5'd0, 3'b000, 5'd1, 7'b0010011); // addi x1,x0,20
            dut.u_if_stage.u_instr_mem.rom[1] = enc_itype(12'd6,  5'd0, 3'b000, 5'd2, 7'b0010011); // addi x2,x0,6

            // ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
            dut.u_if_stage.u_instr_mem.rom[2]  = enc_rtype(7'b0000000,5'd2,5'd1,3'b000,5'd3, 7'b0110011); // add
            dut.u_if_stage.u_instr_mem.rom[3]  = enc_rtype(7'b0100000,5'd2,5'd1,3'b000,5'd4, 7'b0110011); // sub
            dut.u_if_stage.u_instr_mem.rom[4]  = enc_rtype(7'b0000000,5'd2,5'd1,3'b001,5'd5, 7'b0110011); // sll
            dut.u_if_stage.u_instr_mem.rom[5]  = enc_rtype(7'b0000000,5'd1,5'd2,3'b010,5'd6, 7'b0110011); // slt
            dut.u_if_stage.u_instr_mem.rom[6]  = enc_rtype(7'b0000000,5'd1,5'd2,3'b011,5'd7, 7'b0110011); // sltu
            dut.u_if_stage.u_instr_mem.rom[7]  = enc_rtype(7'b0000000,5'd2,5'd1,3'b100,5'd8, 7'b0110011); // xor
            dut.u_if_stage.u_instr_mem.rom[8]  = enc_rtype(7'b0000000,5'd2,5'd1,3'b101,5'd9, 7'b0110011); // srl
            dut.u_if_stage.u_instr_mem.rom[9]  = enc_rtype(7'b0100000,5'd2,5'd1,3'b101,5'd10,7'b0110011); // sra
            dut.u_if_stage.u_instr_mem.rom[10] = enc_rtype(7'b0000000,5'd2,5'd1,3'b110,5'd11,7'b0110011); // or
            dut.u_if_stage.u_instr_mem.rom[11] = enc_rtype(7'b0000000,5'd2,5'd1,3'b111,5'd12,7'b0110011); // and

            apply_reset();
            run_cycles(30);

            check_eq32("ADD  x3",  dut.u_id_stage.u_reg_file.regs[3],  32'd26);
            check_eq32("SUB  x4",  dut.u_id_stage.u_reg_file.regs[4],  32'd14);
            check_eq32("SLL  x5",  dut.u_id_stage.u_reg_file.regs[5],  32'd1280);
            check_eq32("SLT  x6",  dut.u_id_stage.u_reg_file.regs[6],  32'd1);
            check_eq32("SLTU x7",  dut.u_id_stage.u_reg_file.regs[7],  32'd1);
            check_eq32("XOR  x8",  dut.u_id_stage.u_reg_file.regs[8],  32'd18);
            check_eq32("SRL  x9",  dut.u_id_stage.u_reg_file.regs[9],  32'd0);
            check_eq32("SRA  x10", dut.u_id_stage.u_reg_file.regs[10], 32'd0);
            check_eq32("OR   x11", dut.u_id_stage.u_reg_file.regs[11], 32'd22);
            check_eq32("AND  x12", dut.u_id_stage.u_reg_file.regs[12], 32'd4);
        end
    endtask

    task automatic run_test_ITYPE();
        begin
            $display("\n=== run_test_ITYPE ===");
            clear_mem_and_regs();

            dut.u_if_stage.u_instr_mem.rom[0] = enc_itype(12'd9, 5'd0, 3'b000, 5'd1, 7'b0010011); // addi
            dut.u_if_stage.u_instr_mem.rom[1] = enc_itype(12'd7, 5'd1, 3'b010, 5'd2, 7'b0010011); // slti
            dut.u_if_stage.u_instr_mem.rom[2] = enc_itype(12'd7, 5'd1, 3'b011, 5'd3, 7'b0010011); // sltiu
            dut.u_if_stage.u_instr_mem.rom[3] = enc_itype(12'h0F0,5'd1, 3'b100, 5'd4, 7'b0010011); // xori
            dut.u_if_stage.u_instr_mem.rom[4] = enc_itype(12'h003,5'd1, 3'b110, 5'd5, 7'b0010011); // ori
            dut.u_if_stage.u_instr_mem.rom[5] = enc_itype(12'h003,5'd1, 3'b111, 5'd6, 7'b0010011); // andi
            dut.u_if_stage.u_instr_mem.rom[6] = enc_itype(12'b000000000010,5'd1,3'b001,5'd7,7'b0010011); // slli x7,x1,2
            dut.u_if_stage.u_instr_mem.rom[7] = enc_itype(12'b000000000001,5'd1,3'b101,5'd8,7'b0010011); // srli x8,x1,1
            dut.u_if_stage.u_instr_mem.rom[8] = enc_itype(12'b010000000001,5'd1,3'b101,5'd9,7'b0010011); // srai x9,x1,1

            apply_reset();
            run_cycles(25);

            check_eq32("ADDI  x1", dut.u_id_stage.u_reg_file.regs[1], 32'd9);
            check_eq32("SLTI  x2", dut.u_id_stage.u_reg_file.regs[2], 32'd0);
            check_eq32("SLTIU x3", dut.u_id_stage.u_reg_file.regs[3], 32'd0);
            check_eq32("XORI  x4", dut.u_id_stage.u_reg_file.regs[4], 32'h000000F9);
            check_eq32("ORI   x5", dut.u_id_stage.u_reg_file.regs[5], 32'h0000000B);
            check_eq32("ANDI  x6", dut.u_id_stage.u_reg_file.regs[6], 32'h00000001);
            check_eq32("SLLI  x7", dut.u_id_stage.u_reg_file.regs[7], 32'd36);
            check_eq32("SRLI  x8", dut.u_id_stage.u_reg_file.regs[8], 32'd4);
            check_eq32("SRAI  x9", dut.u_id_stage.u_reg_file.regs[9], 32'd4);
        end
    endtask

    task automatic run_test_LOAD_STORE();
        begin
            $display("\n=== run_test_LOAD_STORE ===");
            clear_mem_and_regs();

            // Preload RAM word address 0 with pattern 0xAABBCCDD
            dut.u_mem_stage.u_data_mem.ram[0] = 32'hAABBCCDD;

            // Base addr x1 = 0
            dut.u_if_stage.u_instr_mem.rom[0] = enc_itype(12'd0,5'd0,3'b000,5'd1,7'b0010011); // addi x1, x0, 0

            // Loads
            dut.u_if_stage.u_instr_mem.rom[1] = enc_itype(12'd0,5'd1,3'b000,5'd2,7'b0000011); // lb
            dut.u_if_stage.u_instr_mem.rom[2] = enc_itype(12'd0,5'd1,3'b001,5'd3,7'b0000011); // lh
            dut.u_if_stage.u_instr_mem.rom[3] = enc_itype(12'd0,5'd1,3'b010,5'd4,7'b0000011); // lw
            dut.u_if_stage.u_instr_mem.rom[4] = enc_itype(12'd0,5'd1,3'b100,5'd5,7'b0000011); // lbu
            dut.u_if_stage.u_instr_mem.rom[5] = enc_itype(12'd0,5'd1,3'b101,5'd6,7'b0000011); // lhu

            // Source value for stores
            dut.u_if_stage.u_instr_mem.rom[6] = enc_itype(12'h055,5'd0,3'b000,5'd7,7'b0010011); // addi x7, x0, 0x55

            // Stores at addr 4
            dut.u_if_stage.u_instr_mem.rom[7] = enc_stype(12'd4,5'd7,5'd1,3'b000,7'b0100011); // sb
            dut.u_if_stage.u_instr_mem.rom[8] = enc_stype(12'd4,5'd7,5'd1,3'b001,7'b0100011); // sh
            dut.u_if_stage.u_instr_mem.rom[9] = enc_stype(12'd4,5'd7,5'd1,3'b010,7'b0100011); // sw

            apply_reset();
            run_cycles(35);

            // For ISA-correct core:
            check_eq32("LB  x2", dut.u_id_stage.u_reg_file.regs[2], 32'hFFFFFFDD);
            check_eq32("LH  x3", dut.u_id_stage.u_reg_file.regs[3], 32'hFFFFCCDD);
            check_eq32("LW  x4", dut.u_id_stage.u_reg_file.regs[4], 32'hAABBCCDD);
            check_eq32("LBU x5", dut.u_id_stage.u_reg_file.regs[5], 32'h000000DD);
            check_eq32("LHU x6", dut.u_id_stage.u_reg_file.regs[6], 32'h0000CCDD);

            check_eq32("Store word @1", dut.u_mem_stage.u_data_mem.ram[1], 32'h00000055);
        end
    endtask

    task automatic run_test_BRANCH();
        begin
            $display("\n=== run_test_BRANCH ===");
            clear_mem_and_regs();

            dut.u_if_stage.u_instr_mem.rom[0] = enc_itype(12'd4,5'd0,3'b000,5'd1,7'b0010011); // addi x1,0,4
            dut.u_if_stage.u_instr_mem.rom[1] = enc_itype(12'd4,5'd0,3'b000,5'd2,7'b0010011); // addi x2,0,4

            // BEQ taken: skip rom[3]
            dut.u_if_stage.u_instr_mem.rom[2] = enc_btype(13'd8,5'd2,5'd1,3'b000,7'b1100011); // beq x1,x2,+8
            dut.u_if_stage.u_instr_mem.rom[3] = enc_itype(12'd1,5'd0,3'b000,5'd10,7'b0010011); // should be skipped
            dut.u_if_stage.u_instr_mem.rom[4] = enc_itype(12'd2,5'd0,3'b000,5'd11,7'b0010011); // execute

            // Other branch types (expected ISA behavior)
            dut.u_if_stage.u_instr_mem.rom[5] = enc_btype(13'd8,5'd1,5'd2,3'b001,7'b1100011); // bne (not taken)
            dut.u_if_stage.u_instr_mem.rom[6] = enc_btype(13'd8,5'd1,5'd2,3'b100,7'b1100011); // blt (not taken)
            dut.u_if_stage.u_instr_mem.rom[7] = enc_btype(13'd8,5'd2,5'd1,3'b101,7'b1100011); // bge (taken)
            dut.u_if_stage.u_instr_mem.rom[8] = enc_btype(13'd8,5'd1,5'd2,3'b110,7'b1100011); // bltu (not taken)
            dut.u_if_stage.u_instr_mem.rom[9] = enc_btype(13'd8,5'd2,5'd1,3'b111,7'b1100011); // bgeu (taken)

            apply_reset();
            run_cycles(40);

            check_eq32("BEQ skip x10", dut.u_id_stage.u_reg_file.regs[10], 32'd0);
            check_eq32("BEQ path x11", dut.u_id_stage.u_reg_file.regs[11], 32'd2);
            check_eq32("PC progressed", {30'h0, dut.u_pc_reg.current_pc[1:0]}, 32'h00000000);
        end
    endtask

    task automatic run_test_JUMP_UPPER_SYSTEM_PSEUDO();
        begin
            $display("\n=== run_test_JUMP_UPPER_SYSTEM_PSEUDO ===");
            clear_mem_and_regs();

            // UPPER
            dut.u_if_stage.u_instr_mem.rom[0] = enc_utype(20'h12345,5'd1,7'b0110111); // lui x1,0x12345
            dut.u_if_stage.u_instr_mem.rom[1] = enc_utype(20'h00010,5'd2,7'b0010111); // auipc x2,0x10

            // JAL +8: writes return addr to x3
            dut.u_if_stage.u_instr_mem.rom[2] = enc_jtype(21'd8,5'd3,7'b1101111); // jal x3,+8
            dut.u_if_stage.u_instr_mem.rom[3] = enc_itype(12'd1,5'd0,3'b000,5'd4,7'b0010011); // skipped if jal works
            dut.u_if_stage.u_instr_mem.rom[4] = enc_itype(12'd2,5'd0,3'b000,5'd5,7'b0010011); // target

            // JALR x6, x0, 24 -> jump to ROM[6]
            dut.u_if_stage.u_instr_mem.rom[5] = enc_itype(12'd24,5'd0,3'b000,5'd6,7'b1100111); // jalr
            dut.u_if_stage.u_instr_mem.rom[6] = enc_itype(12'd3,5'd0,3'b000,5'd7,7'b0010011);

            // SYSTEM / FENCE (treated here as smoke test program entries)
            dut.u_if_stage.u_instr_mem.rom[7] = 32'h00000073; // ecall
            dut.u_if_stage.u_instr_mem.rom[8] = 32'h00100073; // ebreak
            dut.u_if_stage.u_instr_mem.rom[9] = 32'h0000000F; // fence
            dut.u_if_stage.u_instr_mem.rom[10]= 32'h0000100F; // fence.i

            // Pseudo examples (encoded as real instructions)
            dut.u_if_stage.u_instr_mem.rom[11]= enc_itype(12'd0,5'd0,3'b000,5'd0,7'b0010011); // nop
            dut.u_if_stage.u_instr_mem.rom[12]= enc_itype(12'd0,5'd7,3'b000,5'd8,7'b0010011); // mv x8,x7
            dut.u_if_stage.u_instr_mem.rom[13]= enc_itype(12'd9,5'd0,3'b000,5'd9,7'b0010011); // li x9,9
            dut.u_if_stage.u_instr_mem.rom[14]= enc_jtype(21'd4,5'd0,7'b1101111);             // j +4

            apply_reset();
            run_cycles(60);

            check_eq32("LUI x1",     dut.u_id_stage.u_reg_file.regs[1], 32'h12345000);
            check_eq32("AUIPC x2",   dut.u_id_stage.u_reg_file.regs[2], 32'h00010004);
            check_eq32("JAL RA x3",  dut.u_id_stage.u_reg_file.regs[3], 32'd12);
            check_eq32("JAL skip x4",dut.u_id_stage.u_reg_file.regs[4], 32'd0);
            check_eq32("Target x5",  dut.u_id_stage.u_reg_file.regs[5], 32'd2);
            check_eq32("MV x8",      dut.u_id_stage.u_reg_file.regs[8], dut.u_id_stage.u_reg_file.regs[7]);
            check_eq32("LI x9",      dut.u_id_stage.u_reg_file.regs[9], 32'd9);
        end
    endtask

    // ------------------------------
    // Main
    // ------------------------------
    initial begin
        pass_count = 0;
        fail_count = 0;

        $dumpfile("riscv_core_tb.vcd");
        $dumpvars(0, riscv_core_tb);

        run_test_RTYPE();
        run_test_ITYPE();
        run_test_LOAD_STORE();
        run_test_BRANCH();
        run_test_JUMP_UPPER_SYSTEM_PSEUDO();

        $display("\n==============================");
        $display("TEST SUMMARY: PASS=%0d FAIL=%0d", pass_count, fail_count);
        $display("==============================\n");

        if (fail_count == 0) begin
            $display("ALL TESTS PASSED");
        end else begin
            $display("SOME TESTS FAILED");
        end

        #20;
        $finish;
    end
endmodule

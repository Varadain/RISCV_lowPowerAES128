`timescale 1ns/1ps

module riscv_core_tb;

    // ==============================
    // DUT
    // ==============================
    logic clk;
    logic rst_n;

    riscv_core_top dut (
        .clk(clk),
        .rst_n(rst_n)
    );

    // ==============================
    // CLOCK
    // ==============================
    initial clk = 0;
    always #5 clk = ~clk;

    // ==============================
    // GLOBALS
    // ==============================
    int pass_count = 0;
    int fail_count = 0;

    localparam PIPE = 12;

    // ==============================
    // COVERAGE ENUM (47 total)
    // ==============================
    typedef enum int {
        ADD,SUB,SLL,SLT,SLTU,XOR_,SRL,SRA,OR_,AND_,
        ADDI,SLTI,SLTIU,XORI,ORI,ANDI,SLLI,SRLI,SRAI,
        LB,LH,LW,LBU,LHU,
        SB,SH,SW,
        BEQ,BNE,BLT,BGE,BLTU,BGEU,
        LUI,AUIPC,
        JAL,JALR,
        ECALL,EBREAK,FENCE,FENCEI,
        NOP,MV,LI,J_SKIP,J_TARGET,NOP2
    } instr_e;

    instr_e current_instr;

    covergroup cg;
        coverpoint current_instr;
    endgroup

    cg cov = new();

    // ==============================
    // HELPERS
    // ==============================
    task reset();
        rst_n = 0;
        repeat(5) @(posedge clk);
        rst_n = 1;
    endtask

    task run(int n);
        repeat(n) @(posedge clk);
    endtask

    task clear_all();
        int i;
        for(i=0;i<256;i++) begin
            dut.u_if_stage.u_instr_mem.rom[i] = 32'h13;
            dut.u_mem_stage.u_data_mem.ram[i] = 0;
        end
        for(i=0;i<32;i++) begin
            dut.u_id_stage.u_reg_file.regs[i] = 0;
        end
    endtask

    task load(int addr, logic [31:0] instr);
        dut.u_if_stage.u_instr_mem.rom[addr[9:2]] = instr;
    endtask

    task set_reg(int r, logic [31:0] v);
        if(r!=0) dut.u_id_stage.u_reg_file.regs[r]=v;
    endtask

    // ==============================
    // CHECK + TRACE
    // ==============================
    task check(string group, string name,
               logic [31:0] got,
               logic [31:0] exp,
               instr_e id);

        current_instr = id;
        cov.sample();

        if(got==exp) begin
            pass_count++;
            $display("%s %s -> got=0x%08x expected=0x%08x -> PASS",
                      group,name,got,exp);
        end else begin
            fail_count++;
            $display("%s %s -> got=0x%08x expected=0x%08x -> FAIL",
                      group,name,got,exp);
        end
    endtask

    // ==============================
    // ENCODERS
    // ==============================
    function automatic [31:0] R;
        input [6:0] f7; input [4:0] rs2,rs1;
        input [2:0] f3; input [4:0] rd; input [6:0] op;
        R = {f7,rs2,rs1,f3,rd,op};
    endfunction

    function automatic [31:0] I;
        input [11:0] imm; input [4:0] rs1;
        input [2:0] f3; input [4:0] rd; input [6:0] op;
        I = {imm,rs1,f3,rd,op};
    endfunction

    function automatic [31:0] S;
        input [11:0] imm; input [4:0] rs2,rs1;
        input [2:0] f3; input [6:0] op;
        S = {imm[11:5],rs2,rs1,f3,imm[4:0],op};
    endfunction

    function automatic [31:0] B;
        input [12:0] imm; input [4:0] rs2,rs1;
        input [2:0] f3; input [6:0] op;
        B = {imm[12],imm[10:5],rs2,rs1,f3,imm[4:1],imm[11],op};
    endfunction

    function automatic [31:0] U;
        input [19:0] imm; input [4:0] rd; input [6:0] op;
        U = {imm,rd,op};
    endfunction

    function automatic [31:0] J;
        input [20:0] imm; input [4:0] rd; input [6:0] op;
        J = {imm[20],imm[10:1],imm[11],imm[19:12],rd,op};
    endfunction

    // ==============================
    // MAIN
    // ==============================
    initial begin

        $dumpfile("tb.vcd");
        $dumpvars(0,riscv_core_tb);

        // ==========================
        // R-TYPE (10)
        // ==========================
        $display("\n=== R-type tests ===");

        clear_all(); set_reg(1,20); set_reg(2,6);
        load(0,R(0,2,1,0,3,7'h33));
        reset(); run(PIPE);
        check("[R]","ADD",dut.u_id_stage.u_reg_file.regs[3],26,ADD);

        clear_all(); set_reg(1,20); set_reg(2,6);
        load(0,R(7'h20,2,1,0,4,7'h33));
        reset(); run(PIPE);
        check("[R]","SUB",dut.u_id_stage.u_reg_file.regs[4],14,SUB);

        clear_all(); set_reg(1,20); set_reg(2,6);
        load(0,R(0,2,1,1,5,7'h33));
        reset(); run(PIPE);
        check("[R]","SLL",dut.u_id_stage.u_reg_file.regs[5],1280,SLL);

        clear_all(); set_reg(1,20); set_reg(2,6);
        load(0,R(0,2,1,2,6,7'h33));
        reset(); run(PIPE);
        check("[R]","SLT",dut.u_id_stage.u_reg_file.regs[6],0,SLT);

        clear_all(); set_reg(1,20); set_reg(2,6);
        load(0,R(0,2,1,3,7,7'h33));
        reset(); run(PIPE);
        check("[R]","SLTU",dut.u_id_stage.u_reg_file.regs[7],0,SLTU);

        clear_all(); set_reg(1,32'h14); set_reg(2,32'h06);
        load(0,R(0,2,1,4,8,7'h33));
        reset(); run(PIPE);
        check("[R]","XOR",dut.u_id_stage.u_reg_file.regs[8],32'h12,XOR_);

        clear_all(); set_reg(1,20); set_reg(2,2);
        load(0,R(0,2,1,5,9,7'h33));
        reset(); run(PIPE);
        check("[R]","SRL",dut.u_id_stage.u_reg_file.regs[9],5,SRL);

        clear_all(); set_reg(1,32'hfffffff0); set_reg(2,2);
        load(0,R(7'h20,2,1,5,10,7'h33));
        reset(); run(PIPE);
        check("[R]","SRA",dut.u_id_stage.u_reg_file.regs[10],32'hfffffffc,SRA);

        clear_all(); set_reg(1,32'h14); set_reg(2,32'h06);
        load(0,R(0,2,1,6,11,7'h33));
        reset(); run(PIPE);
        check("[R]","OR",dut.u_id_stage.u_reg_file.regs[11],32'h16,OR_);

        clear_all(); set_reg(1,32'h14); set_reg(2,32'h06);
        load(0,R(0,2,1,7,12,7'h33));
        reset(); run(PIPE);
        check("[R]","AND",dut.u_id_stage.u_reg_file.regs[12],32'h04,AND_);
      $display("\n=== LOAD/STORE ===");

// LB
clear_all();
dut.u_mem_stage.u_data_mem.ram[0]=32'hAABBCCDD;
load(0,I(0,0,0,2,7'h03));
reset(); run(PIPE);
check("[LOAD]","LB",dut.u_id_stage.u_reg_file.regs[2],32'hFFFFFFDD,LB);

// LH
clear_all();
dut.u_mem_stage.u_data_mem.ram[0]=32'hAABBCCDD;
load(0,I(0,0,1,3,7'h03));
reset(); run(PIPE);
check("[LOAD]","LH",dut.u_id_stage.u_reg_file.regs[3],32'hFFFFCCDD,LH);

// LW
clear_all();
dut.u_mem_stage.u_data_mem.ram[0]=32'hAABBCCDD;
load(0,I(0,0,2,4,7'h03));
reset(); run(PIPE);
check("[LOAD]","LW",dut.u_id_stage.u_reg_file.regs[4],32'hAABBCCDD,LW);

// LBU
clear_all();
dut.u_mem_stage.u_data_mem.ram[0]=32'hAABBCCDD;
load(0,I(0,0,4,5,7'h03));
reset(); run(PIPE);
check("[LOAD]","LBU",dut.u_id_stage.u_reg_file.regs[5],32'h000000DD,LBU);

// LHU
clear_all();
dut.u_mem_stage.u_data_mem.ram[0]=32'hAABBCCDD;
load(0,I(0,0,5,6,7'h03));
reset(); run(PIPE);
check("[LOAD]","LHU",dut.u_id_stage.u_reg_file.regs[6],32'h0000CCDD,LHU);

// SB
clear_all();
set_reg(7,32'h55);
load(0,S(4,7,0,0,7'h23));
reset(); run(PIPE);
check("[STORE]","SB",dut.u_mem_stage.u_data_mem.ram[1],32'h00000055,SB);

// SH
clear_all();
set_reg(7,32'h55AA);
load(0,S(8,7,0,1,7'h23));
reset(); run(PIPE);
check("[STORE]","SH",dut.u_mem_stage.u_data_mem.ram[2],32'h000055AA,SH);

// SW
clear_all();
set_reg(7,32'hDEADBEEF);
load(0,S(12,7,0,2,7'h23));
reset(); run(PIPE);
check("[STORE]","SW",dut.u_mem_stage.u_data_mem.ram[3],32'hDEADBEEF,SW);
      $display("\n=== BRANCH ===");

// BEQ not taken
clear_all(); set_reg(1,1); set_reg(2,2);
load(0,B(8,2,1,0,7'h63));
load(4,I(1,0,0,10,7'h13));
reset(); run(PIPE);
check("[B]","BEQ",dut.u_id_stage.u_reg_file.regs[10],1,BEQ);

// BNE taken
clear_all(); set_reg(1,1); set_reg(2,2);
load(0,B(8,2,1,1,7'h63));
load(8,I(0,0,0,10,7'h13));
reset(); run(PIPE);
check("[B]","BNE",dut.u_id_stage.u_reg_file.regs[10],0,BNE);

// BLT
clear_all(); set_reg(1,-1); set_reg(2,2);
load(0,B(8,2,1,4,7'h63));
load(8,I(0,0,0,10,7'h13));
reset(); run(PIPE);
check("[B]","BLT",dut.u_id_stage.u_reg_file.regs[10],0,BLT);

// BGE
clear_all(); set_reg(1,1); set_reg(2,2);
load(0,B(8,2,1,5,7'h63));
load(4,I(1,0,0,10,7'h13));
reset(); run(PIPE);
check("[B]","BGE",dut.u_id_stage.u_reg_file.regs[10],1,BGE);

// BLTU
clear_all(); set_reg(1,1); set_reg(2,2);
load(0,B(8,2,1,6,7'h63));
load(8,I(0,0,0,10,7'h13));
reset(); run(PIPE);
check("[B]","BLTU",dut.u_id_stage.u_reg_file.regs[10],0,BLTU);

// BGEU
clear_all(); set_reg(1,1); set_reg(2,2);
load(0,B(8,2,1,7,7'h63));
load(4,I(1,0,0,10,7'h13));
reset(); run(PIPE);
check("[B]","BGEU",dut.u_id_stage.u_reg_file.regs[10],1,BGEU);
      $display("\n=== U/J ===");

// LUI
clear_all();
load(0,U(20'h12345,1,7'h37));
reset(); run(PIPE);
check("[U]","LUI",dut.u_id_stage.u_reg_file.regs[1],32'h12345000,LUI);

// AUIPC
clear_all();
load(0,U(20'h1,2,7'h17));
reset(); run(PIPE);
check("[U]","AUIPC",dut.u_id_stage.u_reg_file.regs[2],32'h00001000,AUIPC);

// JAL
clear_all();
load(0,J(8,3,7'h6F));
load(8,I(2,0,0,20,7'h13));
reset(); run(PIPE);
check("[J]","JAL",dut.u_id_stage.u_reg_file.regs[3],4,JAL);

// JALR
clear_all(); set_reg(1,8);
load(0,I(0,1,0,6,7'h67));
load(8,I(2,0,0,21,7'h13));
reset(); run(PIPE);
check("[J]","JALR",dut.u_id_stage.u_reg_file.regs[6],4,JALR);
      $display("\n=== SYSTEM/PSEUDO ===");

// ECALL
clear_all(); set_reg(29,7);
load(0,32'h00000073);
reset(); run(PIPE);
check("[SYS]","ECALL",dut.u_id_stage.u_reg_file.regs[29],7,ECALL);

// EBREAK
clear_all(); set_reg(29,7);
load(0,32'h00100073);
reset(); run(PIPE);
check("[SYS]","EBREAK",dut.u_id_stage.u_reg_file.regs[29],7,EBREAK);

// FENCE
clear_all(); set_reg(31,5);
load(0,32'h0FF0000F);
reset(); run(PIPE);
check("[SYS]","FENCE",dut.u_id_stage.u_reg_file.regs[31],5,FENCE);

// FENCE.I
clear_all(); set_reg(31,5);
load(0,32'h0000100F);
reset(); run(PIPE);
check("[SYS]","FENCEI",dut.u_id_stage.u_reg_file.regs[31],5,FENCEI);

// NOP
clear_all();
load(0,I(0,0,0,0,7'h13));
reset(); run(PIPE);
check("[SYS]","NOP",dut.u_id_stage.u_reg_file.regs[0],0,NOP);

// MV
clear_all(); set_reg(5,2);
load(0,I(0,5,0,8,7'h13));
reset(); run(PIPE);
check("[SYS]","MV",dut.u_id_stage.u_reg_file.regs[8],2,MV);

// LI
clear_all();
load(0,I(9,0,0,9,7'h13));
reset(); run(PIPE);
check("[SYS]","LI",dut.u_id_stage.u_reg_file.regs[9],9,LI);

// J skip/target already done earlier

// NOP2
clear_all(); set_reg(10,0);
load(0,I(0,10,0,11,7'h13));
reset(); run(PIPE);
check("[SYS]","NOP2",dut.u_id_stage.u_reg_file.regs[11],0,NOP2);

        // ==========================
        // I-TYPE (9)
        // ==========================
        $display("\n=== I-type tests ===");

        clear_all(); load(0,I(9,0,0,1,7'h13));
        reset(); run(PIPE);
        check("[I]","ADDI",dut.u_id_stage.u_reg_file.regs[1],9,ADDI);

        clear_all(); set_reg(1,9);
        load(0,I(7,1,2,2,7'h13));
        reset(); run(PIPE);
        check("[I]","SLTI",dut.u_id_stage.u_reg_file.regs[2],0,SLTI);

        clear_all(); set_reg(1,9);
        load(0,I(7,1,3,3,7'h13));
        reset(); run(PIPE);
        check("[I]","SLTIU",dut.u_id_stage.u_reg_file.regs[3],0,SLTIU);

        clear_all(); set_reg(1,9);
        load(0,I(12'hF0,1,4,4,7'h13));
        reset(); run(PIPE);
        check("[I]","XORI",dut.u_id_stage.u_reg_file.regs[4],32'hF9,XORI);

        clear_all(); set_reg(1,9);
        load(0,I(3,1,6,5,7'h13));
        reset(); run(PIPE);
        check("[I]","ORI",dut.u_id_stage.u_reg_file.regs[5],32'h0B,ORI);

        clear_all(); set_reg(1,9);
        load(0,I(3,1,7,6,7'h13));
        reset(); run(PIPE);
        check("[I]","ANDI",dut.u_id_stage.u_reg_file.regs[6],1,ANDI);

        clear_all(); set_reg(1,9);
        load(0,I(2,1,1,7,7'h13));
        reset(); run(PIPE);
        check("[I]","SLLI",dut.u_id_stage.u_reg_file.regs[7],36,SLLI);

        clear_all(); set_reg(1,9);
        load(0,I(1,1,5,8,7'h13));
        reset(); run(PIPE);
        check("[I]","SRLI",dut.u_id_stage.u_reg_file.regs[8],4,SRLI);

        clear_all(); set_reg(1,9);
        load(0,I(12'h401,1,5,9,7'h13));
        reset(); run(PIPE);
        check("[I]","SRAI",dut.u_id_stage.u_reg_file.regs[9],4,SRAI);

        // ==========================
        // J TEST FIX (CRITICAL)
        // ==========================
        $display("\n=== J test ===");

        clear_all();
        load(0,J(8,0,7'h6F));
        load(4,I(1,0,0,27,7'h13)); // skip
        load(8,I(1,0,0,28,7'h13)); // target
        reset(); run(PIPE);

        check("[J]","skip",dut.u_id_stage.u_reg_file.regs[27],0,J_SKIP);
        check("[J]","target",dut.u_id_stage.u_reg_file.regs[28],1,J_TARGET);

        // ==========================
        // SUMMARY
        // ==========================
        $display("\n================================================");
        $display("PASS=%0d FAIL=%0d",pass_count,fail_count);
        $display("Coverage=%0.2f%%",cov.get_coverage());
        $display("================================================");

        $finish;
    end

endmodule

`timescale 1ns/1ps

// ============================================================
// RISC-V CORE TESTBENCH (SELF-CHECKING, DIRECTED)
// ============================================================
//
// PURPOSE:
// --------
// This testbench verifies whether the RISC-V processor correctly executes instructions.
//
// It:
//   1. Loads instructions into instruction memory
//   2. Runs the processor (clock-driven)
//   3. Observes results in register file / memory
//   4. Compares with expected results
//   5. Prints PASS / FAIL
//
// ------------------------------------------------------------
// HIGH-LEVEL EXECUTION FLOW:
//
//   [Load Instructions] → [Reset CPU] → [Run Clock Cycles]
//       → [Pipeline Executes Instructions]
//       → [Check Results] → [PASS / FAIL]
//
// ------------------------------------------------------------
// PIPELINE BEHAVIOR:
//
//   IF → ID → EX → MEM → WB
//
//   Each instruction takes multiple cycles to complete.
//   Multiple instructions are active simultaneously.
//
// ------------------------------------------------------------
// HOW CORRECTNESS IS VERIFIED:
//
//   For each instruction:
//     Expected result is calculated manually
//     Actual result is read from register/memory
//     Compared using check_and_report()
//
// ------------------------------------------------------------
// OUTPUT FORMAT:
//
//   [TYPE] INSTR: explanation → got=... expected=... → PASS/FAIL
//
// ------------------------------------------------------------

module riscv_core_tb;

`ifdef SYNTHESIS
    // --------------------------------------------------------
    // SYNTHESIS MODE (ignored during simulation)
    // --------------------------------------------------------
    logic clk;
    logic rst_n;

    assign clk   = 1'b0;
    assign rst_n = 1'b1;

    riscv_core_top dut (
        .clk(clk),
        .rst_n(rst_n)
    );

`else

    // ========================================================
    // TESTBENCH CONTROL SIGNALS
    // ========================================================

    logic clk;      // clock signal driving CPU
    logic rst_n;    // reset signal

    int pass_count; // number of passed checks
    int fail_count; // number of failed checks

    // Clock timing parameters
    localparam int CLK_HALF   = 5;   // half period = 5ns → 10ns clock
    localparam int PIPE_DRAIN = 12;  // cycles to flush pipeline

    // ========================================================
    // DUT (Device Under Test)
    // ========================================================
    riscv_core_top dut (
        .clk(clk),
        .rst_n(rst_n)
    );

    // ========================================================
    // CLOCK GENERATION
    // ========================================================
    //
    // Creates continuous clock:
    //
    //    clk: 0 → 1 → 0 → 1 ...
    //
    // Every instruction progresses on rising edge
    //
    initial clk = 1'b0;
    always #CLK_HALF clk = ~clk;

    // ========================================================
    // RESET TASK
    // ========================================================
    //
    // Reset clears pipeline + registers
    //
    // Timeline:
    //
    //   rst_n = 0 → system reset
    //   wait few cycles
    //   rst_n = 1 → start execution
    //
    task automatic apply_reset();
        begin
            rst_n = 1'b0;
            repeat (3) @(posedge clk); // hold reset
            rst_n = 1'b1;
            repeat (1) @(posedge clk); // stabilize
        end
    endtask

    // ========================================================
    // RUN CYCLES TASK
    // ========================================================
    //
    // Advances simulation by N clock cycles
    //
    // Used to allow pipeline to execute instructions
    //
    task automatic run_cycles(input int cycles);
        int i;
        begin
            for (i = 0; i < cycles; i++) begin
                @(posedge clk);
            end
        end
    endtask

    // ========================================================
    // INSTRUCTION ENCODERS
    // ========================================================
    //
    // These functions convert human-readable instruction fields
    // into 32-bit machine instructions.
    //
    // Example:
    //   ADD x3, x1, x2 → binary encoding
    //
    // --------------------------------------------------------
    // R-TYPE FORMAT:
    //
    // [funct7][rs2][rs1][funct3][rd][opcode]
    //
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

    // Similar encoding logic for I/S/B/U/J formats...

    // ========================================================
    // MEMORY + REGISTER INITIALIZATION
    // ========================================================
    //
    // Clears everything before each test
    //
    // Why?
    // → Avoid leftover values from previous tests
    //
    task automatic clear_mem_and_regs();
        int i;
        begin
            // Fill instruction memory with NOPs
            for (i = 0; i < 256; i++) begin
                dut.u_if_stage.u_instr_mem.rom[i] = 32'h00000013;
                dut.u_mem_stage.u_data_mem.ram[i] = 32'h0;
            end

            // Reset register file
            for (i = 0; i < 32; i++) begin
                dut.u_id_stage.u_reg_file.regs[i] = 32'h0;
            end
        end
    endtask

    // ========================================================
    // CHECK FUNCTION (CORE OF VERIFICATION)
    // ========================================================
    //
    // This is where correctness is VERIFIED
    //
    // Steps:
    //   1. Compare actual result vs expected
    //   2. Print result
    //   3. Update pass/fail counters
    //
    // Example output:
    //   ADD → got=26 expected=26 → PASS
    //
    task automatic check_and_report(
        input string itype,
        input string mnemonic,
        input string op_text,
        input logic [31:0] got,
        input logic [31:0] exp
    );
        begin
            if (got !== exp) begin
                $display("[%s] %s: %s -> got=0x%08x expected=0x%08x -> FAIL",
                          itype, mnemonic, op_text, got, exp);
                fail_count++;
            end else begin
                $display("[%s] %s: %s -> got=0x%08x expected=0x%08x -> PASS",
                          itype, mnemonic, op_text, got, exp);
                pass_count++;
            end
        end
    endtask

    // ========================================================
    // TEST GROUP STRUCTURE
    // ========================================================
    //
    // Each group tests a class of instructions:
    //
    //   R-type   → ADD, SUB, AND, OR...
    //   I-type   → ADDI, ANDI...
    //   Load/Store
    //   Branch
    //   Jump
    //   System/Fence/Pseudo
    //
    // Each group:
    //   1. Loads instructions into memory
    //   2. Applies reset
    //   3. Runs cycles
    //   4. Checks results
    //
    // ========================================================

    // Example explanation (R-type group):
    //
    // Instruction Flow:
    //
    //   x1 = 20
    //   x2 = 6
    //
    //   ADD  → x3 = 26
    //   SUB  → x4 = 14
    //   SLL  → x5 = 1280
    //
    // Pipeline executes these automatically.

    // (Remaining test tasks unchanged — only explained conceptually)

    // ========================================================
    // MAIN TEST SEQUENCE
    // ========================================================
    //
    // This is where simulation starts
    //
    // FLOW:
    //
    //   1. Initialize counters
    //   2. Enable waveform dump
    //   3. Run all test groups
    //   4. Drain pipeline
    //   5. Print summary
    //
    initial begin
        pass_count = 0;
        fail_count = 0;

        // Enable waveform dump (for EPWave)
        $dumpfile("riscv_core_tb.vcd");
        $dumpvars(0, riscv_core_tb);

        // Run all instruction groups
        run_rtype_tests();
        run_itype_tests();
        run_load_store_tests();
        run_branch_tests();
        run_u_jtype_tests();
        run_system_fence_pseudo_tests();

        // Allow pipeline to finish last instructions
        run_cycles(PIPE_DRAIN);

        // ====================================================
        // FINAL SUMMARY
        // ====================================================
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

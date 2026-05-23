`timescale 1ns / 1ps

module tb_aes128_lowpower;

    reg clk;
    reg reset;
    reg clk_en;
    reg start;

    reg  [127:0] plaintext;
    reg  [127:0] key;
    wire [127:0] ciphertext;
    wire done;

    integer pass_count;
    integer fail_count;
    integer test_id;
    reg [8*32-1:0] test_name;

    IterativeAES DUT (
        .clk        (clk),
        .reset      (reset),
        .clk_en     (clk_en),
        .start      (start),
        .plaintext  (plaintext),
        .key        (key),
        .ciphertext (ciphertext),
        .done       (done)
    );

    always #5 clk = ~clk;   // 100 MHz

    task automatic apply_reset;
        begin
            reset = 1'b1;
            clk_en = 1'b1;
            start = 1'b0;
            plaintext = 128'h0;
            key = 128'h0;
            repeat (3) @(posedge clk);
            reset = 1'b0;
            @(posedge clk);
        end
    endtask

    task automatic run_vector(
        input integer id,
        input [8*32-1:0] name,
        input [127:0] pt,
        input [127:0] aes_key,
        input [127:0] expected_ct
    );
        integer cycles;
        begin
            test_id = id;
            test_name = name;
            @(negedge clk);
            plaintext = pt;
            key = aes_key;
            start = 1'b1;
            @(posedge clk);
            @(negedge clk);
            start = 1'b0;

            cycles = 0;
            while (!done && cycles < 20) begin
                @(posedge clk);
                cycles = cycles + 1;
            end

            if (!done) begin
                fail_count = fail_count + 1;
                $display("[FAIL] Test %0d %-32s timed out", id, name);
            end else if (ciphertext === expected_ct) begin
                pass_count = pass_count + 1;
                $display("[PASS] Test %0d %-32s CT=%032h cycles=%0d",
                         id, name, ciphertext, cycles);
            end else begin
                fail_count = fail_count + 1;
                $display("[FAIL] Test %0d %-32s", id, name);
                $display("       PT       = %032h", pt);
                $display("       Key      = %032h", aes_key);
                $display("       Expected = %032h", expected_ct);
                $display("       Got      = %032h", ciphertext);
            end

            @(posedge clk);
        end
    endtask

    task automatic run_clk_en_stall_vector;
        integer cycles;
        reg [3:0] round_before_stall;
        reg [127:0] state_before_stall;
        reg stall_hold_ok;
        begin
            test_id = 6;
            test_name = "clk_en stall resume vector     ";
            stall_hold_ok = 1'b1;
            @(negedge clk);
            plaintext = 128'h00112233445566778899aabbccddeeff;
            key = 128'h000102030405060708090a0b0c0d0e0f;
            start = 1'b1;
            @(posedge clk);
            @(negedge clk);
            start = 1'b0;

            repeat (3) @(posedge clk);
            @(negedge clk);
            round_before_stall = DUT.round;
            state_before_stall = DUT.state;

            clk_en = 1'b0;
            repeat (4) @(posedge clk);
            @(negedge clk);

            if (DUT.round !== round_before_stall || DUT.state !== state_before_stall) begin
                fail_count = fail_count + 1;
                stall_hold_ok = 1'b0;
                $display("[FAIL] Test 6 clk_en stall resume vector");
                $display("       State or round changed while clk_en was low.");
                $display("       Expected round/state = %0d/%032h",
                         round_before_stall, state_before_stall);
                $display("       Got round/state      = %0d/%032h", DUT.round, DUT.state);
            end else begin
                $display("[INFO] Test 6 clk_en stall held round/state for 4 cycles");
            end

            clk_en = 1'b1;
            cycles = 0;
            while (!done && cycles < 20) begin
                @(posedge clk);
                cycles = cycles + 1;
            end

            if (!done) begin
                fail_count = fail_count + 1;
                $display("[FAIL] Test 6 clk_en stall resume vector timed out");
            end else if (stall_hold_ok && ciphertext === 128'h69c4e0d86a7b0430d8cdb78070b4c55a) begin
                pass_count = pass_count + 1;
                $display("[PASS] Test 6 clk_en stall resume vector CT=%032h cycles_after_resume=%0d",
                         ciphertext, cycles);
            end else if (stall_hold_ok) begin
                fail_count = fail_count + 1;
                $display("[FAIL] Test 6 clk_en stall resume vector");
                $display("       Expected = 69c4e0d86a7b0430d8cdb78070b4c55a");
                $display("       Got      = %032h", ciphertext);
            end

            @(posedge clk);
        end
    endtask

    initial begin
        $dumpfile("aes128_lowpower_multitest.vcd");
        $dumpvars(0, tb_aes128_lowpower);

        clk = 1'b0;
        reset = 1'b0;
        clk_en = 1'b1;
        start = 1'b0;
        plaintext = 128'h0;
        key = 128'h0;
        pass_count = 0;
        fail_count = 0;
        test_id = 0;
        test_name = "initializing                     ";

        apply_reset();

        run_vector(1, "NIST FIPS-197 example          ",
                   128'h00112233445566778899aabbccddeeff,
                   128'h000102030405060708090a0b0c0d0e0f,
                   128'h69c4e0d86a7b0430d8cdb78070b4c55a);

        run_vector(2, "SP800-38A ECB block 1          ",
                   128'h6bc1bee22e409f96e93d7e117393172a,
                   128'h2b7e151628aed2a6abf7158809cf4f3c,
                   128'h3ad77bb40d7a3660a89ecaf32466ef97);

        run_vector(3, "SP800-38A ECB block 2          ",
                   128'hae2d8a571e03ac9c9eb76fac45af8e51,
                   128'h2b7e151628aed2a6abf7158809cf4f3c,
                   128'hf5d3d58503b9699de785895a96fdbaaf);

        run_vector(4, "SP800-38A ECB block 3          ",
                   128'h30c81c46a35ce411e5fbc1191a0a52ef,
                   128'h2b7e151628aed2a6abf7158809cf4f3c,
                   128'h43b1cd7f598ece23881b00e3ed030688);

        run_vector(5, "zero plaintext zero key        ",
                   128'h00000000000000000000000000000000,
                   128'h00000000000000000000000000000000,
                   128'h66e94bd4ef8a2c3b884cfa59ca342b2e);

        run_clk_en_stall_vector();

        $display("==============================================");
        $display(" AES-128 MULTI-TEST SUMMARY: PASS=%0d FAIL=%0d", pass_count, fail_count);
        $display(" Waveform: aes128_lowpower_multitest.vcd");
        $display("==============================================");

        #20;
        if (fail_count == 0) begin
            $finish;
        end else begin
            $fatal(1, "AES-128 multi-testbench failed");
        end
    end

endmodule

`timescale 1ns/1ps
// Small first exercise: test the reusable core without the processor or MMIO.
module aes128_core_tb;
    logic clk = 0;
    always #5 clk = ~clk;
    logic reset = 1, start = 0;
    logic [127:0] key = 0, plaintext = 0;
    wire [127:0] ciphertext;
    wire busy, done;
    AES128_updated_new dut(.*);

    task automatic encrypt_and_check(
        input logic [127:0] k, p, expected,
        input bit inject_busy_start
    );
        integer cycles;
        begin
            @(negedge clk);
            key = k; plaintext = p; start = 1;
            @(negedge clk);
            start = 0;
            if (!busy) $fatal(1, "Core did not accept start");
            cycles = 0;
            while (!done && cycles < 500) begin
                // A second request must not restart an in-flight block.
                if (inject_busy_start && cycles == 8) start = 1;
                else start = 0;
                @(negedge clk);
                cycles++;
            end
            start = 0;
            if (!done) $fatal(1, "AES timeout");
            if (busy || ciphertext !== expected)
                $fatal(1, "AES mismatch: got %032h expected %032h", ciphertext, expected);
            $display("AES CORE PASS: ciphertext=%032h wait_cycles=%0d", ciphertext, cycles);
            @(negedge clk);
            if (done) $fatal(1, "done must clear in IDLE");
            if (ciphertext !== expected) $fatal(1, "Ciphertext must remain stable");
        end
    endtask

    initial begin
        repeat (3) @(negedge clk);
        reset = 0;
        encrypt_and_check(128'h000102030405060708090a0b0c0d0e0f,
                          128'h00112233445566778899aabbccddeeff,
                          128'h69c4e0d86a7b0430d8cdb78070b4c55a, 1);
        encrypt_and_check(128'h0, 128'h0,
                          128'h66e94bd4ef8a2c3b884cfa59ca342b2e, 0);
        $display("ALL TESTS PASSED: AES core, two known-answer vectors and handshake checks");
        $finish;
    end
endmodule

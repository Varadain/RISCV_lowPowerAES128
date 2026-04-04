`timescale 1ns/1ps
//==============================================================
// Testbench: aes128_lowpower_tb
// Description:
// Verification environment for AES-128 low-power RTL
// Includes:
//  - Functional verification (NIST + custom vectors)
//  - Power-aware validation (clock gating behavior)
//  - Basic switching activity estimation
//==============================================================

module aes128_lowpower_tb;

    //----------------------------------------------------------
    // Simulation Parameters
    //----------------------------------------------------------

    // Half clock period (ns) → full clock = 10ns
    localparam int CLK_HALF = 5;

    // Maximum cycles to wait before declaring timeout
    localparam int DONE_TIMEOUT_CYCLES = 200;

    //----------------------------------------------------------
    // DUT Interface Signals
    //----------------------------------------------------------

    // Clock signal driving DUT
    reg clk;

    // Asynchronous reset
    reg reset;

    // Clock enable (used for low-power gating)
    reg clk_en;

    // Start signal to trigger encryption
    reg start;

    // AES inputs
    reg [127:0] plaintext;
    reg [127:0] key;

    // AES outputs
    wire [127:0] ciphertext;
    wire         done;

    //----------------------------------------------------------
    // Verification Metrics
    //----------------------------------------------------------

    // Count number of passing tests
    integer pass_count;

    // Count number of failing tests
    integer fail_count;

    // Approximate switching activity (for power insight)
    integer state_toggle_count;
    integer round_key_toggle_count;

    // Store previous values to detect toggles
    reg [127:0] prev_state;
    reg [127:0] prev_round_key;

    //----------------------------------------------------------
    // DUT Instantiation
    //----------------------------------------------------------

    // Instantiate AES RTL (Device Under Test)
    aes128_lowpower dut (
        .clk(clk),
        .reset(reset),
        .clk_en(clk_en),
        .start(start),
        .plaintext(plaintext),
        .key(key),
        .ciphertext(ciphertext),
        .done(done)
    );

    //----------------------------------------------------------
    // Clock Generation
    //----------------------------------------------------------

    // Toggle clock every CLK_HALF → generates periodic clock
    always #CLK_HALF clk = ~clk;

    //----------------------------------------------------------
    // Switching Activity Monitor (Power Awareness)
    //----------------------------------------------------------

    // This block estimates switching activity by counting
    // how often internal signals change value.
    // NOTE: This is NOT exact power analysis, but gives insight.
    always @(posedge clk) begin
        if (!reset) begin

            // If state changes → count toggle
            if (dut.state !== prev_state)
                state_toggle_count <= state_toggle_count + 1;

            // If round key changes → count toggle
            if (dut.round_key !== prev_round_key)
                round_key_toggle_count <= round_key_toggle_count + 1;

            // Update previous values
            prev_state <= dut.state;
            prev_round_key <= dut.round_key;
        end
    end

    //----------------------------------------------------------
    // Task: Initialize Signals
    //----------------------------------------------------------

    // Sets all signals to known starting values
    task automatic init_signals;
    begin
        clk = 1'b0;                 // Start clock at 0
        reset = 1'b1;               // Assert reset
        clk_en = 1'b0;              // Disable computation
        start = 1'b0;               // No operation yet
        plaintext = 128'h0;
        key = 128'h0;

        // Reset counters
        pass_count = 0;
        fail_count = 0;

        state_toggle_count = 0;
        round_key_toggle_count = 0;

        prev_state = 128'h0;
        prev_round_key = 128'h0;
    end
    endtask

    //----------------------------------------------------------
    // Task: Apply Reset
    //----------------------------------------------------------

    // Ensures DUT starts from a clean state
    task automatic apply_reset;
    begin
        reset = 1'b1;
        clk_en = 1'b0;
        start = 1'b0;

        // Hold reset for a few cycles
        repeat (3) @(posedge clk);

        // Release reset
        reset = 1'b0;

        // Wait one cycle for stability
        @(posedge clk);
    end
    endtask

    //----------------------------------------------------------
    // Task: Wait for Completion or Timeout
    //----------------------------------------------------------

    task automatic wait_done_or_timeout(output bit timed_out);
        integer cycles;
    begin
        timed_out = 1'b1;

        // Wait until done OR timeout reached
        for (cycles = 0; cycles < DONE_TIMEOUT_CYCLES; cycles++) begin
            @(posedge clk);

            if (done) begin
                timed_out = 1'b0;   // Success
                cycles = DONE_TIMEOUT_CYCLES;
            end
        end
    end
    endtask

    //----------------------------------------------------------
    // Task: Check Result
    //----------------------------------------------------------

    // Compares DUT output with expected ciphertext
    task automatic check_result(
        input [1023:0] test_name,
        input [127:0] exp_ct
    );
    begin
        if (ciphertext === exp_ct) begin
            $display("[AES] %0s: PT=%032h KEY=%032h -> CT=%032h -> PASS",
                     test_name, plaintext, key, ciphertext);
            pass_count++;
        end else begin
            $display("[AES] %0s: PT=%032h KEY=%032h -> CT=%032h (EXP=%032h) -> FAIL",
                     test_name, plaintext, key, ciphertext, exp_ct);
            fail_count++;
        end
    end
    endtask

    //----------------------------------------------------------
    // Task: Run One AES Test
    //----------------------------------------------------------

    // This task performs a full encryption test:
    // 1. Apply inputs
    // 2. Trigger start
    // 3. Wait for completion
    // 4. Compare output
    task automatic run_aes_test(
        input [1023:0] test_name,
        input [127:0] pt,
        input [127:0] k,
        input [127:0] exp_ct
    );
        bit timed_out;
    begin
        plaintext = pt;
        key = k;

        // Enable computation
        clk_en = 1'b1;

        // Pulse start signal
        @(posedge clk);
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;

        // Wait for completion
        wait_done_or_timeout(timed_out);

        if (timed_out) begin
            $display("[AES] %0s: TIMEOUT -> FAIL", test_name);
            fail_count++;
        end else begin
            check_result(test_name, exp_ct);
        end

        @(posedge clk);
    end
    endtask

    //----------------------------------------------------------
    // Task: Power Check (Clock Gating Verification)
    //----------------------------------------------------------

    // Verifies that when clk_en = 0:
    //  - Internal state DOES NOT change
    //  - Confirms low-power design correctness
    task automatic power_check_clk_gating;
        reg [127:0] s_hold;
        reg [127:0] rk_hold;
        reg [3:0]   r_hold;
        integer i;
        bit stable;
    begin
        // Start encryption
        plaintext = 128'h00112233445566778899aabbccddeeff;
        key       = 128'h000102030405060708090a0b0c0d0e0f;

        clk_en = 1'b1;
        start  = 1'b1;
        @(posedge clk);
        start  = 1'b0;

        repeat (2) @(posedge clk);

        // Disable clock enable → should freeze state
        clk_en = 1'b0;

        // Capture values
        s_hold  = dut.state;
        rk_hold = dut.round_key;
        r_hold  = dut.round;

        stable = 1'b1;

        // Observe for multiple cycles
        for (i = 0; i < 8; i++) begin
            @(posedge clk);
            if ((dut.state !== s_hold) ||
                (dut.round_key !== rk_hold) ||
                (dut.round !== r_hold))
                stable = 1'b0;
        end

        // Check result
        if (stable) begin
            $display("[POWER] clk_en=0 → state stable → PASS");
            pass_count++;
        end else begin
            $display("[POWER] clk_en=0 → state changed → FAIL");
            fail_count++;
        end

        // Re-enable operation
        clk_en = 1'b1;
        repeat (2) @(posedge clk);
    end
    endtask

    //----------------------------------------------------------
    // Main Simulation
    //----------------------------------------------------------

    initial begin

        // Dump waveform for debugging
        $dumpfile("aes128_lowpower_tb.vcd");
        $dumpvars(0, aes128_lowpower_tb);

        // Initialize and reset
        init_signals();
        apply_reset();

        //------------------------------------------------------
        // Functional Tests (NIST + Custom)
        //------------------------------------------------------

        run_aes_test("NIST-ECB-128",
            128'h00112233445566778899aabbccddeeff,
            128'h000102030405060708090a0b0c0d0e0f,
            128'h69c4e0d86a7b0430d8cdb78070b4c55a);

        run_aes_test("ALL-ZERO",
            128'h00000000000000000000000000000000,
            128'h00000000000000000000000000000000,
            128'h66e94bd4ef8a2c3b884cfa59ca342b2e);

        run_aes_test("RANDOM-1",
            128'hffeeddccbbaa99887766554433221100,
            128'h0f0e0d0c0b0a09080706050403020100,
            128'h29a7a5cc906e274be7a7579ac7e1bfd0);

        //------------------------------------------------------
        // Power Verification
        //------------------------------------------------------

        power_check_clk_gating();

        //------------------------------------------------------
        // Final Report
        //------------------------------------------------------

        $display("[POWER] Toggles: state=%0d round_key=%0d",
                 state_toggle_count, round_key_toggle_count);

        $display("[SUMMARY] PASS=%0d FAIL=%0d", pass_count, fail_count);

        if (fail_count == 0)
            $display("[SUMMARY] ALL TESTS PASSED");
        else
            $display("[SUMMARY] TEST FAILURES DETECTED");

        $finish;
    end

endmodule

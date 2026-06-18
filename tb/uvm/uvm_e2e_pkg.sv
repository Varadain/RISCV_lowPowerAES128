// ============================================================================
// Randomized UVM end-to-end verification package
//
// Transaction flow:
//   randomized sensor data/key/nonce/counter
//       -> independent C-DPI AES-CTR reference
//       -> RTL AES-CTR MMIO programming
//       -> ciphertext comparison and reference decryption
//       -> textual result sent through the real RTL UART
//       -> UART monitor reconstruction
//       -> scoreboard and functional coverage
// ============================================================================
package uvm_e2e_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Independent C model used as the cryptographic golden reference.
    import "DPI-C" function void aes128_ctr_ref(
        input int unsigned key3, input int unsigned key2, input int unsigned key1, input int unsigned key0,
        input int unsigned pt3, input int unsigned pt2, input int unsigned pt1, input int unsigned pt0,
        input int unsigned nonce1, input int unsigned nonce0, input int unsigned counter1, input int unsigned counter0,
        output int unsigned ct3, output int unsigned ct2, output int unsigned ct1, output int unsigned ct0,
        output int unsigned dec3, output int unsigned dec2, output int unsigned dec1, output int unsigned dec0
    );

    `uvm_analysis_imp_decl(_expected)
    `uvm_analysis_imp_decl(_observed)

    // One complete randomized secure-sensor transaction.
    class uvm_e2e_item extends uvm_sequence_item;
        rand bit [127:0] plaintext;
        rand bit [127:0] key;
        rand bit [63:0]  nonce;
        rand bit [63:0]  counter;

        // Results are filled by the driver after C-model and RTL execution.
        bit [127:0] ref_ciphertext;
        bit [127:0] ref_decrypted;
        bit [127:0] rtl_ciphertext;
        string      expected_uart_line;

        constraint nonzero_key_c { key != 128'h0; }
        constraint nonzero_plain_c { plaintext != 128'h0; }

        `uvm_object_utils_begin(uvm_e2e_item)
            `uvm_field_int(plaintext, UVM_ALL_ON)
            `uvm_field_int(key, UVM_ALL_ON)
            `uvm_field_int(nonce, UVM_ALL_ON)
            `uvm_field_int(counter, UVM_ALL_ON)
            `uvm_field_int(ref_ciphertext, UVM_ALL_ON)
            `uvm_field_int(ref_decrypted, UVM_ALL_ON)
            `uvm_field_int(rtl_ciphertext, UVM_ALL_ON)
            `uvm_field_string(expected_uart_line, UVM_ALL_ON)
        `uvm_object_utils_end

        function new(string name = "uvm_e2e_item");
            super.new(name);
        endfunction
    endclass

    // Text line passed between the UART producer, monitor, and scoreboard.
    class uvm_uart_line extends uvm_sequence_item;
        string line;
        `uvm_object_utils_begin(uvm_uart_line)
            `uvm_field_string(line, UVM_ALL_ON)
        `uvm_object_utils_end
        function new(string name = "uvm_uart_line");
            super.new(name);
        endfunction
    endclass

    // Generates repeatable pseudo-random transactions. Plusargs allow a run to
    // change NUM_TXNS and E2E_SEED while preserving reproducibility.
    class uvm_e2e_sequence extends uvm_sequence #(uvm_e2e_item);
        `uvm_object_utils(uvm_e2e_sequence)
        int unsigned num_transactions = 25;
        int unsigned prng_state = 32'h1ace_5eed;

        function new(string name = "uvm_e2e_sequence");
            super.new(name);
        endfunction

        // Small xorshift32 generator avoids dependence on simulator-specific
        // constraint-solver behavior and gives identical data for a known seed.
        function int unsigned next_word();
            prng_state ^= (prng_state << 13);
            prng_state ^= (prng_state >> 17);
            prng_state ^= (prng_state << 5);
            return prng_state;
        endfunction

        function bit [127:0] next_block();
            return {next_word(), next_word(), next_word(), next_word()};
        endfunction

        // Produce the requested number of nonzero plaintext/key transactions.
        task body();
            uvm_e2e_item tr;
            void'($value$plusargs("NUM_TXNS=%0d", num_transactions));
            void'($value$plusargs("E2E_SEED=%0d", prng_state));
            if (prng_state == 32'h0) begin
                prng_state = 32'h1ace_5eed;
            end
            repeat (num_transactions) begin
                tr = uvm_e2e_item::type_id::create("tr");
                start_item(tr);
                tr.plaintext = next_block();
                tr.key       = next_block();
                tr.nonce     = {next_word(), next_word()};
                tr.counter   = {next_word(), next_word()};
                if (tr.plaintext == 128'h0) begin
                    tr.plaintext = 128'h4845_414c_5448_5f48_5237_385f_5339_3721;
                end
                if (tr.key == 128'h0) begin
                    tr.key = 128'h0001_0203_0405_0607_0809_0a0b_0c0d_0e0f;
                end
                finish_item(tr);
            end
        endtask
    endclass

    // Standard UVM sequencer connecting the sequence to the MMIO driver.
    class uvm_e2e_sequencer extends uvm_sequencer #(uvm_e2e_item);
        `uvm_component_utils(uvm_e2e_sequencer)
        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction
    endclass

    // Executes each transaction on the AES and UART RTL and publishes expected
    // UART text plus transaction data for scoreboard and coverage analysis.
    class uvm_e2e_driver extends uvm_driver #(uvm_e2e_item);
        `uvm_component_utils(uvm_e2e_driver)

        virtual uvm_e2e_if vif;
        uvm_analysis_port #(uvm_uart_line) expected_ap;
        uvm_analysis_port #(uvm_e2e_item) coverage_ap;

        function new(string name, uvm_component parent);
            super.new(name, parent);
            expected_ap = new("expected_ap", this);
            coverage_ap = new("coverage_ap", this);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db#(virtual uvm_e2e_if)::get(this, "", "vif", vif)) begin
                `uvm_fatal("NOVIF", "uvm_e2e_if was not set")
            end
        endfunction

        function string hex128(bit [127:0] value);
            return $sformatf("%032h", value);
        endfunction

        // Program all four key/plaintext words, nonce, counter, and CTR start.
        task aes_write_block(uvm_e2e_item tr);
            vif.sensor_plaintext = tr.plaintext;

            vif.aes_write(8'h08, tr.key[31:0]);
            vif.aes_write(8'h0C, tr.key[63:32]);
            vif.aes_write(8'h10, tr.key[95:64]);
            vif.aes_write(8'h14, tr.key[127:96]);

            vif.aes_write(8'h18, vif.sensor_plaintext[31:0]);
            vif.aes_write(8'h1C, vif.sensor_plaintext[63:32]);
            vif.aes_write(8'h20, vif.sensor_plaintext[95:64]);
            vif.aes_write(8'h24, vif.sensor_plaintext[127:96]);

            vif.aes_write(8'h38, tr.nonce[31:0]);
            vif.aes_write(8'h3C, tr.nonce[63:32]);
            vif.aes_write(8'h40, tr.counter[31:0]);
            vif.aes_write(8'h44, tr.counter[63:32]);
            vif.aes_write(8'h00, 32'h0000_0005); // start + CTR mode
        endtask

        // Poll AES status with a timeout, then assemble four CT registers.
        task aes_wait_and_read(output bit [127:0] ciphertext);
            int timeout;
            logic [31:0] status;
            logic [31:0] ct0, ct1, ct2, ct3;
            timeout = 0;
            do begin
                vif.aes_read(8'h04, status);
                timeout++;
            end while ((status[1] !== 1'b1) && (timeout < 500));

            if (status[1] !== 1'b1) begin
                `uvm_error("AES_TIMEOUT", "RTL AES-CTR did not assert done")
            end

            vif.aes_read(8'h28, ct0);
            vif.aes_read(8'h2C, ct1);
            vif.aes_read(8'h30, ct2);
            vif.aes_read(8'h34, ct3);
            ciphertext = {ct3, ct2, ct1, ct0};
        endtask

        // Send one byte only when UART is idle, wait for completion, clear the
        // sticky done flag, and re-enable the transmitter for the next byte.
        task uart_send_byte(byte unsigned value);
            wait (vif.uart_busy == 1'b0);
            vif.uart_write(6'h00, {24'h0, value});
            wait (vif.uart_done == 1'b1);
            vif.uart_write(6'h08, 32'h2); // clear done, keep enable at 0 for one write
            vif.uart_write(6'h08, 32'h1); // re-enable
        endtask

        task uart_send_string(string line);
            for (int i = 0; i < line.len(); i++) begin
                uart_send_byte(line[i]);
            end
        endtask

        // Main end-to-end operation for every item supplied by the sequencer.
        task run_phase(uvm_phase phase);
            uvm_e2e_item tr;
            uvm_uart_line exp;
            int unsigned ct3, ct2, ct1, ct0;
            int unsigned dec3, dec2, dec1, dec0;
            int unsigned transaction_index;

            vif.apply_reset();
            vif.uart_write(6'h0C, 32'h1); // fast simulation baud divisor
            vif.uart_write(6'h08, 32'h1); // enable UART
            transaction_index = 0;

            forever begin
                seq_item_port.get_next_item(tr);
                transaction_index++;
                vif.transaction_index = transaction_index;

                // First compute expected ciphertext and recovered plaintext
                // using the independently compiled C-DPI model.
                aes128_ctr_ref(
                    tr.key[127:96], tr.key[95:64], tr.key[63:32], tr.key[31:0],
                    tr.plaintext[127:96], tr.plaintext[95:64], tr.plaintext[63:32], tr.plaintext[31:0],
                    tr.nonce[63:32], tr.nonce[31:0], tr.counter[63:32], tr.counter[31:0],
                    ct3, ct2, ct1, ct0, dec3, dec2, dec1, dec0
                );

                tr.ref_ciphertext = {ct3, ct2, ct1, ct0};
                tr.ref_decrypted  = {dec3, dec2, dec1, dec0};
                vif.reference_ciphertext = tr.ref_ciphertext;
                vif.reference_decrypted = tr.ref_decrypted;

                // Then run the same values through the synthesizable RTL.
                aes_write_block(tr);
                aes_wait_and_read(tr.rtl_ciphertext);
                vif.rtl_ciphertext = tr.rtl_ciphertext;
                vif.rtl_ciphertext_match = (tr.rtl_ciphertext === tr.ref_ciphertext);
                vif.decrypted_plaintext_match = (tr.ref_decrypted === tr.plaintext);

                if (tr.rtl_ciphertext !== tr.ref_ciphertext) begin
                    `uvm_error("AES_MISMATCH",
                        $sformatf("RTL ciphertext %032h != C reference %032h",
                                  tr.rtl_ciphertext, tr.ref_ciphertext))
                end

                if (tr.ref_decrypted !== tr.plaintext) begin
                    `uvm_error("DEC_MISMATCH",
                        $sformatf("C reference decrypted %032h != plaintext %032h",
                                  tr.ref_decrypted, tr.plaintext))
                end
                // Sample inputs, crosses, and cryptographic match outcomes.
                coverage_ap.write(tr);

                // The expected text is queued before the same text is sent
                // byte-by-byte through the physical UART TX waveform.
                tr.expected_uart_line = {
                    "INPUT=", hex128(tr.plaintext),
                    " KEY=", hex128(tr.key),
                    " CIPHER=", hex128(tr.rtl_ciphertext),
                    " DECRYPTED=", hex128(tr.ref_decrypted),
                    " MATCH=", (tr.ref_decrypted == tr.plaintext) ? "PASS" : "FAIL",
                    "\n"
                };

                exp = uvm_uart_line::type_id::create("exp");
                exp.line = tr.expected_uart_line;
                expected_ap.write(exp);
                uart_send_string(tr.expected_uart_line);

                seq_item_port.item_done();
            end
        endtask
    endclass

    // Functional coverage collector. A portable bit-mask implementation always
    // runs; native covergroups can additionally run when the license supports
    // the NATIVE_COVERGROUPS compilation define.
    class uvm_e2e_coverage extends uvm_component;
        `uvm_component_utils(uvm_e2e_coverage)

        virtual uvm_e2e_if vif;
        uvm_analysis_imp #(uvm_e2e_item, uvm_e2e_coverage) analysis_export;
        int unsigned sampled_count;
        bit [3:0] plaintext_quadrant_bins;
        bit [3:0] key_quadrant_bins;
        bit [3:0] nonce_quadrant_bins;
        bit [3:0] counter_quadrant_bins;
        bit [15:0] plaintext_lsn_bins;
        bit [15:0] key_lsn_bins;
        bit [15:0] nonce_lsn_bins;
        bit [15:0] counter_lsn_bins;
        bit [15:0] plaintext_key_cross_bins;
        bit [15:0] nonce_counter_cross_bins;
        bit rtl_match_bin;
        bit decrypt_match_bin;

`ifdef NATIVE_COVERGROUPS
        covergroup transaction_cg with function sample(
            bit [127:0] plaintext,
            bit [127:0] key,
            bit [63:0] nonce,
            bit [63:0] counter,
            bit rtl_match,
            bit decrypt_match
        );
            option.per_instance = 1;
            option.name = "aes_ctr_random_transaction_coverage";

            cp_plaintext_quadrant: coverpoint plaintext[7:6] {
                bins quadrant[] = {[0:3]};
            }
            cp_key_quadrant: coverpoint key[7:6] {
                bins quadrant[] = {[0:3]};
            }
            cp_nonce_quadrant: coverpoint nonce[1:0] {
                bins quadrant[] = {[0:3]};
            }
            cp_counter_quadrant: coverpoint counter[1:0] {
                bins quadrant[] = {[0:3]};
            }
            cp_plaintext_lsn: coverpoint plaintext[3:0] {
                bins nibble[] = {[0:15]};
            }
            cp_key_lsn: coverpoint key[3:0] {
                bins nibble[] = {[0:15]};
            }
            cp_nonce_lsn: coverpoint nonce[3:0] {
                bins nibble[] = {[0:15]};
            }
            cp_counter_lsn: coverpoint counter[3:0] {
                bins nibble[] = {[0:15]};
            }
            cp_rtl_match: coverpoint rtl_match {
                bins pass = {1'b1};
                illegal_bins fail = {1'b0};
            }
            cp_decrypt_match: coverpoint decrypt_match {
                bins pass = {1'b1};
                illegal_bins fail = {1'b0};
            }

            plaintext_key_cross: cross cp_plaintext_quadrant, cp_key_quadrant;
            nonce_counter_cross: cross cp_nonce_quadrant, cp_counter_quadrant;
        endgroup
`endif

        function new(string name, uvm_component parent);
            super.new(name, parent);
            analysis_export = new("analysis_export", this);
`ifdef NATIVE_COVERGROUPS
            transaction_cg = new();
`endif
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db#(virtual uvm_e2e_if)::get(this, "", "vif", vif)) begin
                `uvm_fatal("NOVIF", "uvm_e2e_if was not set for coverage")
            end
        endfunction

        // Mark input-value bins, cross bins, and pass-result bins for this item.
        function void write(uvm_e2e_item tr);
            bit rtl_match;
            bit decrypt_match;
            rtl_match = (tr.rtl_ciphertext === tr.ref_ciphertext);
            decrypt_match = (tr.ref_decrypted === tr.plaintext);
            plaintext_quadrant_bins[tr.plaintext[7:6]] = 1'b1;
            key_quadrant_bins[tr.key[7:6]] = 1'b1;
            nonce_quadrant_bins[tr.nonce[1:0]] = 1'b1;
            counter_quadrant_bins[tr.counter[1:0]] = 1'b1;
            plaintext_lsn_bins[tr.plaintext[3:0]] = 1'b1;
            key_lsn_bins[tr.key[3:0]] = 1'b1;
            nonce_lsn_bins[tr.nonce[3:0]] = 1'b1;
            counter_lsn_bins[tr.counter[3:0]] = 1'b1;
            plaintext_key_cross_bins[{tr.plaintext[7:6], tr.key[7:6]}] = 1'b1;
            nonce_counter_cross_bins[{tr.nonce[1:0], tr.counter[1:0]}] = 1'b1;
            rtl_match_bin |= rtl_match;
            decrypt_match_bin |= decrypt_match;
`ifdef NATIVE_COVERGROUPS
            transaction_cg.sample(
                tr.plaintext,
                tr.key,
                tr.nonce,
                tr.counter,
                rtl_match,
                decrypt_match
            );
`endif
            sampled_count++;
            vif.coverage_bins = covered_bins();
            vif.coverage_percent_x100 = (10000 * covered_bins()) / 114;
        endfunction

        function int unsigned count_bins(bit [15:0] bin_mask);
            int unsigned count;
            count = 0;
            for (int i = 0; i < 16; i++) begin
                count += bin_mask[i];
            end
            return count;
        endfunction

        // Total planned portable coverage model: 114 individually tracked bins.
        function int unsigned covered_bins();
            return count_bins({12'h0, plaintext_quadrant_bins}) +
                   count_bins({12'h0, key_quadrant_bins}) +
                   count_bins({12'h0, nonce_quadrant_bins}) +
                   count_bins({12'h0, counter_quadrant_bins}) +
                   count_bins(plaintext_lsn_bins) +
                   count_bins(key_lsn_bins) +
                   count_bins(nonce_lsn_bins) +
                   count_bins(counter_lsn_bins) +
                   count_bins(plaintext_key_cross_bins) +
                   count_bins(nonce_counter_cross_bins) +
                   rtl_match_bin + decrypt_match_bin;
        endfunction

        function void report_phase(uvm_phase phase);
            real portable_coverage;
            portable_coverage = (100.0 * covered_bins()) / 114.0;
            `uvm_info("FUNC_COV",
                $sformatf("Portable AES-CTR functional coverage: %0.2f%% (%0d/114 bins) from %0d randomized transactions",
                          portable_coverage, covered_bins(), sampled_count),
                UVM_NONE)
`ifdef NATIVE_COVERGROUPS
            `uvm_info("FUNC_COV",
                $sformatf("Native SystemVerilog covergroup coverage: %0.2f%%",
                          transaction_cg.get_inst_coverage()),
                UVM_NONE)
`endif
        endfunction
    endclass

    // Passive serial monitor that samples the real UART TX pin and reconstructs
    // complete newline-terminated strings without reading internal UART data.
    class uvm_uart_monitor extends uvm_component;
        `uvm_component_utils(uvm_uart_monitor)
        virtual uvm_e2e_if vif;
        uvm_analysis_port #(uvm_uart_line) observed_ap;
        int bit_cycles = 2;

        function new(string name, uvm_component parent);
            super.new(name, parent);
            observed_ap = new("observed_ap", this);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db#(virtual uvm_e2e_if)::get(this, "", "vif", vif)) begin
                `uvm_fatal("NOVIF", "uvm_e2e_if was not set")
            end
        endfunction

        task run_phase(uvm_phase phase);
            byte unsigned ch;
            string line = "";
            uvm_uart_line obs;

            forever begin
                // A falling edge marks the UART start bit. Move to the center
                // of data bit zero, then sample eight LSB-first data bits.
                @(negedge vif.uart_tx);
                ch = 8'h00;
                repeat (bit_cycles + (bit_cycles / 2)) @(posedge vif.clk);
                for (int i = 0; i < 8; i++) begin
                    ch[i] = vif.uart_tx;
                    repeat (bit_cycles) @(posedge vif.clk);
                end

                line = {line, string'(ch)};
                if (ch == 8'h0A) begin
                    obs = uvm_uart_line::type_id::create("obs");
                    obs.line = line;
                    observed_ap.write(obs);
                    line = "";
                end
            end
        endtask
    endclass

    // End-to-end scoreboard: expected strings come from the driver and observed
    // strings come only from UART pin reconstruction.
    class uvm_e2e_scoreboard extends uvm_component;
        `uvm_component_utils(uvm_e2e_scoreboard)

        virtual uvm_e2e_if vif;
        uvm_analysis_imp_expected #(uvm_uart_line, uvm_e2e_scoreboard) expected_export;
        uvm_analysis_imp_observed #(uvm_uart_line, uvm_e2e_scoreboard) observed_export;
        string expected_q[$];
        int matched_count;
        int mismatched_count;
        bit uart_match_bin;

`ifdef NATIVE_COVERGROUPS
        covergroup uart_result_cg with function sample(bit matched);
            option.per_instance = 1;
            option.name = "uart_end_to_end_result_coverage";
            cp_uart_match: coverpoint matched {
                bins pass = {1'b1};
                illegal_bins fail = {1'b0};
            }
        endgroup
`endif

        function new(string name, uvm_component parent);
            super.new(name, parent);
            expected_export = new("expected_export", this);
            observed_export = new("observed_export", this);
`ifdef NATIVE_COVERGROUPS
            uart_result_cg = new();
`endif
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db#(virtual uvm_e2e_if)::get(this, "", "vif", vif)) begin
                `uvm_fatal("NOVIF", "uvm_e2e_if was not set for scoreboard")
            end
        endfunction

        // Queue expected lines in transaction order.
        function void write_expected(uvm_uart_line t);
            expected_q.push_back(t.line);
        endfunction

        // Compare each observed UART line with the oldest expected line.
        function void write_observed(uvm_uart_line t);
            string exp;
            if (expected_q.size() == 0) begin
                `uvm_error("UNEXPECTED_UART", $sformatf("Observed unexpected UART line: %s", t.line))
                return;
            end
            exp = expected_q.pop_front();
            if (t.line != exp) begin
                mismatched_count++;
                vif.uart_mismatches = mismatched_count;
`ifdef NATIVE_COVERGROUPS
                uart_result_cg.sample(1'b0);
`endif
                `uvm_error("UART_MISMATCH", $sformatf("Observed '%s' expected '%s'", t.line, exp))
            end else begin
                matched_count++;
                vif.uart_matches = matched_count;
                uart_match_bin = 1'b1;
`ifdef NATIVE_COVERGROUPS
                uart_result_cg.sample(1'b1);
`endif
                `uvm_info("UART_MATCH", $sformatf("Matched UART line %0d: %s", matched_count, t.line), UVM_LOW)
            end
        endfunction

        function void check_phase(uvm_phase phase);
            if (expected_q.size() != 0) begin
                `uvm_error("MISSING_UART", $sformatf("%0d expected UART lines were not observed", expected_q.size()))
            end
            if (matched_count == 0) begin
                `uvm_error("NO_COVERAGE", "No UART lines were matched")
            end
        endfunction

        function void report_phase(uvm_phase phase);
            `uvm_info("FUNC_COV",
                $sformatf("Portable UART end-to-end result coverage: %0.2f%%, matches=%0d mismatches=%0d",
                          uart_match_bin ? 100.0 : 0.0, matched_count, mismatched_count),
                UVM_NONE)
`ifdef NATIVE_COVERGROUPS
            `uvm_info("FUNC_COV",
                $sformatf("Native UART result covergroup coverage: %0.2f%%",
                          uart_result_cg.get_inst_coverage()),
                UVM_NONE)
`endif
        endfunction
    endclass

    // Environment containing all active and passive verification components.
    class uvm_e2e_env extends uvm_env;
        `uvm_component_utils(uvm_e2e_env)
        uvm_e2e_sequencer seqr;
        uvm_e2e_driver    driver;
        uvm_uart_monitor  monitor;
        uvm_e2e_scoreboard scoreboard;
        uvm_e2e_coverage coverage;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            seqr = uvm_e2e_sequencer::type_id::create("seqr", this);
            driver = uvm_e2e_driver::type_id::create("driver", this);
            monitor = uvm_uart_monitor::type_id::create("monitor", this);
            scoreboard = uvm_e2e_scoreboard::type_id::create("scoreboard", this);
            coverage = uvm_e2e_coverage::type_id::create("coverage", this);
        endfunction

        // Transaction flow connections:
        // sequence -> driver; driver -> expected scoreboard/coverage;
        // UART monitor -> observed scoreboard.
        function void connect_phase(uvm_phase phase);
            driver.seq_item_port.connect(seqr.seq_item_export);
            driver.expected_ap.connect(scoreboard.expected_export);
            driver.coverage_ap.connect(coverage.analysis_export);
            monitor.observed_ap.connect(scoreboard.observed_export);
        endfunction
    endclass

    // Top-level UVM test that starts the randomized sequence and keeps the
    // objection raised long enough for the final UART line to complete.
    class uvm_e2e_test extends uvm_test;
        `uvm_component_utils(uvm_e2e_test)
        uvm_e2e_env env;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            env = uvm_e2e_env::type_id::create("env", this);
        endfunction

        task run_phase(uvm_phase phase);
            uvm_e2e_sequence seq;
            phase.raise_objection(this);
            seq = uvm_e2e_sequence::type_id::create("seq");
            seq.start(env.seqr);
            repeat (200) @(env.driver.vif.clk);
            phase.drop_objection(this);
        endtask
    endclass
endpackage

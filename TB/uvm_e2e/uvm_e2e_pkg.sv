package uvm_e2e_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import "DPI-C" function void aes128_ctr_ref(
        input int unsigned key3, input int unsigned key2, input int unsigned key1, input int unsigned key0,
        input int unsigned pt3, input int unsigned pt2, input int unsigned pt1, input int unsigned pt0,
        input int unsigned nonce1, input int unsigned nonce0, input int unsigned counter1, input int unsigned counter0,
        output int unsigned ct3, output int unsigned ct2, output int unsigned ct1, output int unsigned ct0,
        output int unsigned dec3, output int unsigned dec2, output int unsigned dec1, output int unsigned dec0
    );

    `uvm_analysis_imp_decl(_expected)
    `uvm_analysis_imp_decl(_observed)

    class uvm_e2e_item extends uvm_sequence_item;
        rand bit [127:0] plaintext;
        rand bit [127:0] key;
        rand bit [63:0]  nonce;
        rand bit [63:0]  counter;

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

    class uvm_uart_line extends uvm_sequence_item;
        string line;
        `uvm_object_utils_begin(uvm_uart_line)
            `uvm_field_string(line, UVM_ALL_ON)
        `uvm_object_utils_end
        function new(string name = "uvm_uart_line");
            super.new(name);
        endfunction
    endclass

    class uvm_e2e_sequence extends uvm_sequence #(uvm_e2e_item);
        `uvm_object_utils(uvm_e2e_sequence)
        int unsigned num_transactions = 25;
        int unsigned prng_state = 32'h1ace_5eed;

        function new(string name = "uvm_e2e_sequence");
            super.new(name);
        endfunction

        function int unsigned next_word();
            prng_state ^= (prng_state << 13);
            prng_state ^= (prng_state >> 17);
            prng_state ^= (prng_state << 5);
            return prng_state;
        endfunction

        function bit [127:0] next_block();
            return {next_word(), next_word(), next_word(), next_word()};
        endfunction

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

    class uvm_e2e_sequencer extends uvm_sequencer #(uvm_e2e_item);
        `uvm_component_utils(uvm_e2e_sequencer)
        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction
    endclass

    class uvm_e2e_driver extends uvm_driver #(uvm_e2e_item);
        `uvm_component_utils(uvm_e2e_driver)

        virtual uvm_e2e_if vif;
        uvm_analysis_port #(uvm_uart_line) expected_ap;

        function new(string name, uvm_component parent);
            super.new(name, parent);
            expected_ap = new("expected_ap", this);
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

        task aes_wait_and_read(output bit [127:0] ciphertext);
            int timeout;
            logic [31:0] status;
            logic [31:0] ct0, ct1, ct2, ct3;
            timeout = 0;
            do begin
                vif.aes_read(8'h04, status);
                timeout++;
            end while ((status[1] !== 1'b1) && (timeout < 100));

            if (status[1] !== 1'b1) begin
                `uvm_error("AES_TIMEOUT", "RTL AES-CTR did not assert done")
            end

            vif.aes_read(8'h28, ct0);
            vif.aes_read(8'h2C, ct1);
            vif.aes_read(8'h30, ct2);
            vif.aes_read(8'h34, ct3);
            ciphertext = {ct3, ct2, ct1, ct0};
        endtask

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

        task run_phase(uvm_phase phase);
            uvm_e2e_item tr;
            uvm_uart_line exp;
            int unsigned ct3, ct2, ct1, ct0;
            int unsigned dec3, dec2, dec1, dec0;

            vif.apply_reset();
            vif.uart_write(6'h0C, 32'h1); // fast simulation baud divisor
            vif.uart_write(6'h08, 32'h1); // enable UART

            forever begin
                seq_item_port.get_next_item(tr);

                aes128_ctr_ref(
                    tr.key[127:96], tr.key[95:64], tr.key[63:32], tr.key[31:0],
                    tr.plaintext[127:96], tr.plaintext[95:64], tr.plaintext[63:32], tr.plaintext[31:0],
                    tr.nonce[63:32], tr.nonce[31:0], tr.counter[63:32], tr.counter[31:0],
                    ct3, ct2, ct1, ct0, dec3, dec2, dec1, dec0
                );

                tr.ref_ciphertext = {ct3, ct2, ct1, ct0};
                tr.ref_decrypted  = {dec3, dec2, dec1, dec0};

                aes_write_block(tr);
                aes_wait_and_read(tr.rtl_ciphertext);

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

    class uvm_e2e_scoreboard extends uvm_component;
        `uvm_component_utils(uvm_e2e_scoreboard)

        uvm_analysis_imp_expected #(uvm_uart_line, uvm_e2e_scoreboard) expected_export;
        uvm_analysis_imp_observed #(uvm_uart_line, uvm_e2e_scoreboard) observed_export;
        string expected_q[$];
        int matched_count;

        function new(string name, uvm_component parent);
            super.new(name, parent);
            expected_export = new("expected_export", this);
            observed_export = new("observed_export", this);
        endfunction

        function void write_expected(uvm_uart_line t);
            expected_q.push_back(t.line);
        endfunction

        function void write_observed(uvm_uart_line t);
            string exp;
            if (expected_q.size() == 0) begin
                `uvm_error("UNEXPECTED_UART", $sformatf("Observed unexpected UART line: %s", t.line))
                return;
            end
            exp = expected_q.pop_front();
            if (t.line != exp) begin
                `uvm_error("UART_MISMATCH", $sformatf("Observed '%s' expected '%s'", t.line, exp))
            end else begin
                matched_count++;
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
    endclass

    class uvm_e2e_env extends uvm_env;
        `uvm_component_utils(uvm_e2e_env)
        uvm_e2e_sequencer seqr;
        uvm_e2e_driver    driver;
        uvm_uart_monitor  monitor;
        uvm_e2e_scoreboard scoreboard;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            seqr = uvm_e2e_sequencer::type_id::create("seqr", this);
            driver = uvm_e2e_driver::type_id::create("driver", this);
            monitor = uvm_uart_monitor::type_id::create("monitor", this);
            scoreboard = uvm_e2e_scoreboard::type_id::create("scoreboard", this);
        endfunction

        function void connect_phase(uvm_phase phase);
            driver.seq_item_port.connect(seqr.seq_item_export);
            driver.expected_ap.connect(scoreboard.expected_export);
            monitor.observed_ap.connect(scoreboard.observed_export);
        endfunction
    endclass

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

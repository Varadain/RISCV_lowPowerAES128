`ifndef AES_SCOREBOARD_SV
`define AES_SCOREBOARD_SV

class aes_scoreboard extends uvm_component;
    `uvm_component_utils(aes_scoreboard)

    uvm_analysis_imp_exp #(aes_transaction, aes_scoreboard) expected_export;
    uvm_analysis_imp_obs #(aes_transaction, aes_scoreboard) observed_export;

    aes_transaction exp_q[$];
    int unsigned total_count;
    int unsigned pass_count;
    int unsigned fail_count;
    int unsigned latency_sum;
    int unsigned min_latency;
    int unsigned max_latency;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        expected_export = new("expected_export", this);
        observed_export = new("observed_export", this);
        min_latency = 32'hffff_ffff;
    endfunction

    function void write_exp(aes_transaction tr);
        aes_transaction c;
        $cast(c, tr.clone());
        exp_q.push_back(c);
    endfunction

    function void write_obs(aes_transaction obs);
        aes_transaction exp;
        if (exp_q.size() == 0) begin
            fail_count++;
            `uvm_error("AES_SCB", "Observed ciphertext without expected transaction")
            return;
        end
        exp = exp_q.pop_front();
        total_count++;
        latency_sum += obs.latency_cycles;
        if (obs.latency_cycles < min_latency) min_latency = obs.latency_cycles;
        if (obs.latency_cycles > max_latency) max_latency = obs.latency_cycles;

        if (obs.observed_ciphertext === exp.expected_ciphertext) begin
            pass_count++;
            `uvm_info("AES_PASS", $sformatf("%s CT=%032h latency=%0d cycles PASS",
                exp.test_name, obs.observed_ciphertext, obs.latency_cycles), UVM_LOW)
        end else begin
            fail_count++;
            `uvm_error("AES_FAIL", $sformatf("%s CT=%032h EXP=%032h FAIL",
                exp.test_name, obs.observed_ciphertext, exp.expected_ciphertext))
        end
    endfunction

    function real avg_latency();
        if (total_count == 0) return 0.0;
        return real'(latency_sum) / real'(total_count);
    endfunction

    function void check_phase(uvm_phase phase);
        if (exp_q.size() != 0) begin
            fail_count += exp_q.size();
            `uvm_error("AES_SCB", $sformatf("%0d expected transactions were not observed", exp_q.size()))
        end
    endfunction
endclass

`endif

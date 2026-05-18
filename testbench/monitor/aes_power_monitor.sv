`ifndef AES_POWER_MONITOR_SV
`define AES_POWER_MONITOR_SV

class aes_power_monitor extends uvm_component;
    `uvm_component_utils(aes_power_monitor)
    virtual aes_interface vif;
    aes_scoreboard scb;
    aes_coverage   cov;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual aes_interface)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", "aes_power_monitor missing virtual interface")
        end
    endfunction

    function real clock_gating_efficiency();
        int unsigned total;
        total = vif.active_cycles + vif.idle_cycles;
        if (total == 0) return 0.0;
        return real'(vif.idle_cycles) * 100.0 / real'(total);
    endfunction

    function real utilization();
        int unsigned total;
        total = vif.active_cycles + vif.idle_cycles;
        if (total == 0) return 0.0;
        return real'(vif.active_cycles) * 100.0 / real'(total);
    endfunction

    function real estimated_power_saving();
        return clock_gating_efficiency() * 0.70;
    endfunction

    function real throughput_gbps();
        real lat;
        lat = (scb == null) ? 0.0 : scb.avg_latency();
        if (lat <= 0.0) return 0.0;
        return 12.8 / lat;
    endfunction

    function string grade(real value);
        if (value >= 95.0) return "A+";
        if (value >= 85.0) return "A";
        if (value >= 70.0) return "B";
        return "REVIEW";
    endfunction

    function void report_phase(uvm_phase phase);
        real cov_pct;
        real avg_lat;
        cov_pct = (cov == null) ? 0.0 : cov.get_percent();
        avg_lat = (scb == null) ? 0.0 : scb.avg_latency();

        $display("");
        $display("=========================================================");
        $display("AES LOW POWER VERIFICATION DASHBOARD");
        $display("=========================================================");
        $display("| METRIC                     | VALUE                    |");
        $display("---------------------------------------------------------");
        $display("| Simulation Time            | %-24t |", $time);
        $display("| Test Name                  | %-24s |", uvm_top.get_full_name());
        $display("| AES Mode                   | %-24s |", "AES-128 ECB ENC");
        $display("| AES Clock Frequency        | %-24s |", "100 MHz");
        $display("| Total Transactions         | %-24d |", scb.total_count);
        $display("| Passed Transactions        | %-24d |", scb.pass_count);
        $display("| Failed Transactions        | %-24d |", scb.fail_count);
        $display("| Coverage Percentage        | %0.2f%%                   |", cov_pct);
        $display("| Clock Gating Efficiency    | %0.2f%%                   |", clock_gating_efficiency());
        $display("| Estimated Power Reduction  | %0.2f%%                   |", estimated_power_saving());
        $display("| Toggle Count State         | %-24d |", vif.state_toggles);
        $display("| Toggle Count Round Key     | %-24d |", vif.round_key_toggles);
        $display("| Avg Encryption Latency     | %0.2f cycles              |", avg_lat);
        $display("| Throughput                 | %0.3f Gbps                |", throughput_gbps());
        $display("| Effective Frequency        | %-24s |", "100 MHz");
        $display("| Idle Cycles                | %-24d |", vif.idle_cycles);
        $display("| Active Cycles              | %-24d |", vif.active_cycles);
        $display("| Scan Mode Cycles           | %-24d |", vif.scan_cycles);
        $display("| DFT Status                 | %-24s |", (vif.scan_cycles > 0) ? "EXERCISED" : "NOT_RUN");
        $display("| Assertion Failures         | %-24d |", vif.assertion_fail_count);
        $display("| Glitch Events              | %-24d |", vif.glitch_count);
        $display("| Double Pulse Events        | %-24d |", vif.double_pulse_count);
        $display("| Missing Pulse Events       | %-24d |", vif.missing_pulse_count);
        $display("| FSM Integrity Status       | %-24s |", (vif.assertion_fail_count == 0) ? "PASS" : "FAIL");
        $display("| Ciphertext Integrity       | %-24s |", (scb.fail_count == 0) ? "PASS" : "FAIL");
        $display("| Performance Grade          | %-24s |", grade(100.0 - avg_lat));
        $display("| Power Grade                | %-24s |", grade(estimated_power_saving() + 70.0));
        $display("| Verification Grade         | %-24s |", grade(cov_pct));
        $display("=========================================================");
        $display("");
    endfunction
endclass

`endif

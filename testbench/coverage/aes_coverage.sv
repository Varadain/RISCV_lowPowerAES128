`ifndef AES_COVERAGE_SV
`define AES_COVERAGE_SV

class aes_coverage extends uvm_component;
    `uvm_component_utils(aes_coverage)
    uvm_analysis_imp_cov #(aes_transaction, aes_coverage) cov_export;
    virtual aes_interface vif;

    bit scenario_hit[8];
    bit round_hit[11];
    bit scan_seen;
    bit reset_seen;
    bit idle_seen;
    bit wake_seen;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        cov_export = new("cov_export", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual aes_interface)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", "aes_coverage missing virtual interface")
        end
    endfunction

    function void write_cov(aes_transaction tr);
        scenario_hit[tr.scenario] = 1'b1;
    endfunction

    task run_phase(uvm_phase phase);
        forever begin
            @(posedge vif.clk);
            if (vif.round_dbg <= 10) round_hit[vif.round_dbg] = 1'b1;
            if (vif.test_mode && vif.scan_enable) scan_seen = 1'b1;
            if (vif.reset) reset_seen = 1'b1;
            if (!vif.clk_en) idle_seen = 1'b1;
            if (!vif.reset && vif.clk_en && vif.start) wake_seen = 1'b1;
        end
    endtask

    function real get_percent();
        int hit;
        int total;
        hit = 0;
        total = 8 + 11 + 4;
        for (int i = 0; i < 8; i++) if (scenario_hit[i]) hit++;
        for (int r = 0; r < 11; r++) if (round_hit[r]) hit++;
        if (scan_seen) hit++;
        if (reset_seen) hit++;
        if (idle_seen) hit++;
        if (wake_seen) hit++;
        return (real'(hit) * 100.0) / real'(total);
    endfunction
endclass

`endif

`ifndef AES_MONITOR_SV
`define AES_MONITOR_SV

class aes_monitor extends uvm_component;
    `uvm_component_utils(aes_monitor)

    virtual aes_interface vif;
    uvm_analysis_port #(aes_transaction) observed_ap;
    int unsigned start_cycle_q[$];

    function new(string name, uvm_component parent);
        super.new(name, parent);
        observed_ap = new("observed_ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual aes_interface)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", "aes_monitor missing virtual interface")
        end
    endfunction

    task run_phase(uvm_phase phase);
        bit prev_done;
        aes_transaction tr;
        forever begin
            @(vif.mon_cb);
            if (vif.mon_cb.reset) begin
                prev_done = 1'b0;
                start_cycle_q.delete();
            end else begin
                if (vif.mon_cb.start) begin
                    start_cycle_q.push_back(vif.cycle_count);
                end
                if (vif.mon_cb.done && !prev_done) begin
                    tr = aes_transaction::type_id::create("observed_tr");
                    tr.observed_ciphertext = vif.ciphertext_dbg;
                    if (start_cycle_q.size() > 0) begin
                        tr.latency_cycles = vif.cycle_count - start_cycle_q.pop_front();
                    end
                    observed_ap.write(tr);
                end
                prev_done = vif.mon_cb.done;
            end
        end
    endtask
endclass

`endif

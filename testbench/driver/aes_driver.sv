`ifndef AES_DRIVER_SV
`define AES_DRIVER_SV

class aes_driver extends uvm_driver #(aes_transaction);
    `uvm_component_utils(aes_driver)

    virtual aes_interface vif;
    uvm_analysis_port #(aes_transaction) expected_ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        expected_ap = new("expected_ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual aes_interface)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", "aes_driver missing virtual interface")
        end
    endfunction

    task run_phase(uvm_phase phase);
        aes_transaction tr;
        init_bus();
        apply_reset();
        forever begin
            seq_item_port.get_next_item(tr);
            expected_ap.write(tr);
            drive_transaction(tr);
            seq_item_port.item_done();
        end
    endtask

    task init_bus();
        vif.drv_cb.reset         <= 1'b1;
        vif.drv_cb.clk_en        <= 1'b0;
        vif.drv_cb.test_mode     <= 1'b0;
        vif.drv_cb.scan_enable   <= 1'b0;
        vif.drv_cb.scan_in       <= 1'b0;
        vif.drv_cb.load          <= 1'b0;
        vif.drv_cb.load_sel      <= 1'b0;
        vif.drv_cb.load_index    <= 4'd0;
        vif.drv_cb.data_in       <= 8'd0;
        vif.drv_cb.start         <= 1'b0;
        vif.drv_cb.data_out_index <= 4'd0;
    endtask

    task apply_reset();
        repeat (4) @(vif.drv_cb);
        vif.drv_cb.reset <= 1'b0;
        repeat (2) @(vif.drv_cb);
    endtask

    task load_block(bit load_sel, bit [127:0] value);
        vif.drv_cb.clk_en <= 1'b1;
        for (int i = 0; i < 16; i++) begin
            vif.drv_cb.load       <= 1'b1;
            vif.drv_cb.load_sel   <= load_sel;
            vif.drv_cb.load_index <= i[3:0];
            vif.drv_cb.data_in    <= value[127 - (i * 8) -: 8];
            @(vif.drv_cb);
        end
        vif.drv_cb.load <= 1'b0;
        @(vif.drv_cb);
    endtask

    task do_scan_shift(aes_transaction tr);
        vif.drv_cb.test_mode   <= 1'b1;
        vif.drv_cb.scan_enable <= 1'b1;
        vif.drv_cb.clk_en      <= 1'b0;
        for (int i = 0; i < tr.scan_shift_cycles; i++) begin
            vif.drv_cb.scan_in <= i[0];
            @(vif.drv_cb);
        end
        vif.drv_cb.scan_enable <= 1'b0;
        vif.drv_cb.test_mode   <= 1'b0;
        vif.drv_cb.scan_in     <= 1'b0;
        repeat (2) @(vif.drv_cb);
    endtask

    task start_and_wait(aes_transaction tr);
        bit saw_done;
        int unsigned cycles;
        vif.drv_cb.clk_en <= 1'b1;
        vif.drv_cb.start <= 1'b1;
        @(vif.drv_cb);
        vif.drv_cb.start <= 1'b0;

        if (tr.scenario == AES_SCENARIO_CLK_STALL ||
            tr.scenario == AES_SCENARIO_TRAFFIC_STRESS ||
            tr.scenario == AES_SCENARIO_GLITCH_STRESS) begin
            repeat (2) @(vif.drv_cb);
            vif.drv_cb.clk_en <= 1'b0;
            repeat (tr.stall_cycles) @(vif.drv_cb);
            vif.drv_cb.clk_en <= 1'b1;
        end

        if (tr.scenario == AES_SCENARIO_RESET_COLLISION) begin
            repeat (2) @(vif.drv_cb);
            vif.drv_cb.reset <= 1'b1;
            repeat (2) @(vif.drv_cb);
            vif.drv_cb.reset <= 1'b0;
            repeat (2) @(vif.drv_cb);
            vif.drv_cb.start <= 1'b1;
            @(vif.drv_cb);
            vif.drv_cb.start <= 1'b0;
        end

        saw_done = 1'b0;
        for (cycles = 0; cycles < 220; cycles++) begin
            @(vif.drv_cb);
            if (vif.drv_cb.done) begin
                saw_done = 1'b1;
                break;
            end
        end
        if (!saw_done) begin
            `uvm_error("AES_TIMEOUT", $sformatf("%s timed out waiting for done", tr.test_name))
        end
        @(vif.drv_cb);
    endtask

    task drive_transaction(aes_transaction tr);
        `uvm_info("AES_DRV", $sformatf("Driving %s scenario=%0d", tr.test_name, tr.scenario), UVM_MEDIUM)
        if (tr.scenario == AES_SCENARIO_IDLE_WAKEUP) begin
            vif.drv_cb.clk_en <= 1'b0;
            repeat (tr.idle_cycles) @(vif.drv_cb);
        end
        if (tr.scenario == AES_SCENARIO_SCAN_SHIFT) begin
            do_scan_shift(tr);
        end
        load_block(1'b0, tr.plaintext);
        load_block(1'b1, tr.key);
        start_and_wait(tr);
    endtask
endclass

`endif

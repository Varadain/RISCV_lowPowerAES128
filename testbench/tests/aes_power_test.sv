`ifndef AES_POWER_TEST_SV
`define AES_POWER_TEST_SV

class aes_power_test extends aes_base_test;
    `uvm_component_utils(aes_power_test)
    function new(string name, uvm_component parent); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        aes_clock_gate_sequence seq;
        phase.raise_objection(this);
        seq = aes_clock_gate_sequence::type_id::create("seq");
        seq.start(env.agent.sequencer);
        repeat (20) @(env.agent.driver.vif.drv_cb);
        phase.drop_objection(this);
    endtask
endclass

`endif

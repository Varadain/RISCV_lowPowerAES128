`ifndef AES_BASE_TEST_SV
`define AES_BASE_TEST_SV

class aes_base_test extends uvm_test;
    `uvm_component_utils(aes_base_test)
    aes_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = aes_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        aes_base_sequence seq;
        phase.raise_objection(this);
        seq = aes_base_sequence::type_id::create("seq");
        seq.start(env.agent.sequencer);
        repeat (20) @(env.agent.driver.vif.drv_cb);
        phase.drop_objection(this);
    endtask
endclass

`endif

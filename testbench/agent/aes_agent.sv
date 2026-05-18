`ifndef AES_AGENT_SV
`define AES_AGENT_SV

class aes_agent extends uvm_agent;
    `uvm_component_utils(aes_agent)
    aes_sequencer sequencer;
    aes_driver    driver;
    aes_monitor   monitor;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        sequencer = aes_sequencer::type_id::create("sequencer", this);
        driver    = aes_driver::type_id::create("driver", this);
        monitor   = aes_monitor::type_id::create("monitor", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction
endclass

`endif

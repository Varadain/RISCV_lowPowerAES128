`ifndef AES_ENV_SV
`define AES_ENV_SV

class aes_env extends uvm_env;
    `uvm_component_utils(aes_env)
    aes_agent         agent;
    aes_scoreboard    scoreboard;
    aes_coverage      coverage;
    aes_power_monitor power_monitor;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent         = aes_agent::type_id::create("agent", this);
        scoreboard    = aes_scoreboard::type_id::create("scoreboard", this);
        coverage      = aes_coverage::type_id::create("coverage", this);
        power_monitor = aes_power_monitor::type_id::create("power_monitor", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        agent.driver.expected_ap.connect(scoreboard.expected_export);
        agent.driver.expected_ap.connect(coverage.cov_export);
        agent.monitor.observed_ap.connect(scoreboard.observed_export);
        power_monitor.scb = scoreboard;
        power_monitor.cov = coverage;
    endfunction
endclass

`endif

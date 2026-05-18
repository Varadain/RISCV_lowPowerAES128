`ifndef AES_INTERFACE_SV
`define AES_INTERFACE_SV

interface aes_interface(input logic clk);
    logic       reset;
    logic       clk_en;
    logic       test_mode;
    logic       scan_enable;
    logic       scan_in;
    logic       scan_out;
    logic       load;
    logic       load_sel;
    logic [3:0] load_index;
    logic [7:0] data_in;
    logic       start;
    logic [3:0] data_out_index;
    logic [7:0] data_out;
    logic       done;

    logic         gated_clk_dbg;
    logic [127:0] plaintext_dbg;
    logic [127:0] key_dbg;
    logic [127:0] state_dbg;
    logic [127:0] round_key_dbg;
    logic [127:0] ciphertext_dbg;
    logic [3:0]   round_dbg;

    int unsigned cycle_count;
    int unsigned active_cycles;
    int unsigned idle_cycles;
    int unsigned scan_cycles;
    int unsigned gated_clk_edges;
    int unsigned state_toggles;
    int unsigned round_key_toggles;
    int unsigned ciphertext_toggles;
    int unsigned glitch_count;
    int unsigned double_pulse_count;
    int unsigned missing_pulse_count;
    int unsigned assertion_fail_count;

    logic [127:0] prev_state;
    logic [127:0] prev_round_key;
    logic [127:0] prev_ciphertext;
    time          last_gated_edge_time;
    time          prev_gated_edge_time;

    clocking drv_cb @(posedge clk);
        output reset, clk_en, test_mode, scan_enable, scan_in;
        output load, load_sel, load_index, data_in, start, data_out_index;
        input  data_out, done, scan_out;
    endclocking

    clocking mon_cb @(posedge clk);
        input reset, clk_en, test_mode, scan_enable, scan_in, scan_out;
        input load, load_sel, load_index, data_in, start, data_out_index;
        input data_out, done, gated_clk_dbg, round_dbg, ciphertext_dbg;
    endclocking

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            cycle_count        <= 0;
            active_cycles      <= 0;
            idle_cycles        <= 0;
            scan_cycles        <= 0;
            state_toggles      <= 0;
            round_key_toggles  <= 0;
            ciphertext_toggles <= 0;
            missing_pulse_count <= 0;
            prev_state         <= '0;
            prev_round_key     <= '0;
            prev_ciphertext    <= '0;
        end else begin
            cycle_count <= cycle_count + 1;
            if (test_mode && scan_enable) begin
                scan_cycles <= scan_cycles + 1;
            end
            if (clk_en || test_mode) begin
                active_cycles <= active_cycles + 1;
            end else begin
                idle_cycles <= idle_cycles + 1;
            end
            if (state_dbg !== prev_state) begin
                state_toggles <= state_toggles + 1;
            end
            if (round_key_dbg !== prev_round_key) begin
                round_key_toggles <= round_key_toggles + 1;
            end
            if (ciphertext_dbg !== prev_ciphertext) begin
                ciphertext_toggles <= ciphertext_toggles + 1;
            end
            if ((clk_en || test_mode) && (start || round_dbg != 4'd0) &&
                (gated_clk_dbg !== 1'b1) && (gated_clk_dbg !== 1'b0)) begin
                missing_pulse_count <= missing_pulse_count + 1;
            end
            prev_state      <= state_dbg;
            prev_round_key  <= round_key_dbg;
            prev_ciphertext <= ciphertext_dbg;
        end
    end

    always @(posedge gated_clk_dbg) begin
        gated_clk_edges <= gated_clk_edges + 1;
        prev_gated_edge_time <= last_gated_edge_time;
        last_gated_edge_time <= $time;
        if (prev_gated_edge_time != 0 && ($time - last_gated_edge_time) < 5ns) begin
            double_pulse_count <= double_pulse_count + 1;
        end
    end

    always @(gated_clk_dbg) begin
        if (!reset && $time > 0 && gated_clk_dbg !== 1'b0 && gated_clk_dbg !== 1'b1) begin
            glitch_count <= glitch_count + 1;
        end
    end
endinterface

`endif

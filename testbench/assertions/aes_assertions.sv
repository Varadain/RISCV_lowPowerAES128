`ifndef AES_ASSERTIONS_SV
`define AES_ASSERTIONS_SV

module aes_assertions(aes_interface vif);
    timeunit 1ns;
    timeprecision 1ps;
    property p_no_core_change_when_disabled;
        @(posedge vif.clk) disable iff (vif.reset !== 1'b0 || vif.test_mode)
            (!vif.clk_en && !vif.scan_enable) |=> $stable({vif.state_dbg, vif.round_key_dbg, vif.round_dbg, vif.ciphertext_dbg});
    endproperty

    property p_done_after_final_round;
        @(posedge vif.clk) disable iff (vif.reset !== 1'b0 || vif.test_mode)
            $rose(vif.done) |-> $past(vif.round_dbg) == 4'd10;
    endproperty

    property p_round_is_legal;
        @(posedge vif.clk) disable iff (vif.reset !== 1'b0)
            vif.round_dbg <= 4'd10;
    endproperty

    property p_no_xz_outputs;
        @(posedge vif.clk) disable iff (vif.reset !== 1'b0)
            !$isunknown({vif.done, vif.data_out, vif.scan_out, vif.gated_clk_dbg});
    endproperty

    property p_reset_recovers_idle;
        @(posedge vif.clk)
            $fell(vif.reset) |=> (vif.round_dbg == 4'd0 && vif.done == 1'b0);
    endproperty

    assert_no_core_change_when_disabled: assert property (p_no_core_change_when_disabled)
        else begin
            vif.assertion_fail_count++;
            $error("[AES_ASSERT][%0t] Core changed while clk_en=0 outside scan mode", $time);
        end

    always @(posedge vif.clk) begin
        #1ps;
        if (vif.reset === 1'b0 && vif.test_mode && vif.scan_enable &&
            vif.gated_clk_dbg !== 1'b1) begin
            vif.assertion_fail_count++;
            $error("[AES_ASSERT][%0t] Scan mode did not bypass clock gate", $time);
        end
    end

    assert_done_after_final_round: assert property (p_done_after_final_round)
        else begin
            vif.assertion_fail_count++;
            $error("[AES_ASSERT][%0t] done asserted without final AES round", $time);
        end

    assert_round_is_legal: assert property (p_round_is_legal)
        else begin
            vif.assertion_fail_count++;
            $error("[AES_ASSERT][%0t] Illegal AES round value %0d", $time, vif.round_dbg);
        end

    assert_no_xz_outputs: assert property (p_no_xz_outputs)
        else begin
            vif.assertion_fail_count++;
            $error("[AES_ASSERT][%0t] X/Z detected on visible AES outputs", $time);
        end

    assert_reset_recovers_idle: assert property (p_reset_recovers_idle)
        else begin
            vif.assertion_fail_count++;
            $error("[AES_ASSERT][%0t] Reset did not recover idle state", $time);
        end
endmodule

`endif

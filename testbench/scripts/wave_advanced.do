set project_dir "D:/mtech/sem 4/midesm presetation/AES128_lowPower"
set tb_dir "$project_dir/uvm_tb"

transcript file [file join $tb_dir "logs/aes_advanced_wave.log"]
transcript on

if {[file exists work]} {
    vdel -lib work -all
}
vlib work
vmap work work

vlog -sv -work work "$project_dir/aes_sbox.sv"
vlog -sv -work work "$project_dir/sub_bytes.sv"
vlog -sv -work work "$project_dir/shift_rows.sv"
vlog -sv -work work "$project_dir/mix_col.sv"
vlog -sv -work work "$project_dir/mix_columns.sv"
vlog -sv -work work "$project_dir/key_expand.sv"
vlog -sv -work work "$project_dir/AES128_lowPower.sv"
vlog -sv -work work +incdir+$tb_dir "$tb_dir/interfaces/aes_interface.sv"
vlog -sv -work work +incdir+$tb_dir "$tb_dir/assertions/aes_assertions.sv"
vlog -sv -work work +incdir+$tb_dir "$tb_dir/aes_uvm_pkg.sv"
vlog -sv -work work +incdir+$tb_dir "$tb_dir/aes_tb_top.sv"

vsim -t 1ps -suppress 12110 -novopt work.aes_tb_top +UVM_TESTNAME=aes_stress_test

add wave -divider "DFT and Clock Gating"
add wave sim:/aes_tb_top/clk
add wave sim:/aes_tb_top/aes_if/reset
add wave sim:/aes_tb_top/aes_if/clk_en
add wave sim:/aes_tb_top/aes_if/gated_clk_dbg
add wave sim:/aes_tb_top/aes_if/test_mode
add wave sim:/aes_tb_top/aes_if/scan_enable
add wave sim:/aes_tb_top/aes_if/scan_in
add wave sim:/aes_tb_top/aes_if/scan_out

add wave -divider "AES Transaction Interface"
add wave sim:/aes_tb_top/aes_if/load
add wave sim:/aes_tb_top/aes_if/load_sel
add wave sim:/aes_tb_top/aes_if/load_index
add wave -radix hex sim:/aes_tb_top/aes_if/data_in
add wave sim:/aes_tb_top/aes_if/start
add wave sim:/aes_tb_top/aes_if/done
add wave -radix hex sim:/aes_tb_top/aes_if/data_out

add wave -divider "Core State"
add wave -radix hex sim:/aes_tb_top/aes_if/plaintext_dbg
add wave -radix hex sim:/aes_tb_top/aes_if/key_dbg
add wave -radix hex sim:/aes_tb_top/aes_if/state_dbg
add wave -radix hex sim:/aes_tb_top/aes_if/round_key_dbg
add wave -radix unsigned sim:/aes_tb_top/aes_if/round_dbg
add wave -radix hex sim:/aes_tb_top/aes_if/ciphertext_dbg

add wave -divider "Power and Assertion Metrics"
add wave -radix unsigned sim:/aes_tb_top/aes_if/active_cycles
add wave -radix unsigned sim:/aes_tb_top/aes_if/idle_cycles
add wave -radix unsigned sim:/aes_tb_top/aes_if/scan_cycles
add wave -radix unsigned sim:/aes_tb_top/aes_if/gated_clk_edges
add wave -radix unsigned sim:/aes_tb_top/aes_if/state_toggles
add wave -radix unsigned sim:/aes_tb_top/aes_if/round_key_toggles
add wave -radix unsigned sim:/aes_tb_top/aes_if/glitch_count
add wave -radix unsigned sim:/aes_tb_top/aes_if/double_pulse_count
add wave -radix unsigned sim:/aes_tb_top/aes_if/assertion_fail_count

view wave
view structure
view signals
run -all
wave zoom full

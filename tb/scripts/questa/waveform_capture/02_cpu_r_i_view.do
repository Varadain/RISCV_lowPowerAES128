view wave
delete wave *
set DS 02_directed_cpu_capture
add wave -divider {DIRECTED CPU PART 1 - R-TYPE AND I-TYPE ALU PIPELINE FLOW}
add wave ${DS}:/riscv_core_tb/clk ${DS}:/riscv_core_tb/rst_n
add wave -radix hexadecimal ${DS}:/riscv_core_tb/obs_if_pc ${DS}:/riscv_core_tb/obs_if_instr ${DS}:/riscv_core_tb/obs_id_instr
add wave -radix hexadecimal ${DS}:/riscv_core_tb/obs_ex_op_a ${DS}:/riscv_core_tb/obs_ex_op_b ${DS}:/riscv_core_tb/obs_ex_alu_result
add wave -radix unsigned ${DS}:/riscv_core_tb/obs_wb_rd
add wave ${DS}:/riscv_core_tb/obs_wb_reg_write
add wave -radix hexadecimal ${DS}:/riscv_core_tb/obs_wb_data
add wave -radix unsigned ${DS}:/riscv_core_tb/pass_count ${DS}:/riscv_core_tb/fail_count
configure wave -namecolwidth 280
configure wave -valuecolwidth 190
configure wave -timelineunits ns
wave zoom range 0ns 650ns

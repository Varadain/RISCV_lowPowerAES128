view wave
delete wave *
set DS 04_random_smoke_capture
add wave -divider {DETERMINISTIC RANDOMIZED SMOKE - CUSTOM ISA, SENSOR, DMA, UART}
add wave ${DS}:/riscv_core_tb/clk ${DS}:/riscv_core_tb/rst_n
add wave -radix hexadecimal ${DS}:/riscv_core_tb/obs_if_pc ${DS}:/riscv_core_tb/obs_if_instr
add wave ${DS}:/riscv_core_tb/obs_custom_mem
add wave -radix hexadecimal ${DS}:/riscv_core_tb/obs_custom_result
add wave -radix hexadecimal ${DS}:/riscv_core_tb/obs_mem_eff_addr ${DS}:/riscv_core_tb/obs_mem_write_data ${DS}:/riscv_core_tb/obs_mem_read_data
add wave ${DS}:/riscv_core_tb/obs_mem_read ${DS}:/riscv_core_tb/obs_mem_write
add wave ${DS}:/riscv_core_tb/obs_uart_busy ${DS}:/riscv_core_tb/obs_uart_done ${DS}:/riscv_core_tb/uart_tx_tb
add wave -radix unsigned ${DS}:/riscv_core_tb/pass_count ${DS}:/riscv_core_tb/fail_count
configure wave -namecolwidth 290
configure wave -valuecolwidth 210
configure wave -timelineunits ns
wave zoom full

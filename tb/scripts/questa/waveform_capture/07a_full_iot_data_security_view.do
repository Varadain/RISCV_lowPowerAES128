view wave
delete wave *
set DS 07_full_iot_scenario_capture
add wave -divider {FULL-SOC SCENARIO PART 1 - SENSOR, CPU, DMA, AND AES-CTR}
add wave ${DS}:/riscv_core_tb/clk ${DS}:/riscv_core_tb/rst_n
add wave -radix unsigned ${DS}:/riscv_core_tb/verification_phase_id
add wave -radix hexadecimal ${DS}:/riscv_core_tb/obs_if_pc ${DS}:/riscv_core_tb/obs_if_instr
add wave -radix hexadecimal ${DS}:/riscv_core_tb/obs_mem_eff_addr
add wave ${DS}:/riscv_core_tb/obs_mem_read ${DS}:/riscv_core_tb/obs_mem_write
add wave -radix hexadecimal ${DS}:/riscv_core_tb/obs_mem_write_data ${DS}:/riscv_core_tb/obs_mem_read_data
add wave -radix hexadecimal ${DS}:/riscv_core_tb/obs_dmem4 ${DS}:/riscv_core_tb/obs_dmem5
add wave ${DS}:/riscv_core_tb/spi_sclk_tb ${DS}:/riscv_core_tb/spi_mosi_tb ${DS}:/riscv_core_tb/spi_ss_n_tb
add wave ${DS}:/riscv_core_tb/obs_aes_start ${DS}:/riscv_core_tb/obs_aes_busy ${DS}:/riscv_core_tb/obs_aes_done
add wave -radix hexadecimal ${DS}:/riscv_core_tb/obs_aes_plaintext ${DS}:/riscv_core_tb/obs_aes_ciphertext
configure wave -namecolwidth 300
configure wave -valuecolwidth 230
configure wave -timelineunits ns
wave zoom full
echo {FULL-SOC PART 1: CPU-driven sensor/SPI access, memory/DMA movement, and AES-CTR encryption.}

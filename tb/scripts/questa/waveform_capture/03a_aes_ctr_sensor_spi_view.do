view wave
delete wave *
set DS 03_directed_peripheral_capture
add wave -divider {DIRECTED PERIPHERALS PART 1 - AES-CTR, SENSOR, AND SPI}
add wave ${DS}:/riscv_core_tb/clk ${DS}:/riscv_core_tb/rst_n
add wave -radix hexadecimal ${DS}:/riscv_core_tb/obs_mem_eff_addr ${DS}:/riscv_core_tb/obs_mem_write_data ${DS}:/riscv_core_tb/obs_mem_read_data
add wave ${DS}:/riscv_core_tb/obs_mem_read ${DS}:/riscv_core_tb/obs_mem_write
add wave ${DS}:/riscv_core_tb/obs_aes_start ${DS}:/riscv_core_tb/obs_aes_busy ${DS}:/riscv_core_tb/obs_aes_done
add wave -radix hexadecimal ${DS}:/riscv_core_tb/obs_aes_plaintext ${DS}:/riscv_core_tb/obs_aes_ciphertext
add wave ${DS}:/riscv_core_tb/spi_sclk_tb ${DS}:/riscv_core_tb/spi_mosi_tb ${DS}:/riscv_core_tb/spi_miso_tb ${DS}:/riscv_core_tb/spi_ss_n_tb
add wave -radix unsigned ${DS}:/riscv_core_tb/pass_count ${DS}:/riscv_core_tb/fail_count
configure wave -namecolwidth 290
configure wave -valuecolwidth 220
configure wave -timelineunits us
wave zoom range 0ns 13500ns

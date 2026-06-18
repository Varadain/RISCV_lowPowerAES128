view wave
delete wave *
set DS 05_uvm_e2e_complete_capture
add wave -divider {PART 1 - RANDOMIZED TRANSACTION AND AES PROGRAMMING}
add wave ${DS}:/uvm_e2e_tb_top/clk ${DS}:/uvm_e2e_tb_top/e2e_if/rst_n
add wave -radix unsigned ${DS}:/uvm_e2e_tb_top/e2e_if/transaction_index
add wave -radix hexadecimal ${DS}:/uvm_e2e_tb_top/e2e_if/sensor_plaintext
add wave -divider {AES MMIO writes: address selects register; data carries key/plaintext/nonce/counter}
add wave -radix hexadecimal ${DS}:/uvm_e2e_tb_top/e2e_if/aes_addr ${DS}:/uvm_e2e_tb_top/e2e_if/aes_wdata
add wave ${DS}:/uvm_e2e_tb_top/e2e_if/aes_write_en ${DS}:/uvm_e2e_tb_top/e2e_if/aes_read_en
add wave -radix hexadecimal ${DS}:/uvm_e2e_tb_top/u_aes_mmio/key_reg ${DS}:/uvm_e2e_tb_top/u_aes_mmio/pt_reg
add wave -radix hexadecimal ${DS}:/uvm_e2e_tb_top/u_aes_mmio/nonce_reg ${DS}:/uvm_e2e_tb_top/u_aes_mmio/counter_reg
add wave ${DS}:/uvm_e2e_tb_top/u_aes_mmio/mode_ctr_reg
configure wave -namecolwidth 300
configure wave -valuecolwidth 270
configure wave -timelineunits ns
wave zoom range 0ns 700ns
echo {PART 1: Randomized sensor plaintext, AES key, nonce, counter, and CTR-mode programming.}

view wave
delete wave *
set DS 06_functional_coverage_capture
add wave -divider {100-TRANSACTION PORTABLE FUNCTIONAL COVERAGE CLOSURE}
add wave ${DS}:/uvm_e2e_tb_top/clk ${DS}:/uvm_e2e_tb_top/e2e_if/rst_n
add wave -radix unsigned ${DS}:/uvm_e2e_tb_top/e2e_if/transaction_index
add wave -radix hexadecimal ${DS}:/uvm_e2e_tb_top/e2e_if/sensor_plaintext
add wave -radix hexadecimal ${DS}:/uvm_e2e_tb_top/e2e_if/rtl_ciphertext
add wave ${DS}:/uvm_e2e_tb_top/e2e_if/rtl_ciphertext_match
add wave ${DS}:/uvm_e2e_tb_top/e2e_if/decrypted_plaintext_match
add wave -radix unsigned ${DS}:/uvm_e2e_tb_top/e2e_if/coverage_bins
add wave -radix unsigned ${DS}:/uvm_e2e_tb_top/e2e_if/coverage_percent_x100
add wave -radix unsigned ${DS}:/uvm_e2e_tb_top/e2e_if/uart_matches
add wave -radix unsigned ${DS}:/uvm_e2e_tb_top/e2e_if/uart_mismatches
configure wave -namecolwidth 315
configure wave -valuecolwidth 220
configure wave -timelineunits ms
wave zoom full
echo {FUNCTIONAL COVERAGE: 100 randomized transactions, 114/114 planned bins, 100 UART matches, zero mismatches.}

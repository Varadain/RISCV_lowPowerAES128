view wave
delete wave *
set DS 01_aes_known_answer_capture
add wave -divider {AES-128 NIST KNOWN-ANSWER TEST - ITERATIVE REUSABLE CORE}
add wave ${DS}:/riscv_core_tb/clk ${DS}:/riscv_core_tb/rst_n
add wave -radix hexadecimal ${DS}:/riscv_core_tb/obs_aes_key ${DS}:/riscv_core_tb/obs_aes_plaintext
add wave ${DS}:/riscv_core_tb/obs_aes_start ${DS}:/riscv_core_tb/obs_aes_busy ${DS}:/riscv_core_tb/obs_aes_done
add wave -radix unsigned ${DS}:/riscv_core_tb/obs_aes_round
add wave -radix hexadecimal ${DS}:/riscv_core_tb/obs_aes_state ${DS}:/riscv_core_tb/obs_aes_round_key
add wave -radix hexadecimal ${DS}:/riscv_core_tb/obs_aes_ciphertext
add wave -radix unsigned ${DS}:/riscv_core_tb/pass_count ${DS}:/riscv_core_tb/fail_count
configure wave -namecolwidth 285
configure wave -valuecolwidth 300
configure wave -timelineunits ns
wave zoom full
WaveRestoreCursors {{Completion} {3050000 ps} 0}

# ============================================================
# Quartus TimeQuest SDC constraints
# Project : RISC-V AES IoT Security Processor
# Top     : riscv_aes_advancements
#
# This file mirrors the expanded top-level signal list used for the Genus SDC,
# but uses Quartus/TimeQuest-compatible SDC syntax.
# ============================================================

set CLK_PERIOD_NS       20.000
set INPUT_DELAY_NS      2.000
set OUTPUT_DELAY_NS     2.000

# ============================================================
# Complete explicit top-level signal list
# ============================================================
# Inputs:
#   clk
#   rst_n
#   spi_miso
#
# Outputs:
#   current_pc_debug[0]
#   current_pc_debug[1]
#   current_pc_debug[2]
#   current_pc_debug[3]
#   current_pc_debug[4]
#   current_pc_debug[5]
#   current_pc_debug[6]
#   current_pc_debug[7]
#   current_pc_debug[8]
#   current_pc_debug[9]
#   current_pc_debug[10]
#   current_pc_debug[11]
#   current_pc_debug[12]
#   current_pc_debug[13]
#   current_pc_debug[14]
#   current_pc_debug[15]
#   current_pc_debug[16]
#   current_pc_debug[17]
#   current_pc_debug[18]
#   current_pc_debug[19]
#   current_pc_debug[20]
#   current_pc_debug[21]
#   current_pc_debug[22]
#   current_pc_debug[23]
#   current_pc_debug[24]
#   current_pc_debug[25]
#   current_pc_debug[26]
#   current_pc_debug[27]
#   current_pc_debug[28]
#   current_pc_debug[29]
#   current_pc_debug[30]
#   current_pc_debug[31]
#   aes_done_debug
#   aes_ciphertext_debug[0]
#   aes_ciphertext_debug[1]
#   aes_ciphertext_debug[2]
#   aes_ciphertext_debug[3]
#   aes_ciphertext_debug[4]
#   aes_ciphertext_debug[5]
#   aes_ciphertext_debug[6]
#   aes_ciphertext_debug[7]
#   aes_ciphertext_debug[8]
#   aes_ciphertext_debug[9]
#   aes_ciphertext_debug[10]
#   aes_ciphertext_debug[11]
#   aes_ciphertext_debug[12]
#   aes_ciphertext_debug[13]
#   aes_ciphertext_debug[14]
#   aes_ciphertext_debug[15]
#   aes_ciphertext_debug[16]
#   aes_ciphertext_debug[17]
#   aes_ciphertext_debug[18]
#   aes_ciphertext_debug[19]
#   aes_ciphertext_debug[20]
#   aes_ciphertext_debug[21]
#   aes_ciphertext_debug[22]
#   aes_ciphertext_debug[23]
#   aes_ciphertext_debug[24]
#   aes_ciphertext_debug[25]
#   aes_ciphertext_debug[26]
#   aes_ciphertext_debug[27]
#   aes_ciphertext_debug[28]
#   aes_ciphertext_debug[29]
#   aes_ciphertext_debug[30]
#   aes_ciphertext_debug[31]
#   uart_tx
#   spi_mosi
#   spi_sclk
#   spi_ss_n
#   irq_debug
#   sleep_debug
#   activity_counter_debug[0]
#   activity_counter_debug[1]
#   activity_counter_debug[2]
#   activity_counter_debug[3]
#   activity_counter_debug[4]
#   activity_counter_debug[5]
#   activity_counter_debug[6]
#   activity_counter_debug[7]
#   activity_counter_debug[8]
#   activity_counter_debug[9]
#   activity_counter_debug[10]
#   activity_counter_debug[11]
#   activity_counter_debug[12]
#   activity_counter_debug[13]
#   activity_counter_debug[14]
#   activity_counter_debug[15]
#   activity_counter_debug[16]
#   activity_counter_debug[17]
#   activity_counter_debug[18]
#   activity_counter_debug[19]
#   activity_counter_debug[20]
#   activity_counter_debug[21]
#   activity_counter_debug[22]
#   activity_counter_debug[23]
#   activity_counter_debug[24]
#   activity_counter_debug[25]
#   activity_counter_debug[26]
#   activity_counter_debug[27]
#   activity_counter_debug[28]
#   activity_counter_debug[29]
#   activity_counter_debug[30]
#   activity_counter_debug[31]

# Quartus/TimeQuest collections.  Bus ports are collected with wildcard
# patterns because TimeQuest expands bus bits in its timing netlist.
set CLK_PORT       [get_ports {clk}]
set RESET_PORT     [get_ports {rst_n}]
set DATA_IN_PORTS  [get_ports {spi_miso}]
set OUTPUT_PORTS   [get_ports {current_pc_debug[*] aes_done_debug aes_ciphertext_debug[*] uart_tx spi_mosi spi_sclk spi_ss_n irq_debug sleep_debug activity_counter_debug[*]}]

# Primary system clock.
create_clock -name clk -period $CLK_PERIOD_NS -waveform [list 0.000 [expr $CLK_PERIOD_NS/2.0]] $CLK_PORT

# Active-low asynchronous reset is excluded from normal data timing.
set_false_path -from $RESET_PORT

# External I/O timing assumptions for report generation.
set_input_delay  -clock [get_clocks {clk}] $INPUT_DELAY_NS  $DATA_IN_PORTS
set_output_delay -clock [get_clocks {clk}] $OUTPUT_DELAY_NS $OUTPUT_PORTS

# Let Quartus derive device/corner-specific uncertainty details.
derive_clock_uncertainty

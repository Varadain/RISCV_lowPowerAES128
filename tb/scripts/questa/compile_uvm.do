set ROOT {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/risc_aes_custom_ISA}
set UVM_DIR [file join $ROOT verification uvm_e2e]
set WORK questa_capture_uvm_work
file mkdir results

if {[file exists $WORK]} {
    vdel -lib $WORK -all
}
vlib $WORK
vmap work $WORK
vlog -sv +incdir+$UVM_DIR -work $WORK \
    [file join $UVM_DIR uvm_e2e_if.sv] \
    [file join $ROOT aes_mmio.sv] \
    [file join $ROOT rtl aes128_reusable 00_aes128_top.sv] \
    [file join $ROOT rtl aes128_reusable 01_aes_sbox_rom.sv] \
    [file join $ROOT rtl aes128_reusable 02_aes_sbox_seq.sv] \
    [file join $ROOT rtl aes128_reusable 03_aes_mix_columns_seq.sv] \
    [file join $ROOT rtl aes128_reusable 04_aes_key_expand_seq.sv] \
    [file join $ROOT aes128_lowpower.sv] \
    [file join $ROOT uart_tx.sv] [file join $ROOT uart_mmio.sv] \
    [file join $UVM_DIR uvm_e2e_pkg.sv] [file join $UVM_DIR uvm_e2e_tb_top.sv]

set ROOT {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/risc_aes_custom_ISA}
set WORK questa_capture_work
file mkdir results

if {[file exists $WORK]} {
    vdel -lib $WORK -all
}
vlib $WORK
vmap work $WORK

set rtl_files [list \
    riscv_aes_advancements.sv pc_reg.sv if_stage.sv instr_mem.sv id_stage.sv \
    reg_file.sv imm_gen.sv control_unit.sv hazard_unit.sv forwarding_unit.sv \
    ex_stage.sv alu.sv mem_stage.sv load_store_unit.sv data_mem.sv aes_mmio.sv \
    rtl/aes128_reusable/00_aes128_top.sv rtl/aes128_reusable/01_aes_sbox_rom.sv \
    rtl/aes128_reusable/02_aes_sbox_seq.sv rtl/aes128_reusable/03_aes_mix_columns_seq.sv \
    rtl/aes128_reusable/04_aes_key_expand_seq.sv aes128_lowpower.sv \
    uart_tx.sv uart_mmio.sv sensor_mmio.sv \
    ip/sensor_spi_ip/sensor_spi_ip.v sensor_spi_mmio.sv simple_intc.sv \
    dma_lite.sv power_mgmt_mmio.sv wb_stage.sv riscv_core_tb.sv]

set full_files {}
foreach f $rtl_files {
    lappend full_files [file join $ROOT $f]
}
vlog -sv +define+SIMULATION -work $WORK {*}$full_files

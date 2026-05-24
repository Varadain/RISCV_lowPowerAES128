transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlib sensor_spi_ip
vmap sensor_spi_ip sensor_spi_ip
vlog -vlog01compat -work sensor_spi_ip +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements/risc_aes_custom_ISA/ip/sensor_spi_ip {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/risc_aes_custom_ISA/ip/sensor_spi_ip/sensor_spi_ip.v}
vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements/risc_aes_custom_ISA {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/risc_aes_custom_ISA/riscv_aes_advancements.sv}
vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements/risc_aes_custom_ISA {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/risc_aes_custom_ISA/pc_reg.sv}
vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements/risc_aes_custom_ISA {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/risc_aes_custom_ISA/if_stage.sv}
vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements/risc_aes_custom_ISA {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/risc_aes_custom_ISA/instr_mem.sv}
vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements/risc_aes_custom_ISA {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/risc_aes_custom_ISA/id_stage.sv}
vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements/risc_aes_custom_ISA {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/risc_aes_custom_ISA/reg_file.sv}
vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements/risc_aes_custom_ISA {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/risc_aes_custom_ISA/imm_gen.sv}
vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements/risc_aes_custom_ISA {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/risc_aes_custom_ISA/control_unit.sv}
vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements/risc_aes_custom_ISA {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/risc_aes_custom_ISA/hazard_unit.sv}
vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements/risc_aes_custom_ISA {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/risc_aes_custom_ISA/forwarding_unit.sv}
vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements/risc_aes_custom_ISA {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/risc_aes_custom_ISA/ex_stage.sv}
vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements/risc_aes_custom_ISA {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/risc_aes_custom_ISA/alu.sv}
vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements/risc_aes_custom_ISA {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/risc_aes_custom_ISA/mem_stage.sv}
vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements/risc_aes_custom_ISA {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/risc_aes_custom_ISA/load_store_unit.sv}
vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements/risc_aes_custom_ISA {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/risc_aes_custom_ISA/data_mem.sv}
vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements/risc_aes_custom_ISA {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/risc_aes_custom_ISA/aes_mmio.sv}
vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements/risc_aes_custom_ISA {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/risc_aes_custom_ISA/aes128_lowpower.sv}
vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements/risc_aes_custom_ISA {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/risc_aes_custom_ISA/uart_tx.sv}
vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements/risc_aes_custom_ISA {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/risc_aes_custom_ISA/uart_mmio.sv}
vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements/risc_aes_custom_ISA {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/risc_aes_custom_ISA/sensor_spi_mmio.sv}
vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements/risc_aes_custom_ISA {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/risc_aes_custom_ISA/simple_intc.sv}
vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements/risc_aes_custom_ISA {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/risc_aes_custom_ISA/dma_lite.sv}
vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements/risc_aes_custom_ISA {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/risc_aes_custom_ISA/power_mgmt_mmio.sv}
vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements/risc_aes_custom_ISA {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/risc_aes_custom_ISA/wb_stage.sv}

vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements/risc_aes_custom_ISA {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/risc_aes_custom_ISA/riscv_core_tb.sv}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cyclonev_ver -L cyclonev_hssi_ver -L cyclonev_pcie_hip_ver -L rtl_work -L work -L sensor_spi_ip -voptargs="+acc"  riscv_core_tb

add wave *
view structure
view signals
run -all

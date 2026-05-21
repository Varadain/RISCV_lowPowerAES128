transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlib sensor_spi_ip
vmap sensor_spi_ip sensor_spi_ip
vlog -vlog01compat -work sensor_spi_ip +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements/ip/sensor_spi_ip {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/ip/sensor_spi_ip/sensor_spi_ip.v}
vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/riscv_aes_advancements.sv}
vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/pc_reg.sv}
vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/if_stage.sv}
vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/instr_mem.sv}
vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/id_stage.sv}
vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/reg_file.sv}
vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/imm_gen.sv}
vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/control_unit.sv}
vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/hazard_unit.sv}
vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/forwarding_unit.sv}
vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/ex_stage.sv}
vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/alu.sv}
vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/mem_stage.sv}
vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/load_store_unit.sv}
vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/data_mem.sv}
vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/aes_mmio.sv}
vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/aes128_lowpower.sv}
vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/uart_tx.sv}
vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/uart_mmio.sv}
vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/sensor_spi_mmio.sv}
vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/simple_intc.sv}
vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/dma_lite.sv}
vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/power_mgmt_mmio.sv}
vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/wb_stage.sv}

vlog -sv -work work +incdir+D:/mtech/sem\ 4/midesm\ presetation/riscv_aes_advancements {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/riscv_core_tb.sv}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cyclonev_ver -L cyclonev_hssi_ver -L cyclonev_pcie_hip_ver -L rtl_work -L work -L sensor_spi_ip -voptargs="+acc"  riscv_core_tb

add wave *
view structure
view signals
run -all

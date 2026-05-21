$ErrorActionPreference = "Stop"
$Root = $PSScriptRoot
$QuestaBin = "C:\intelFPGA_lite\questa_fse\win64"
$Work = "work_tmp"

$Files = @(
    "riscv_aes_advancements.sv",
    "pc_reg.sv",
    "if_stage.sv",
    "instr_mem.sv",
    "id_stage.sv",
    "reg_file.sv",
    "imm_gen.sv",
    "control_unit.sv",
    "hazard_unit.sv",
    "forwarding_unit.sv",
    "ex_stage.sv",
    "alu.sv",
    "mem_stage.sv",
    "load_store_unit.sv",
    "data_mem.sv",
    "aes_mmio.sv",
    "aes128_lowpower.sv",
    "uart_tx.sv",
    "uart_mmio.sv",
    "sensor_mmio.sv",
    "ip\sensor_spi_ip\sensor_spi_ip.v",
    "sensor_spi_mmio.sv",
    "simple_intc.sv",
    "dma_lite.sv",
    "power_mgmt_mmio.sv",
    "wb_stage.sv",
    "riscv_core_tb.sv"
)

if (Test-Path "$Root\$Work") {
    & "$QuestaBin\vdel.exe" -lib $Work -all
}

& "$QuestaBin\vlib.exe" $Work
& "$QuestaBin\vlog.exe" -sv +define+SIMULATION -work $Work @($Files | ForEach-Object { Join-Path $Root $_ })
& "$QuestaBin\vsim.exe" -c -t 1ps -voptargs="+acc" "$Work.riscv_core_tb" -do "run -all; quit"

param(
    [switch]$FullSocScenarioOnly,
    [ValidateSet("All", "AesKat", "DirectedCpu", "DirectedPeripheral", "RandomSmoke", "FullSocScenario")]
    [string]$VerificationMode = "All"
)

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
    "rtl\aes128_reusable\00_aes128_top.sv",
    "rtl\aes128_reusable\01_aes_sbox_rom.sv",
    "rtl\aes128_reusable\02_aes_sbox_seq.sv",
    "rtl\aes128_reusable\03_aes_mix_columns_seq.sv",
    "rtl\aes128_reusable\04_aes_key_expand_seq.sv",
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
$VsimArgs = @("-c", "-t", "1ps", "-voptargs=+acc", "$Work.riscv_core_tb")
if ($FullSocScenarioOnly) {
    $VerificationMode = "FullSocScenario"
}

$ModePlusArgs = @{
    "AesKat"             = "+AES_KAT_ONLY"
    "DirectedCpu"        = "+DIRECTED_CPU_ONLY"
    "DirectedPeripheral" = "+DIRECTED_PERIPHERAL_ONLY"
    "RandomSmoke"        = "+RANDOM_SMOKE_ONLY"
    "FullSocScenario"    = "+FULL_SOC_SCENARIO_ONLY"
}
if ($VerificationMode -ne "All") {
    $VsimArgs += $ModePlusArgs[$VerificationMode]
}
$VsimArgs += @("-do", "run -all; quit")

& "$QuestaBin\vsim.exe" @VsimArgs

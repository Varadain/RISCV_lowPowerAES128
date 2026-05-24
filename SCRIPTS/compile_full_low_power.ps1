param(
    [switch]$NoAssembler
)

$ErrorActionPreference = "Stop"
$Project = "riscv_aes_advancements"
$QuartusBin = "C:\intelFPGA_lite\23.1std\quartus\bin64"
$Qsf = Join-Path $PSScriptRoot "$Project.qsf"
$OriginalQsf = Get-Content -Raw $Qsf

Write-Host "Full low-CPU Quartus compile." -ForegroundColor Cyan
Write-Host "Tip: close browsers/Questa first and keep the laptop on a hard surface." -ForegroundColor DarkCyan

try {
    $LimitedQsf = $OriginalQsf -replace 'set_global_assignment -name NUM_PARALLEL_PROCESSORS \d+', 'set_global_assignment -name NUM_PARALLEL_PROCESSORS 1'
    Set-Content -Path $Qsf -Value $LimitedQsf -NoNewline

    & "$QuartusBin\quartus_map.exe" --read_settings_files=on --write_settings_files=off $Project -c $Project
    & "$QuartusBin\quartus_fit.exe" --read_settings_files=off --write_settings_files=off $Project -c $Project

    if (-not $NoAssembler) {
        & "$QuartusBin\quartus_asm.exe" --read_settings_files=off --write_settings_files=off $Project -c $Project
    }

    & "$QuartusBin\quartus_sta.exe" $Project -c $Project
} finally {
    Set-Content -Path $Qsf -Value $OriginalQsf -NoNewline
}

Write-Host "Full compile flow complete." -ForegroundColor Green

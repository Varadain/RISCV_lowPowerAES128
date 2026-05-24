#Fast Quartus compile script, useful for checking synthesis without heavy full flow.
param(
    [switch]$RunSta,
    [switch]$Cool
)

$ErrorActionPreference = "Stop"
$Project = "riscv_aes_advancements"
$QuartusBin = "C:\intelFPGA_lite\23.1std\quartus\bin64"
$Qsf = Join-Path $PSScriptRoot "$Project.qsf"
$OriginalQsf = Get-Content -Raw $Qsf

Write-Host "Lightweight compile: Analysis & Synthesis only" -ForegroundColor Cyan
Write-Host "This avoids the fitter/assembler heat-heavy stages." -ForegroundColor DarkCyan

try {
    if ($Cool) {
        # Optional cooler mode. Quartus will warn that this is slower, so it is
        # opt-in rather than the default warning-clean flow.
        $LimitedQsf = $OriginalQsf -replace 'set_global_assignment -name NUM_PARALLEL_PROCESSORS \d+', 'set_global_assignment -name NUM_PARALLEL_PROCESSORS 1'
        Set-Content -Path $Qsf -Value $LimitedQsf -NoNewline
    }

    & "$QuartusBin\quartus_map.exe" --read_settings_files=on --write_settings_files=off $Project -c $Project

    if ($RunSta) {
        Write-Host "Running Timing Analyzer only because -RunSta was requested." -ForegroundColor Cyan
        & "$QuartusBin\quartus_sta.exe" $Project -c $Project
    }
} finally {
    Set-Content -Path $Qsf -Value $OriginalQsf -NoNewline
}

Write-Host "Done. For full FPGA implementation, run .\compile_full_low_power.ps1 later." -ForegroundColor Green

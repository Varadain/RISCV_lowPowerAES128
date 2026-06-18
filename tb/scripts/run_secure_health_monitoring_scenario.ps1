# Stop immediately if compilation, simulation, or file handling fails.
$ErrorActionPreference = "Stop"

# Resolve all paths from this script so it can be launched from any directory.
$ScenarioDir = $PSScriptRoot
$Root = Resolve-Path (Join-Path $ScenarioDir "..\..")
$ResultsDir = Join-Path $ScenarioDir "results"
$LogPath = Join-Path $ResultsDir "secure_health_monitoring_scenario.log"
$VcdPath = Join-Path $ResultsDir "secure_health_monitoring_scenario.vcd"

# Keep scenario evidence separate from normal regression output.
New-Item -ItemType Directory -Force -Path $ResultsDir | Out-Null

Push-Location $Root
try {
    # Run only the CPU-driven Full-SoC application. The regression script
    # compiles the same production RTL used by the complete project.
    & powershell -NoProfile -ExecutionPolicy Bypass -File ".\run_questa_regression.ps1" -FullSocScenarioOnly *>&1 |
        Tee-Object -FilePath $LogPath

    # Convert a nonzero simulator exit status into a clear script failure.
    if ($LASTEXITCODE -ne 0) {
        throw "Standalone Full-SoC scenario simulation failed."
    }

    # Preserve the waveform beside the scenario transcript for later review.
    if (Test-Path ".\riscv_core_tb.vcd") {
        Copy-Item ".\riscv_core_tb.vcd" $VcdPath -Force
    }

    # Print only the final pass/fail lines after the full log has been stored.
    $summary = Select-String -Path $LogPath -Pattern "verification summary:|ALL TESTS PASSED|SOME TESTS FAILED"
    $summary | ForEach-Object { Write-Host $_.Line }
}
finally {
    Pop-Location
}

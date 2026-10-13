param(
    [ValidateSet('AesCore','All','AesKat','DirectedCpu','DirectedPeripheral','RandomSmoke','FullSocScenario','UvmE2e','Coverage')]
    [string]$Mode = 'AesCore',
    [ValidateRange(1,100000)][int]$NumTxns = 25,
    [int]$Seed = 101,
    [string]$QuestaBin = '',
    [switch]$NativeCovergroups,
    [switch]$DryRun
)
$ErrorActionPreference = 'Stop'
$Root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$IsUvm = $Mode -in @('UvmE2e','Coverage')
$List = if ($IsUvm) { 'uvm' } elseif ($Mode -eq 'AesCore') { 'aes' } else { 'soc' }
$Sources = @(Get-Content -LiteralPath (Join-Path $Root "tb/filelists/$List.f") |
    Where-Object { $_.Trim() -and -not $_.StartsWith('#') } |
    ForEach-Object { Join-Path $Root $_.Trim() })
foreach ($source in $Sources) { if (-not (Test-Path -LiteralPath $source)) { throw "Missing source: $source" } }
$Top = if ($IsUvm) { 'uvm_e2e_tb_top' } elseif ($Mode -eq 'AesCore') { 'aes128_core_tb' } else { 'riscv_core_tb' }
if ($Mode -eq 'Coverage' -and -not $PSBoundParameters.ContainsKey('NumTxns')) { $NumTxns = 100 }
if ($Mode -eq 'Coverage' -and -not $PSBoundParameters.ContainsKey('Seed')) { $Seed = 611 }
if ($DryRun) {
    Write-Output "Mode=$Mode Top=$Top Sources=$($Sources.Count) Transactions=$NumTxns Seed=$Seed"
    $Sources | ForEach-Object { Write-Output $_ }
    exit 0
}

function Find-Tool([string]$Name) {
    if ($QuestaBin) {
        $candidate = Join-Path $QuestaBin "$Name.exe"
        if (Test-Path -LiteralPath $candidate) { return $candidate }
    }
    $tool = Get-Command $Name -ErrorAction SilentlyContinue
    if ($tool) { return $tool.Source }
    throw "$Name not found. Add Questa's bin directory to PATH or pass -QuestaBin."
}
$Vlib = Find-Tool 'vlib'; $Vlog = Find-Tool 'vlog'; $Vsim = Find-Tool 'vsim'
$Build = Join-Path $Root "build/$Mode"
if (-not $Build.StartsWith($Root+[IO.Path]::DirectorySeparatorChar)) { throw 'Invalid build directory' }
New-Item -ItemType Directory -Force -Path $Build | Out-Null
Push-Location $Build
try {
    if (-not (Test-Path -LiteralPath 'work')) {
        & $Vlib work
        if ($LASTEXITCODE -ne 0) { throw 'vlib failed' }
    }
    $CompileArgs = @('-sv','-work','work',"+incdir+$(Join-Path $Root 'tb/uvm')")
    if ($NativeCovergroups) { $CompileArgs += '+define+NATIVE_COVERGROUPS' }
    & $Vlog @CompileArgs @Sources 2>&1 | Tee-Object -FilePath compile.log
    if ($LASTEXITCODE -ne 0) { throw "vlog failed; see $Build/compile.log" }
    $SimArgs = @('-c','-t','1ps','-voptargs=+acc','-wlf','simulation.wlf')
    if ($IsUvm) {
        $QuestaRoot = Split-Path (Split-Path $Vlog -Parent) -Parent
        $Gcc = Get-Command gcc -ErrorAction SilentlyContinue
        $Compiler = if ($Gcc) { $Gcc.Source } else {
            $Bundled = Get-ChildItem -LiteralPath $QuestaRoot -Directory -Filter 'gcc-*' |
                ForEach-Object { Get-ChildItem -LiteralPath $_.FullName -Recurse -File -Filter gcc.exe } |
                Select-Object -First 1
            if ($Bundled) { $Bundled.FullName }
        }
        if (-not $Compiler) { throw 'UVM needs gcc for the C-DPI model. Use a Questa installation with its bundled compiler or MinGW-w64.' }
        & $Compiler -shared -O2 "-I$(Join-Path $QuestaRoot 'include')" -o aes_ctr_ref.dll (Join-Path $Root 'tb/reference_model/aes_ctr_ref.c') 2>&1 |
            Tee-Object -FilePath dpi-build.log
        if ($LASTEXITCODE -ne 0) { throw 'C-DPI compilation failed' }
        $SimArgs += @('-sv_seed',"$Seed",'-sv_lib',(Join-Path $Build 'aes_ctr_ref'),"+NUM_TXNS=$NumTxns","+E2E_SEED=$Seed")
    } else {
        $PlusArgs = @{ AesKat='+AES_KAT_ONLY'; DirectedCpu='+DIRECTED_CPU_ONLY'; DirectedPeripheral='+DIRECTED_PERIPHERAL_ONLY'; RandomSmoke='+RANDOM_SMOKE_ONLY'; FullSocScenario='+FULL_SOC_SCENARIO_ONLY' }
        if ($PlusArgs.ContainsKey($Mode)) { $SimArgs += $PlusArgs[$Mode] }
    }
    # Abort an accidental endless simulation after 20 ms of simulated time.
    $SimArgs += @("work.$Top",'-do','onerror {quit -code 1}; run 20 ms; quit -code 0')
    & $Vsim @SimArgs 2>&1 | Tee-Object -FilePath simulation.log
    if ($LASTEXITCODE -ne 0) { throw "vsim failed; see $Build/simulation.log" }
    $Log = Get-Content -Raw -LiteralPath simulation.log
    if ($Log -match 'SOME TESTS FAILED|\*\* (Error|Fatal):|UVM_(ERROR|FATAL)\s+:\s+[1-9]|mismatches=[1-9]') {
        throw "Verification reported failures; see $Build/simulation.log"
    }
    if ($IsUvm) {
        if ($Log -notmatch "matches=$NumTxns mismatches=0") { throw 'UVM did not finish the expected transaction count' }
        if ($Mode -eq 'Coverage' -and $Log -notmatch '114/114 bins') { throw 'Portable coverage did not close all 114 defined bins' }
    } elseif ($Log -notmatch 'ALL TESTS PASSED') { throw 'No completed passing test summary found' }
    Write-Output "Completed $Mode. Logs and waveforms: $Build"
}
finally { Pop-Location }

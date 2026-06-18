param(
    [int]$NumTxns = 25,
    [int]$Seed = 1,
    [switch]$DumpVcd,
    [switch]$NativeCovergroups,
    [string]$VcdPath = ""
)

$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$UvmDir = $PSScriptRoot
$Work = "uvm_e2e_work"
$RefBase = Join-Path $UvmDir "aes_ctr_ref"
$RefC = Join-Path $UvmDir "aes_ctr_ref.c"

function Find-QuestaRoot {
    $vlogCmd = Get-Command vlog -ErrorAction SilentlyContinue
    if ($vlogCmd) {
        return (Resolve-Path (Join-Path (Split-Path $vlogCmd.Source -Parent) "..")).Path
    }
    return $null
}

function Build-DpiLibrary {
    $gcc = Get-Command gcc -ErrorAction SilentlyContinue
    $cl = Get-Command cl -ErrorAction SilentlyContinue
    $zigCmd = Get-Command python-zig -ErrorAction SilentlyContinue
    $zigExe = $null
    if ($zigCmd) {
        $zigExe = $zigCmd.Source
    }
    if (-not $zigExe) {
        $zigPath = Join-Path $env:APPDATA "Python\Python312\Scripts\python-zig.exe"
        if (Test-Path $zigPath) {
            $zigExe = $zigPath
        }
    }

    $questaRoot = Find-QuestaRoot
    if (-not $questaRoot) {
        throw "Could not locate Questa installation from PATH. Run this script from a Questa-enabled shell."
    }

    $dpiInclude = Join-Path $questaRoot "include"
    $dll = "$RefBase.dll"

    if ($gcc) {
        & gcc -shared -O2 -I"$dpiInclude" -o "$dll" "$RefC"
        if ($LASTEXITCODE -ne 0) {
            throw "gcc failed while building aes_ctr_ref.dll"
        }
        return
    }

    if ($cl) {
        & cl /nologo /LD /O2 /I"$dpiInclude" "$RefC" /Fe"$dll"
        if ($LASTEXITCODE -ne 0) {
            throw "cl.exe failed while building aes_ctr_ref.dll"
        }
        Remove-Item -ErrorAction SilentlyContinue "$RefBase.obj", "$RefBase.exp", "$RefBase.lib"
        return
    }

    if ($zigExe) {
        & $zigExe cc -shared -O2 -I"$dpiInclude" -o "$dll" "$RefC"
        if ($LASTEXITCODE -ne 0) {
            throw "python-zig failed while building aes_ctr_ref.dll"
        }
        return
    }

    throw "No C compiler was found in PATH. Install MinGW-w64/MSYS2 gcc, run from a Visual Studio Developer PowerShell where cl.exe is available, or install Python ziglang."
}

Push-Location $Root
try {
    Build-DpiLibrary

    if (Test-Path $Work) {
        Remove-Item -Recurse -Force $Work
    }
    vlib $Work
    vmap work $Work

    $vlogArgs = @(
        "-sv",
        "+incdir+$UvmDir"
    )
    if ($NativeCovergroups) {
        $vlogArgs += "+define+NATIVE_COVERGROUPS"
    }
    $vlogArgs += @(
        "$UvmDir\uvm_e2e_if.sv",
        "$Root\aes_mmio.sv",
        "$Root\rtl\aes128_reusable\00_aes128_top.sv",
        "$Root\rtl\aes128_reusable\01_aes_sbox_rom.sv",
        "$Root\rtl\aes128_reusable\02_aes_sbox_seq.sv",
        "$Root\rtl\aes128_reusable\03_aes_mix_columns_seq.sv",
        "$Root\rtl\aes128_reusable\04_aes_key_expand_seq.sv",
        "$Root\aes128_lowpower.sv",
        "$Root\uart_tx.sv",
        "$Root\uart_mmio.sv",
        "$UvmDir\uvm_e2e_pkg.sv",
        "$UvmDir\uvm_e2e_tb_top.sv"
    )
    vlog @vlogArgs
    if ($LASTEXITCODE -ne 0) {
        throw "vlog failed while compiling the UVM end-to-end environment"
    }

    $doCmd = "run -all; quit"
    if ($DumpVcd) {
        if ([string]::IsNullOrWhiteSpace($VcdPath)) {
            $VcdPath = Join-Path $UvmDir "uvm_e2e_${NumTxns}_seed_${Seed}.vcd"
        }
        $resolvedVcd = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($VcdPath)
        $vcdForQuesta = $resolvedVcd.Replace("\", "/")
        $doCmd = "vcd file {$vcdForQuesta}; " +
                 "vcd add /uvm_e2e_tb_top/clk; " +
                 "vcd add -r /uvm_e2e_tb_top/e2e_if/*; " +
                 "vcd add -r /uvm_e2e_tb_top/u_aes_mmio/*; " +
                 "vcd add -r /uvm_e2e_tb_top/u_uart_mmio/*; " +
                 "run -all; vcd flush; quit"
    }

    $vsimArgs = @("-c", "-sv_seed", "$Seed", "-sv_lib", "$RefBase")
    if ($DumpVcd) {
        $vsimArgs += @("-voptargs=+acc")
    }
    $vsimArgs += @("work.uvm_e2e_tb_top", "-do", "$doCmd", "+UVM_TESTNAME=uvm_e2e_test", "+NUM_TXNS=$NumTxns", "+E2E_SEED=$Seed")
    & vsim @vsimArgs
    if ($LASTEXITCODE -ne 0) {
        throw "vsim failed while running the UVM end-to-end environment"
    }
}
finally {
    Pop-Location
}

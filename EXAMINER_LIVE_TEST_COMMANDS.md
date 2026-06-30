# Examiner Live-Test Command Sheet

Project root:

```text
D:\mtech\sem 4\midesm presetation\riscv_aes_advancements\risc_aes_custom_ISA
```

## 1. First Clarification: Quartus or Questa?

- **Quartus** compiles, synthesizes, fits and analyzes the FPGA design.
- **Questa** runs RTL, directed, randomized, UVM and scenario simulations.
- Therefore, when the examiner asks to run a functional test, run it in **Questa**.
- Use Quartus only if the examiner asks for synthesis, resource, timing, power or netlist evidence.

Do not enter a Questa `do` command in the Quartus Tcl Console. The `do` command belongs in the **Questa Transcript**.

## 2. Fastest GUI Method

Open PowerShell and run:

```powershell
cd "D:\mtech\sem 4\midesm presetation\riscv_aes_advancements\risc_aes_custom_ISA\verification\questa_wave_capture"
```

Then select the required test:

| Examiner request | Command | Expected evidence |
| --- | --- | --- |
| AES NIST test only | `.\launch_capture.ps1 -Test 01` | 6 PASS, 0 FAIL |
| Directed CPU instructions only | `.\launch_capture.ps1 -Test 02` | 47 PASS, 0 FAIL |
| Directed peripherals and custom ISA only | `.\launch_capture.ps1 -Test 03` | 25 PASS, 0 FAIL |
| Randomized smoke test only | `.\launch_capture.ps1 -Test 04` | 5 PASS, 0 FAIL |
| UVM end-to-end test | `.\launch_capture.ps1 -Test 05` | RTL/C/decryption/UART match |
| 100-transaction portable coverage | `.\launch_capture.ps1 -Test 06` | 100 matches, 0 mismatches, 114/114 bins |
| Complete Full-SoC scenario | `.\launch_capture.ps1 -Test 07` | 15 PASS, 0 FAIL |

Each command compiles the required sources, starts the selected simulation, opens the Wave and Transcript windows and applies a curated signal view.

## 3. Directed Peripheral Test Only

### PowerShell GUI command

```powershell
cd "D:\mtech\sem 4\midesm presetation\riscv_aes_advancements\risc_aes_custom_ISA\verification\questa_wave_capture"
.\launch_capture.ps1 -Test 03
```

### Command inside an already-open Questa Transcript

```tcl
cd {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/risc_aes_custom_ISA/verification/questa_wave_capture}
do 03_directed_peripherals_custom.do
```

### Headless regression command

```powershell
cd "D:\mtech\sem 4\midesm presetation\riscv_aes_advancements\risc_aes_custom_ISA"
.\run_questa_regression.ps1 -VerificationMode DirectedPeripheral
```

The selector passed to the testbench is:

```text
+DIRECTED_PERIPHERAL_ONLY
```

This selector executes only:

1. AES-CTR test
2. Sensor MMIO test
3. Sensor SPI test
4. UART MMIO test
5. Interrupt-controller test
6. DMA-lite test
7. Power and activity-counter test
8. Custom security ISA test

It does not execute the directed CPU instruction suite, random smoke test or Full-SoC scenario.

### What to show the examiner

In the Transcript, point to:

```text
PASS=25 FAIL=0
ALL TESTS PASSED
```

This exact command was rechecked on 1 July 2026. Questa compiled the RTL with `Errors: 0, Warnings: 0`; the simulation completed at 18,225 ns and reported all 25 checks passed. The single `vopt-10587` simulation warning is caused by `+acc`, which intentionally retains internal waveform visibility and is not a functional RTL failure.

In the Wave window, explain:

1. `clk` toggles and `rst_n` is released.
2. `obs_mem_eff_addr` selects each MMIO range.
3. `obs_mem_write` and `obs_mem_read` identify CPU peripheral accesses.
4. AES shows `start -> busy -> done`, followed by ciphertext.
5. SPI shows serial-clock and data activity.
6. UART shows `busy`, serial `uart_tx_tb`, and `done`.
7. Interrupt, DMA, sleep and custom-ISA signals become active in their test windows.
8. `fail_count` remains zero.

The complete waveform can be divided into three readable views after producing the native WLF capture:

```powershell
& "C:\intelFPGA_lite\questa_fse\win64\vsim.exe" -c -do 03_directed_peripheral_capture_run.do
```

Then open Questa and apply one of these view scripts:

```tcl
dataset open results/03_directed_peripheral_capture.wlf
do 03a_aes_ctr_sensor_spi_view.do
```

```tcl
dataset open results/03_directed_peripheral_capture.wlf
do 03b_uart_irq_dma_power_view.do
```

```tcl
dataset open results/03_directed_peripheral_capture.wlf
do 03c_custom_isa_view.do
```

## 4. UVM End-to-End Test

The UVM end-to-end environment is different from the complete processor scenario. It verifies the AES-CTR and UART data path using randomized inputs and an independent C-DPI reference model.

### One transaction with a readable GUI waveform

```powershell
cd "D:\mtech\sem 4\midesm presetation\riscv_aes_advancements\risc_aes_custom_ISA\verification\questa_wave_capture"
.\launch_capture.ps1 -Test 05
```

Equivalent command in the Questa Transcript:

```tcl
cd {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/risc_aes_custom_ISA/verification/questa_wave_capture}
do 05_uvm_e2e_c_reference.do
```

The single transaction is intentional for a readable live waveform. It uses:

```text
+UVM_TESTNAME=uvm_e2e_test
+NUM_TXNS=1
+E2E_SEED=101
```

### Twenty-five transaction UVM regression

Use a Questa-enabled PowerShell:

```powershell
$env:Path = "C:\intelFPGA_lite\questa_fse\win64;$env:Path"
cd "D:\mtech\sem 4\midesm presetation\riscv_aes_advancements\risc_aes_custom_ISA"
.\verification\uvm_e2e\run_uvm_e2e_questa.ps1 -NumTxns 25 -Seed 101
```

This script also builds `aes_ctr_ref.dll` from the independent C AES-CTR reference model when necessary.

### What UVM proves

For every randomized transaction:

1. The sequence generates plaintext, key, nonce and counter.
2. The driver programs AES MMIO registers.
3. The C-DPI model calculates the reference ciphertext and decrypts it.
4. RTL AES-CTR calculates its ciphertext.
5. The driver sends the transaction record through RTL UART.
6. The UART monitor reconstructs the serial text.
7. The scoreboard compares expected and observed UART records.
8. Coverage records randomized input bins and result matches.

### Pass evidence

Show all of the following:

```text
rtl_ciphertext_match = 1
decrypted_plaintext_match = 1
uart_mismatches = 0
```

For the 25-transaction run, the expected summary is 25 UART matches and zero mismatches. A one-transaction waveform should show one match and zero mismatches.

If `aes_ctr_ref.dll` is missing, first execute the 25-transaction PowerShell command above. It compiles the C model and then runs UVM.

## 5. Complete Full-SoC Scenario

If the examiner says "run the complete sensor-to-UART scenario," use Test 07. This is a CPU-driven scenario in `riscv_core_tb.sv`; it is not the standalone UVM environment.

### GUI command

```powershell
cd "D:\mtech\sem 4\midesm presetation\riscv_aes_advancements\risc_aes_custom_ISA\verification\questa_wave_capture"
.\launch_capture.ps1 -Test 07
```

### Questa Transcript command

```tcl
cd {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/risc_aes_custom_ISA/verification/questa_wave_capture}
do 07_full_iot_scenario.do
```

### Headless command with saved log

```powershell
cd "D:\mtech\sem 4\midesm presetation\riscv_aes_advancements\risc_aes_custom_ISA"
.\verification\scenarios\run_secure_health_monitoring_scenario.ps1
```

The testbench selector is:

```text
+FULL_SOC_SCENARIO_ONLY
```

The scenario executes:

```text
Sensor/SPI -> CPU/RAM -> DMA -> AES-CTR -> UART -> IRQ/power counters -> sleep
```

### Pass evidence

Show:

```text
PASS=15 FAIL=0
ALL TESTS PASSED
```

Explain the waveform in two parts:

- Data-security path: CPU, MMIO, sensor/SPI, DMA and AES-CTR.
- Output/control path: UART, interrupt, activity counter and sleep.

## 6. Functional Coverage Run

The installed Questa Starter Edition does not provide the license needed for native SystemVerilog covergroups. Use the portable coverage collector already implemented in the UVM environment.

### GUI command

```powershell
cd "D:\mtech\sem 4\midesm presetation\riscv_aes_advancements\risc_aes_custom_ISA\verification\questa_wave_capture"
.\launch_capture.ps1 -Test 06
```

### Portable 100-transaction command

```powershell
$env:Path = "C:\intelFPGA_lite\questa_fse\win64;$env:Path"
cd "D:\mtech\sem 4\midesm presetation\riscv_aes_advancements\risc_aes_custom_ISA"
.\verification\uvm_e2e\run_uvm_e2e_questa.ps1 -NumTxns 100 -Seed 611
```

Expected evidence:

```text
100 UART matches
0 UART mismatches
114/114 portable coverage bins
```

Do not add `-NativeCovergroups` on the current Starter Edition installation.

## 7. Other Directed Selectors

Run these from the project root:

```powershell
.\run_questa_regression.ps1 -VerificationMode AesKat
.\run_questa_regression.ps1 -VerificationMode DirectedCpu
.\run_questa_regression.ps1 -VerificationMode DirectedPeripheral
.\run_questa_regression.ps1 -VerificationMode RandomSmoke
.\run_questa_regression.ps1 -VerificationMode FullSocScenario
.\run_questa_regression.ps1 -VerificationMode All
```

The corresponding testbench plusargs are:

| Mode | Plusarg |
| --- | --- |
| AES KAT | `+AES_KAT_ONLY` |
| Directed CPU | `+DIRECTED_CPU_ONLY` |
| Directed peripherals | `+DIRECTED_PERIPHERAL_ONLY` |
| Random smoke | `+RANDOM_SMOKE_ONLY` |
| Full-SoC scenario | `+FULL_SOC_SCENARIO_ONLY` |

## 8. If the Examiner Specifically Says "Run It Through Quartus"

Answer:

> Quartus is used to compile and implement the synthesizable FPGA design. The functional testbench and UVM environment execute in Questa. I can first show the successful Quartus Analysis and Synthesis result, then launch the selected RTL test directly in Questa with its runtime selector.

For a quick Quartus compile without a long full fit, open the Quartus project and select:

```text
Processing -> Start -> Start Analysis & Synthesis
```

Command-line equivalent:

```powershell
cd "D:\mtech\sem 4\midesm presetation\riscv_aes_advancements\risc_aes_custom_ISA"
quartus_map riscv_aes_advancements -c riscv_aes_advancements
```

Do not start a full fit during a short live demonstration unless the examiner explicitly asks for it. The fit consumes more time and processor power but does not add value to a functional RTL test.

## 9. Common Live-Demo Problems

| Problem | Meaning | Immediate correction |
| --- | --- | --- |
| `invalid command name "do"` | The command was entered in Quartus Tcl Console | Enter it in Questa Transcript |
| Missing `rom` hierarchy | RTL was compiled without simulation mode | Use `compile_rtl.do`, which adds `+define+SIMULATION` |
| UVM DPI library cannot load | C reference DLL is absent or path is wrong | Run `run_uvm_e2e_questa.ps1` once to build it |
| Wave signals look constant | Entire long test is zoomed out | Use `wave zoom full`, then zoom into an active interval |
| Native covergroup license error | Starter Edition lacks `svverification` | Run portable coverage without `-NativeCovergroups` |
| Old results appear | An old WLF dataset is open | Close the dataset and rerun the selected `.do` file |

## 10. Thirty-Second Viva Answer

> Each verification layer has a runtime plusarg, so I do not modify the RTL or testbench to isolate a test. For example, `+DIRECTED_PERIPHERAL_ONLY` runs only AES-CTR, sensor/SPI, UART, interrupt, DMA, power and custom-ISA checks and produces 25 passes with zero failures. The UVM test is a separate environment selected with `+UVM_TESTNAME=uvm_e2e_test`; it randomizes plaintext, key, nonce and counter, compares RTL against a C-DPI model, reconstructs UART output and checks it in the scoreboard. For the complete CPU-driven sensor-to-UART application, I use `+FULL_SOC_SCENARIO_ONLY`, which produces 15 passes with zero failures. Quartus proves synthesis and implementation, while Questa executes these functional tests.

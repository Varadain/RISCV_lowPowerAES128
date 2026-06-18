# Scenario Test Case: Secure Health-Monitoring IoT Transaction

## Test Identification

| Field | Value |
| --- | --- |
| Test-case ID | `SOC_SCENARIO_001` |
| Testbench | `riscv_core_tb.sv` |
| DUT top | `riscv_aes_advancements` |
| Run selector | `+FULL_SOC_SCENARIO_ONLY` |
| Verification level | Full-SoC application scenario |
| Expected result | 15 checks pass, 0 checks fail |

## Objective

Verify one realistic health-monitoring transaction across the complete
Lightweight IoT Security Processor. The transaction must be controlled by the
5-stage RISC-V CPU and must exercise the sensor/SPI interface, data memory,
DMA-lite, AES-CTR accelerator, UART transmitter, interrupt controller, activity
counters, and sleep control together.

This scenario complements, but does not replace, the separate instruction and
randomized UVM regressions.

## Application Scenario

A health sensor provides one 32-bit sample:

```text
Sensor sample = 0x12345678
```

The CPU reads the sample, stores it in local RAM, starts an SPI transaction,
programs DMA to copy the sample, configures AES-CTR, encrypts the sample, and
sends the low ciphertext byte through UART. The CPU then reads interrupt and
activity evidence before requesting sleep.

```text
Sensor/SPI
   -> CPU load/store instructions
   -> Data RAM
   -> DMA-lite copy
   -> AES-CTR encryption
   -> UART ciphertext transmission
   -> Interrupt/activity observation
   -> Sleep
```

## Processor Instructions Used

The scenario uses the instruction forms naturally required by the application:

| Instruction | Scenario purpose |
| --- | --- |
| `ADDI` | Construct MMIO addresses, controls, counters, and loop values |
| `LW` | Read sensor, AES ciphertext, constants, IRQ pending, and counters |
| `SW` | Configure peripherals and store sensor data |
| `BNE` | Execute software wait loops while hardware engines complete |
| `JAL` | Hold the CPU at the completed application state |
| `NOP` | Resolve the current core's load-to-store dependency limitation |

All other supported instructions are verified by the separate directed
instruction regression. They are intentionally not forced into this application
because they are not required by the health-monitoring transaction.

## Scenario Phases

### Phase 1: Initialize System Control

The CPU constructs all MMIO base addresses, enables all interrupt sources, and
clears the activity counters.

Expected interrupt enable value:

```text
IRQ_ENABLE = 0x0000000F
```

### Phase 2: Acquire Sensor Sample

The CPU reads `SENSOR_DATA` at `0x00000400` and stores the sample into data RAM.

Expected value:

```text
CPU register sample = 0x12345678
RAM[16]             = 0x12345678
```

### Phase 3: Start SPI Sensor Transaction

The CPU programs SPI slave select, control, and transmit data registers.
Loopback connects `MOSI` to `MISO` in the testbench.

Expected evidence:

```text
SPI SCLK edge count > 0
```

### Phase 4: DMA Sensor Data

The CPU programs DMA-lite to copy one word:

```text
Source      = RAM byte address 64
Destination = RAM byte address 68
Length      = 1 word
```

Expected result:

```text
RAM[17] = 0x12345678
DMA done interrupt asserted
```

### Phase 5: Encrypt Sensor Data

The CPU loads the AES key, nonce, and counter from RAM and starts AES-CTR.

```text
Key     = 000102030405060708090A0B0C0D0E0F
Nonce   = 0011223344556677
Counter = 8899AABBCCDDEEFF
PT0     = 12345678
```

Expected low ciphertext word:

```text
AES CT0 = 0x62809322
```

### Phase 6: Transmit Ciphertext

The CPU reads AES `CT0` and writes it to UART TX data. UART transmits its low
byte.

Expected result:

```text
UART TX data = 0x22
UART done    = 1
```

### Phase 7: Observe Interrupts and Activity

Expected pending interrupt bits:

```text
bit 0 = AES done
bit 1 = UART TX done
bit 2 = sensor ready
bit 3 = DMA done

IRQ_PENDING[3:0] = 0xF
combined IRQ     = 1
```

Expected activity:

```text
AES active cycles    > 0
UART active cycles   > 0
DMA active cycles    > 0
Sensor active cycles > 0
```

### Phase 8: Enter Sleep

After the encrypted sample is transmitted and evidence is captured, the CPU
writes the sleep-request bit.

Expected result:

```text
sleep_debug  = 1
sleep_cycles > 0
```

## Pass Criteria

The scenario passes only when all 15 checks below pass:

1. CPU reaches the application completion marker.
2. CPU reads the expected sensor sample.
3. DMA copies the sample correctly.
4. SPI generates serial-clock activity.
5. AES-CTR produces the expected low ciphertext word.
6. UART accepts the expected ciphertext byte.
7. UART completes transmission.
8. All four interrupt sources become pending.
9. Combined IRQ asserts.
10. AES activity counter is nonzero.
11. UART activity counter is nonzero.
12. DMA activity counter is nonzero.
13. Sensor activity counter is nonzero.
14. Sleep asserts.
15. Sleep-cycle counter increments.

## Run Command

From the project root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\verification\scenarios\run_secure_health_monitoring_scenario.ps1
```

## Generated Evidence

```text
verification/scenarios/results/secure_health_monitoring_scenario.log
verification/scenarios/results/secure_health_monitoring_scenario.vcd
```

The VCD can be opened in Questa for a scenario-focused waveform review.

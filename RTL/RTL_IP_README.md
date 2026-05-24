# Lightweight IoT Security Processor Architecture

## Summary

This project implements a thesis-oriented IoT security SoC around a 5-stage RV32I-style RISC-V processor. The processor reads sensor data through MMIO, encrypts it using a hardware AES-128 accelerator in ECB or CTR mode, and emits encrypted output through a UART transmitter.

This variant adds a RISC-V `custom-0` security instruction path so selected AES/control operations can be issued as custom instructions in addition to the existing MMIO programming model.

```text
Sensor MMIO / Intel Avalon SPI IP
    |
5-stage RISC-V CPU
    |
AES-128 / AES-CTR MMIO
    |
UART MMIO transmitter
    |
Encrypted serial output
```

## Pipeline

The CPU keeps the existing five pipeline stages:

```text
IF -> ID -> EX -> MEM -> WB
```

Forwarding, load-use stalling, and branch flushing are preserved. New functionality is added at the MEM-stage interconnect rather than by rewriting the stable CPU pipeline.

## Security Datapath

The AES primitive remains `aes128_lowpower.sv`. The MMIO wrapper now supports:

- Existing AES-ECB behavior for compatibility.
- AES-CTR mode for streaming sensor payload encryption.
- 64-bit nonce and 64-bit counter register pair.
- Counter auto-increment after each encrypted block.

## Peripheral Set

- `sensor_spi_mmio.sv`: backward-compatible sensor registers plus a generated Intel `altera_avalon_spi` master IP for external sensor I/O.
- `uart_tx.sv` and `uart_mmio.sv`: byte transmit path with programmable baud divisor.
- `simple_intc.sv`: pending/enable/clear interrupt aggregation for AES, UART, sensor, and DMA events.
- `dma_lite.sv`: one-word-per-cycle internal RAM copy engine.
- `power_mgmt_mmio.sv`: sleep request and activity counters for low-power measurement.

## Custom ISA Extension

The custom security ISA uses opcode `0001011`. Decode marks the instruction as a custom operation, EX forwards operands through the normal forwarding muxes, MEM executes the command, and WB writes the result to `rd`.

Supported commands are:

- `CSEC_XOR`
- `CSEC_AES_STATUS`
- `CSEC_AES_START`
- `CSEC_AES_CT0`
- `CSEC_AES_CLEAR`

This lets the thesis compare conventional MMIO AES control against a processor-extension approach with fewer software instructions.

## Low-Power Strategy

The design avoids unsafe generated clocks. Peripheral activity is controlled with clock-enable inputs. The power block records CPU, AES, UART, DMA, sensor, and sleep cycles so a thesis can compare active versus idle behavior.

## FPGA Visibility

The top-level exposes debug outputs to keep meaningful logic observable during FPGA synthesis:

- `current_pc_debug`
- `aes_done_debug`
- `aes_ciphertext_debug`
- `uart_tx`
- `spi_mosi`
- `spi_sclk`
- `spi_ss_n`
- `irq_debug`
- `sleep_debug`
- `activity_counter_debug`


----
# Lightweight IoT Security Processor Memory Map

All addresses are byte addresses. Normal data memory occupies the low RAM region. Peripheral accesses are decoded in `mem_stage.sv`.

| Base | Peripheral | Registers |
| --- | --- | --- |
| `0x0000_0300` | AES / AES-CTR | Key, plaintext, ciphertext, nonce, counter, control/status |
| `0x0000_0400` | Sensor MMIO + SPI IP | Sensor data/status/control and Intel Avalon SPI sensor I/O |
| `0x0000_0500` | UART MMIO | TX data/status/control/baud divisor |
| `0x0000_0600` | Interrupt controller | IRQ pending/enable/clear |
| `0x0000_0700` | DMA-lite | Source/destination/length/control/status |
| `0x0000_0800` | Power/activity | Sleep control and activity counters |

## AES / AES-CTR `0x0000_0300`

| Offset | Name | Description |
| --- | --- | --- |
| `0x00` | `AES_CTRL` | Write bit 0 start, bit 1 clear done, bit 2 CTR mode |
| `0x04` | `AES_STATUS` | Read bit 0 busy, bit 1 done, bit 2 CTR mode |
| `0x08`..`0x14` | `AES_KEY0`..`AES_KEY3` | 128-bit AES key, little-endian word order |
| `0x18`..`0x24` | `AES_PT0`..`AES_PT3` | 128-bit plaintext block |
| `0x28`..`0x34` | `AES_CT0`..`AES_CT3` | 128-bit ciphertext block |
| `0x38` | `AES_NONCE0` | CTR nonce bits `[31:0]` |
| `0x3C` | `AES_NONCE1` | CTR nonce bits `[63:32]` |
| `0x40` | `AES_COUNT0` | CTR counter bits `[31:0]` |
| `0x44` | `AES_COUNT1` | CTR counter bits `[63:32]` |

CTR mode computes `ciphertext = plaintext XOR AES_encrypt(nonce[63:0] || counter[63:0])` and auto-increments the counter after each block.

## Sensor / SPI `0x0000_0400`

| Offset | Name | Description |
| --- | --- | --- |
| `0x00` | `SENSOR_DATA` | Read current sensor sample; write allowed for test/demo injection |
| `0x04` | `SENSOR_STATUS` | Bit 0 data ready |
| `0x08` | `SENSOR_CONTROL` | Bit 0 enable, bit 1 clear data ready |
| `0x10` | `SPI_RXDATA` | Intel `altera_avalon_spi` receive data |
| `0x14` | `SPI_TXDATA` | Intel `altera_avalon_spi` transmit data |
| `0x18` | `SPI_STATUS` | Intel `altera_avalon_spi` status register |
| `0x1C` | `SPI_CONTROL` | Intel `altera_avalon_spi` control register |
| `0x24` | `SPI_SLAVE_SELECT` | Intel `altera_avalon_spi` slave-select register |

The original sensor data/status/control registers remain backward-compatible. The SPI window exposes a generated Intel SPI master IP for realistic external sensor I/O.

## UART `0x0000_0500`

| Offset | Name | Description |
| --- | --- | --- |
| `0x00` | `UART_TXDATA` | Write low byte to start an 8-N-1 transmit when idle |
| `0x04` | `UART_STATUS` | Bit 0 busy, bit 1 done |
| `0x08` | `UART_CONTROL` | Bit 0 enable, bit 1 clear done |
| `0x0C` | `UART_BAUD_DIV` | Baud tick divisor |

## Interrupt Controller `0x0000_0600`

| Offset | Name | Description |
| --- | --- | --- |
| `0x00` | `IRQ_PENDING` | Bit 0 AES done, bit 1 UART done, bit 2 sensor ready, bit 3 DMA done |
| `0x04` | `IRQ_ENABLE` | Same bit layout |
| `0x08` | `IRQ_CLEAR` | Write 1s to clear pending bits |

## DMA-lite `0x0000_0700`

| Offset | Name | Description |
| --- | --- | --- |
| `0x00` | `DMA_SRC_ADDR` | Source byte address |
| `0x04` | `DMA_DST_ADDR` | Destination byte address |
| `0x08` | `DMA_LEN` | Word count |
| `0x0C` | `DMA_CTRL` | Bit 0 start, bit 1 clear done |
| `0x10` | `DMA_STATUS` | Bit 0 busy, bit 1 done |

## Power / Activity `0x0000_0800`

| Offset | Name | Description |
| --- | --- | --- |
| `0x00` | `POWER_CTRL` | Bit 0 sleep request, bit 1 clear counters |
| `0x04` | `CPU_ACTIVE_CYCLES` | CPU-active counter |
| `0x08` | `AES_ACTIVE_CYCLES` | AES busy counter |
| `0x0C` | `UART_ACTIVE_CYCLES` | UART busy counter |
| `0x10` | `SLEEP_CYCLES` | Sleep-mode counter |
| `0x14` | `DMA_ACTIVE_CYCLES` | DMA busy counter |
| `0x18` | `SENSOR_ACTIVE_CYCLES` | Sensor enabled counter |

----
# Custom Security ISA Extension

This project extends the Lightweight IoT Security Processor with a small
RISC-V `custom-0` instruction set. The existing MMIO peripherals remain
compatible; the custom instructions are an added fast path for thesis
comparison.

## Encoding

All custom security instructions use:

```text
opcode = 7'b0001011   // RISC-V custom-0
format = R-type style
funct3 = command
rs1    = operand A
rs2    = operand B
rd     = result register
```

Instruction word:

```text
[31:25] funct7/reserved
[24:20] rs2
[19:15] rs1
[14:12] funct3 command
[11:7]  rd
[6:0]   0001011
```

## Commands

| funct3 | Mnemonic | Behavior |
| --- | --- | --- |
| `000` | `CSEC_XOR rd, rs1, rs2` | `rd = rs1 ^ rs2` |
| `001` | `CSEC_AES_STATUS rd` | `rd = {29'b0, mode_ctr, done, busy}` |
| `010` | `CSEC_AES_START rd, rs1, rs2` | Starts AES-CTR. `pt[31:0]=rs1`, `pt[63:32]=rs2`, high plaintext cleared. |
| `011` | `CSEC_AES_CT0 rd` | `rd = ciphertext[31:0]` |
| `100` | `CSEC_AES_CLEAR rd` | Clears AES done flag. |

## Pipeline Integration

The decode stage recognizes `custom-0` and marks the instruction as a custom
security operation. Operands flow through EX with the normal forwarding muxes:

```text
ID decode -> EX operand forwarding -> MEM custom security unit -> WB rd
```

The MEM stage executes the custom command. AES-related commands are forwarded
to `aes_mmio.sv`, so the existing AES ECB/CTR MMIO behavior is preserved.

## Thesis Use

This extension supports a direct comparison:

```text
MMIO AES control sequence vs custom ISA AES control sequence
```

Expected benefits are fewer instruction cycles for accelerator control and a
clear processor-extension contribution. The tradeoff is lower software
portability because standard assemblers need raw `.word` encodings or custom
assembler support.

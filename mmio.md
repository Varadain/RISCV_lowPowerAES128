# MMIO Code Deep Dive

## Purpose

This document explains the memory-mapped I/O code used in the project:

```text
Lightweight RISC-V Based Secure Health-Monitoring IoT Processor
with AES-CTR Encryption and Custom Security ISA
```

MMIO means **Memory-Mapped Input/Output**. In this design, the RISC-V CPU
controls hardware peripherals using normal load and store instructions.

Instead of having special instructions for every peripheral, the CPU accesses
fixed addresses:

```text
lw -> read a peripheral register
sw -> write a peripheral register
```

Example:

```text
sw x5, 0(x1)
```

If `x1 = 0x0000_0500`, then this store writes to the UART transmit-data
register instead of normal RAM.

---

# 1. Why MMIO Is Used

MMIO allows the same RISC-V load/store path to control:

```text
AES accelerator
Sensor / SPI interface
UART transmitter
Interrupt controller
DMA-lite engine
Power/activity counters
```

The CPU does not need a separate bus protocol or special instruction for every
hardware block. The MEM stage checks the address and sends the access to the
correct peripheral.

Speaker note:

> MMIO is the bridge between the CPU and hardware peripherals. The CPU sees
> peripheral registers as memory addresses. When the CPU executes a load or
> store to a peripheral address, the MEM stage routes that access to the
> corresponding hardware block.

---

# 2. Global MMIO Address Map

The main MMIO address decoding is implemented in:

```text
mem_stage.sv
```

Address map:

| Base Address | Peripheral |
| --- | --- |
| `0x0000_0300` | AES / AES-CTR |
| `0x0000_0400` | Sensor MMIO + SPI |
| `0x0000_0500` | UART MMIO |
| `0x0000_0600` | Interrupt controller |
| `0x0000_0700` | DMA-lite |
| `0x0000_0800` | Power/activity control |

The decoder uses the upper address bits:

```systemverilog
assign aes_sel    = (eff_addr[31:8] == 24'h000003);
assign sensor_sel = (eff_addr[31:8] == 24'h000004);
assign uart_sel   = (eff_addr[31:8] == 24'h000005);
assign intc_sel   = (eff_addr[31:8] == 24'h000006);
assign dma_sel    = (eff_addr[31:8] == 24'h000007);
assign power_sel  = (eff_addr[31:8] == 24'h000008);
```

This means each peripheral gets a 256-byte address window.

Example:

```text
0x0000_0300 to 0x0000_03FF -> AES
0x0000_0400 to 0x0000_04FF -> Sensor/SPI
0x0000_0500 to 0x0000_05FF -> UART
```

---

# 3. MEM Stage MMIO Select Logic

After selecting the peripheral, `mem_stage.sv` generates read/write enables:

```systemverilog
assign aes_write_en    = mem_write_i & aes_sel;
assign aes_read_en     = mem_read_i  & aes_sel;
assign sensor_write_en = mem_write_i & sensor_sel;
assign sensor_read_en  = mem_read_i  & sensor_sel;
assign uart_write_en   = mem_write_i & uart_sel;
assign uart_read_en    = mem_read_i  & uart_sel;
assign intc_write_en   = mem_write_i & intc_sel;
assign intc_read_en    = mem_read_i  & intc_sel;
assign dma_write_en    = mem_write_i & dma_sel;
assign dma_read_en     = mem_read_i  & dma_sel;
assign power_write_en  = mem_write_i & power_sel;
assign power_read_en   = mem_read_i  & power_sel;
```

So:

```text
mem_write_i + AES address -> aes_write_en
mem_read_i  + AES address -> aes_read_en
mem_write_i + UART address -> uart_write_en
mem_read_i  + UART address -> uart_read_en
```

Normal data memory is selected only when the address is not MMIO:

```systemverilog
assign data_mem_read_en  = (mem_read_i | mem_write_i) & ~mmio_sel & ~custom_valid_i;
assign data_mem_write_en = mem_write_i & ~mmio_sel & ~custom_valid_i;
```

Speaker note:

> The MEM stage prevents multiple peripherals from responding at the same time.
> Only one select signal becomes active based on the address. If the address is
> not in the MMIO range, the access goes to normal data memory.

---

# 4. MMIO Read Data Mux

The MEM stage also selects which read data goes back to the CPU:

```systemverilog
always_comb begin
    read_data_o = 32'h0;
    if (custom_valid_i) begin
        read_data_o = custom_result;
    end else if (mmio_sel) begin
        unique case (1'b1)
            aes_sel:    read_data_o = aes_read_data;
            sensor_sel: read_data_o = sensor_read_data;
            uart_sel:   read_data_o = uart_read_data;
            intc_sel:   read_data_o = intc_read_data;
            dma_sel:    read_data_o = dma_read_data;
            power_sel:  read_data_o = power_read_data;
            default:    read_data_o = mmio_sel ? 32'hDEAD_BAAD : mem_read_data;
        endcase
    end else begin
        read_data_o = mem_read_data;
    end
end
```

Meaning:

```text
If custom instruction is active -> return custom result
Else if AES selected -> return AES register data
Else if UART selected -> return UART register data
Else if no MMIO -> return normal RAM data
```

The default MMIO error value is:

```text
0xDEAD_BAAD
```

This helps catch accidental unmapped MMIO accesses.

---

# 5. AES MMIO Code

File:

```text
aes_mmio.sv
```

Base address:

```text
0x0000_0300
```

## AES Register Map

| Offset | Address | Register | Description |
| --- | --- | --- | --- |
| `0x00` | `0x0000_0300` | `AES_CTRL` | Start, clear done, CTR mode |
| `0x04` | `0x0000_0304` | `AES_STATUS` | Busy, done, CTR mode |
| `0x08` | `0x0000_0308` | `AES_KEY0` | Key bits `[31:0]` |
| `0x0C` | `0x0000_030C` | `AES_KEY1` | Key bits `[63:32]` |
| `0x10` | `0x0000_0310` | `AES_KEY2` | Key bits `[95:64]` |
| `0x14` | `0x0000_0314` | `AES_KEY3` | Key bits `[127:96]` |
| `0x18` | `0x0000_0318` | `AES_PT0` | Plaintext bits `[31:0]` |
| `0x1C` | `0x0000_031C` | `AES_PT1` | Plaintext bits `[63:32]` |
| `0x20` | `0x0000_0320` | `AES_PT2` | Plaintext bits `[95:64]` |
| `0x24` | `0x0000_0324` | `AES_PT3` | Plaintext bits `[127:96]` |
| `0x28` | `0x0000_0328` | `AES_CT0` | Ciphertext bits `[31:0]` |
| `0x2C` | `0x0000_032C` | `AES_CT1` | Ciphertext bits `[63:32]` |
| `0x30` | `0x0000_0330` | `AES_CT2` | Ciphertext bits `[95:64]` |
| `0x34` | `0x0000_0334` | `AES_CT3` | Ciphertext bits `[127:96]` |
| `0x38` | `0x0000_0338` | `AES_NONCE0` | Nonce bits `[31:0]` |
| `0x3C` | `0x0000_033C` | `AES_NONCE1` | Nonce bits `[63:32]` |
| `0x40` | `0x0000_0340` | `AES_COUNT0` | Counter bits `[31:0]` |
| `0x44` | `0x0000_0344` | `AES_COUNT1` | Counter bits `[63:32]` |

## AES Control Register

Offset:

```text
0x00
```

Bits:

| Bit | Name | Meaning |
| --- | --- | --- |
| bit 0 | start | Start AES if not busy |
| bit 1 | clear done | Clear done flag |
| bit 2 | mode_ctr | Select CTR mode |

Code behavior:

```systemverilog
mode_ctr_reg <= write_data_i[2];
if (write_data_i[0] && !busy_reg) begin
    busy_reg <= 1'b1;
    done_reg <= 1'b0;
end
if (write_data_i[1]) begin
    done_reg <= 1'b0;
end
```

Meaning:

```text
Write bit 0 = 1 -> AES starts
Write bit 1 = 1 -> done flag clears
Write bit 2 = 1 -> CTR mode
Write bit 2 = 0 -> ECB mode
```

## AES Status Register

Offset:

```text
0x04
```

Read value:

```text
{29'b0, mode_ctr, done, busy}
```

Bits:

| Bit | Meaning |
| --- | --- |
| bit 0 | AES busy |
| bit 1 | AES done |
| bit 2 | CTR mode enabled |

## AES ECB Flow

```text
1. CPU writes AES key registers
2. CPU writes plaintext registers
3. CPU writes AES_CTRL with start=1 and mode_ctr=0
4. AES core encrypts plaintext
5. busy=1 during encryption
6. done=1 after completion
7. CPU reads AES_CT0 to AES_CT3
```

ECB operation:

```text
ciphertext = AES_encrypt(plaintext)
```

## AES-CTR Flow

```text
1. CPU writes AES key
2. CPU writes plaintext health packet
3. CPU writes nonce
4. CPU writes counter
5. CPU writes AES_CTRL with start=1 and mode_ctr=1
6. AES encrypts nonce || counter
7. Wrapper XORs plaintext with keystream
8. Counter auto-increments
9. CPU reads ciphertext
```

CTR operation:

```text
keystream  = AES_encrypt(nonce || counter)
ciphertext = plaintext XOR keystream
```

Code behavior after AES completes:

```systemverilog
ct_reg <= mode_ctr_reg ? (pt_reg ^ aes_ciphertext) : aes_ciphertext;
busy_reg <= 1'b0;
done_reg <= 1'b1;
if (mode_ctr_reg) begin
    counter_reg <= counter_reg + 64'd1;
end
```

Speaker note:

> AES MMIO is the most important security peripheral. The CPU writes key,
> plaintext, nonce, counter, and control values. The AES wrapper starts the
> iterative AES core and returns ciphertext through MMIO registers. ECB mode is
> preserved, and CTR mode is added for IoT sensor-stream encryption.

---

# 6. Sensor / SPI MMIO Code

File:

```text
sensor_spi_mmio.sv
```

Base address:

```text
0x0000_0400
```

This file combines a simple sensor register model with an SPI register window.

## Sensor/SPI Register Map

| Offset | Address | Register | Description |
| --- | --- | --- | --- |
| `0x00` | `0x0000_0400` | `SENSOR_DATA` | Current sensor sample |
| `0x04` | `0x0000_0404` | `SENSOR_STATUS` | bit 0 = data ready |
| `0x08` | `0x0000_0408` | `SENSOR_CONTROL` | bit 0 = enable, bit 1 = clear data ready |
| `0x10` | `0x0000_0410` | `SPI_RXDATA` | SPI receive data |
| `0x14` | `0x0000_0414` | `SPI_TXDATA` | SPI transmit data |
| `0x18` | `0x0000_0418` | `SPI_STATUS` | SPI status |
| `0x1C` | `0x0000_041C` | `SPI_CONTROL` | SPI control |
| `0x24` | `0x0000_0424` | `SPI_SLAVE_SELECT` | SPI slave select |

## Sensor Data Behavior

On reset:

```systemverilog
sensor_data_reg <= 32'h1234_5678;
data_ready_reg  <= 1'b1;
enable_reg      <= 1'b1;
```

So after reset:

```text
SENSOR_DATA = 0x12345678
SENSOR_STATUS[0] = 1
SENSOR_CONTROL[0] = 1
```

When sensor is enabled, an internal `sample_tick` increments. When it reaches
`0xFF`, the sensor data changes:

```systemverilog
sensor_data_reg <= sensor_data_reg + 32'h0001_0101;
data_ready_reg  <= 1'b1;
```

This models a new sensor sample arriving over time.

## Read Behavior

```text
Read SENSOR_DATA   -> returns sensor_data_reg and clears data_ready
Read SENSOR_STATUS -> returns data_ready bit
Read SENSOR_CONTROL -> returns enable bit
```

Code behavior:

```systemverilog
if (read_en_i && (reg_offset == OFF_DATA)) begin
    data_ready_reg <= 1'b0;
end
```

So reading sensor data automatically clears the ready flag.

## Write Behavior

```text
Write SENSOR_DATA -> test/demo injection of sensor value
Write SENSOR_CONTROL[0] -> enable sensor
Write SENSOR_CONTROL[1] -> clear data_ready
```

## SPI Register Selection

SPI offsets are converted to SPI IP addresses:

| MMIO Offset | SPI IP Address |
| --- | --- |
| `SPI_RXDATA` `0x10` | `3'd0` |
| `SPI_TXDATA` `0x14` | `3'd1` |
| `SPI_STATUS` `0x18` | `3'd2` |
| `SPI_CONTROL` `0x1C` | `3'd3` |
| `SPI_SLAVE_SELECT` `0x24` | `3'd5` |

The SPI IP is selected only for SPI offsets:

```systemverilog
spi_select = spi_reg_sel & clk_en_i
```

Speaker note:

> The sensor/SPI MMIO block provides both a simple test sensor and a more
> practical SPI interface. The simple sensor register is useful for simulation,
> while the SPI register window can connect to an external health sensor such as
> a pulse or temperature sensor module.

---

# 7. UART MMIO Code

Files:

```text
uart_mmio.sv
uart_tx.sv
```

Base address:

```text
0x0000_0500
```

## UART Register Map

| Offset | Address | Register | Description |
| --- | --- | --- | --- |
| `0x00` | `0x0000_0500` | `UART_TXDATA` | Write low byte to transmit |
| `0x04` | `0x0000_0504` | `UART_STATUS` | bit 0 = busy, bit 1 = done |
| `0x08` | `0x0000_0508` | `UART_CONTROL` | bit 0 = enable, bit 1 = clear done |
| `0x0C` | `0x0000_050C` | `UART_BAUD_DIV` | Baud divisor |

## Reset Values

On reset:

```text
baud_div_reg = 15
enable_reg = 1
done_latched = 0
```

Default baud behavior:

```text
bit tick = baud_div + 1 clock cycles
```

With default `baud_div = 15`:

```text
1 UART bit = 16 clock cycles
```

## Transmit Flow

The CPU writes a byte to `UART_TXDATA`.

Code behavior:

```systemverilog
if (enable_reg && !tx_busy_o) begin
    tx_data_reg <= write_data_i[7:0];
    tx_start <= 1'b1;
    done_latched <= 1'b0;
end
```

UART frame format:

```text
8-N-1
1 start bit
8 data bits
1 stop bit
```

Total:

```text
10 serial bits per byte
```

## UART Status

Read value:

```text
{30'b0, done_latched, tx_busy_o}
```

Bits:

| Bit | Meaning |
| --- | --- |
| bit 0 | transmitter busy |
| bit 1 | transmit done |

## UART Control

Bits:

| Bit | Meaning |
| --- | --- |
| bit 0 | enable UART |
| bit 1 | clear done flag |

## Baud Divisor Formula

```text
baud_rate = system_clock_frequency / (baud_div + 1)
```

Example for 50 MHz clock and 115200 baud:

```text
baud_div = (50,000,000 / 115,200) - 1
         approximately 433
```

Speaker note:

> UART MMIO is the encrypted output path. The CPU writes ciphertext bytes to
> `UART_TXDATA`. The UART transmitter serializes those bytes on the `uart_tx`
> output pin, while `busy` and `done` flags allow the CPU to know when
> transmission is active or complete.

---

# 8. Interrupt Controller MMIO Code

File:

```text
simple_intc.sv
```

Base address:

```text
0x0000_0600
```

## Interrupt Register Map

| Offset | Address | Register | Description |
| --- | --- | --- | --- |
| `0x00` | `0x0000_0600` | `IRQ_PENDING` | Pending interrupt bits |
| `0x04` | `0x0000_0604` | `IRQ_ENABLE` | Enable bits |
| `0x08` | `0x0000_0608` | `IRQ_CLEAR` | Write 1 to clear pending bits |

## Interrupt Bit Layout

| Bit | Source |
| --- | --- |
| bit 0 | AES done |
| bit 1 | UART TX done |
| bit 2 | Sensor data ready |
| bit 3 | DMA done |

Interrupt sources are packed as:

```systemverilog
assign irq_sources = {
    dma_done_irq_i,
    sensor_data_ready_irq_i,
    uart_tx_done_irq_i,
    aes_done_irq_i
};
```

## Pending Register Behavior

Every cycle:

```systemverilog
pending_reg <= pending_reg | irq_sources;
```

Meaning:

```text
If AES done occurs, IRQ_PENDING[0] becomes 1
If UART done occurs, IRQ_PENDING[1] becomes 1
If sensor ready occurs, IRQ_PENDING[2] becomes 1
If DMA done occurs, IRQ_PENDING[3] becomes 1
```

## Enable Register

Writing to `IRQ_ENABLE` controls which pending interrupts can assert the final
IRQ line.

```systemverilog
OFF_ENABLE: enable_reg <= write_data_i[3:0];
```

## Clear Register

Writing 1s to `IRQ_CLEAR` clears selected pending bits:

```systemverilog
OFF_CLEAR: pending_reg <= (pending_reg | irq_sources) & ~write_data_i[3:0];
```

Example:

```text
write 0x4 to IRQ_CLEAR -> clear sensor-ready pending bit
```

## Combined IRQ Output

```systemverilog
assign irq_o = |(pending_reg & enable_reg);
```

Meaning:

```text
irq_o = 1 if any pending interrupt is also enabled
```

Speaker note:

> The interrupt controller collects event signals from AES, UART, sensor, and
> DMA. Pending bits record events, enable bits select which events can generate
> the combined interrupt, and clear bits allow software to acknowledge handled
> events.

---

# 9. DMA-lite MMIO Code

File:

```text
dma_lite.sv
```

Base address:

```text
0x0000_0700
```

## DMA Register Map

| Offset | Address | Register | Description |
| --- | --- | --- | --- |
| `0x00` | `0x0000_0700` | `DMA_SRC_ADDR` | Source byte address |
| `0x04` | `0x0000_0704` | `DMA_DST_ADDR` | Destination byte address |
| `0x08` | `0x0000_0708` | `DMA_LEN` | Word count |
| `0x0C` | `0x0000_070C` | `DMA_CTRL` | bit 0 = start, bit 1 = clear done |
| `0x10` | `0x0000_0710` | `DMA_STATUS` | bit 0 = busy, bit 1 = done |

## DMA Address Generation

DMA copies words, so address increments by 4 bytes:

```systemverilog
assign dma_read_addr_o  = src_addr_reg + {index_reg[29:0], 2'b00};
assign dma_write_addr_o = dst_addr_reg + {index_reg[29:0], 2'b00};
```

Meaning:

```text
index 0 -> base address
index 1 -> base + 4
index 2 -> base + 8
```

## DMA Start Behavior

Writing `DMA_CTRL[0] = 1` starts DMA if it is not already busy:

```systemverilog
if (write_data_i[0] && !busy_o) begin
    index_reg <= 32'h0;
    busy_o    <= (len_reg != 32'h0);
    done_o    <= (len_reg == 32'h0);
end
```

If length is zero:

```text
busy = 0
done = 1
```

If length is nonzero:

```text
busy = 1
done = 0 until transfer finishes
```

## DMA Copy Behavior

While busy:

```systemverilog
dma_write_en_o = clk_en_i && busy_o;
dma_write_data_o = dma_read_data_i;
```

So each active cycle:

```text
read source word
write destination word
increment index
```

When final word is copied:

```systemverilog
busy_o <= 1'b0;
done_o <= 1'b1;
```

## DMA Status

Read value:

```text
{30'b0, done, busy}
```

Speaker note:

> DMA-lite is a simple word-copy accelerator. The CPU writes source address,
> destination address, length, and start. The DMA then moves one word per cycle
> through a lightweight data-memory port and sets done when complete.

---

# 10. Power / Activity MMIO Code

File:

```text
power_mgmt_mmio.sv
```

Base address:

```text
0x0000_0800
```

## Power Register Map

| Offset | Address | Register | Description |
| --- | --- | --- | --- |
| `0x00` | `0x0000_0800` | `POWER_CTRL` | bit 0 = sleep request, bit 1 = clear counters |
| `0x04` | `0x0000_0804` | `CPU_ACTIVE_CYCLES` | CPU active-cycle count |
| `0x08` | `0x0000_0808` | `AES_ACTIVE_CYCLES` | AES busy-cycle count |
| `0x0C` | `0x0000_080C` | `UART_ACTIVE_CYCLES` | UART busy-cycle count |
| `0x10` | `0x0000_0810` | `SLEEP_CYCLES` | Sleep-cycle count |
| `0x14` | `0x0000_0814` | `DMA_ACTIVE_CYCLES` | DMA busy-cycle count |
| `0x18` | `0x0000_0818` | `SENSOR_ACTIVE_CYCLES` | Sensor active-cycle count |

## POWER_CTRL

Bits:

| Bit | Meaning |
| --- | --- |
| bit 0 | sleep request |
| bit 1 | clear counters |

Writing bit 0:

```systemverilog
sleep_o <= write_data_i[0];
```

Writing bit 1 clears all counters:

```systemverilog
clear_counters = write_en_i && (reg_offset == OFF_CTRL) && write_data_i[1];
```

## Counter Behavior

Counters increment based on activity inputs:

```systemverilog
if (cpu_active_i && !sleep_o) cpu_active_cycles <= cpu_active_cycles + 32'd1;
if (aes_active_i)             aes_active_cycles <= aes_active_cycles + 32'd1;
if (uart_active_i)            uart_active_cycles <= uart_active_cycles + 32'd1;
if (sleep_o)                  sleep_cycles <= sleep_cycles + 32'd1;
if (dma_active_i)             dma_active_cycles <= dma_active_cycles + 32'd1;
if (sensor_active_i)          sensor_active_cycles <= sensor_active_cycles + 32'd1;
```

This allows software/testbench to measure:

```text
How long CPU was active
How long AES was encrypting
How long UART was transmitting
How long DMA was copying
How long sensor interface was active
How long the system was in sleep mode
```

## Activity Debug Output

The debug output combines selected counters:

```systemverilog
activity_counter_debug_o =
    aes_active_cycles ^ uart_active_cycles ^ sleep_cycles ^ dma_active_cycles;
```

Speaker note:

> The power-management MMIO block makes low-power behavior measurable. It does
> not physically gate unsafe clocks. Instead, it tracks activity and sleep time
> using counters, which is useful for comparing polling, DMA, interrupts, and
> custom ISA control overhead.

---

# 11. MMIO Access Examples

## Read Sensor Data

```text
x1 = 0x0000_0400
lw x2, 0(x1)
```

Result:

```text
x2 = SENSOR_DATA
data_ready flag clears after read
```

## Start AES-CTR Encryption

```text
x1 = 0x0000_0300
sw key words to offsets 0x08 to 0x14
sw plaintext words to offsets 0x18 to 0x24
sw nonce to offsets 0x38 and 0x3C
sw counter to offsets 0x40 and 0x44
sw 0x5 to AES_CTRL
```

Why `0x5`?

```text
0x5 = 0b101
bit 0 = start
bit 2 = CTR mode
```

## Poll AES Status

```text
lw x3, 4(x1)
```

Check:

```text
x3[0] = busy
x3[1] = done
x3[2] = CTR mode
```

## Send Ciphertext Through UART

```text
x1 = 0x0000_0500
sw ciphertext_byte, 0(x1)
```

Then poll:

```text
lw status, 4(x1)
```

Check:

```text
status[0] = busy
status[1] = done
```

## Enable Sensor Interrupt

```text
x1 = 0x0000_0600
sw 0x4, 4(x1)
```

Why `0x4`?

```text
0x4 = bit 2
bit 2 = sensor ready interrupt enable
```

## Clear Sensor Interrupt

```text
sw 0x4, 8(x1)
```

## Start DMA

```text
x1 = 0x0000_0700
sw src_addr, 0(x1)
sw dst_addr, 4(x1)
sw length,   8(x1)
sw 0x1,      12(x1)
```

## Enter Sleep Mode

```text
x1 = 0x0000_0800
sw 0x1, 0(x1)
```

Why `0x1`?

```text
POWER_CTRL[0] = sleep request
```

---

# 12. How MMIO Was Verified

The MMIO functionality is verified in:

```text
riscv_core_tb.sv
```

Verification includes:

```text
AES ECB register write/read and ciphertext checks
AES-CTR mode and counter increment checks
Sensor data read check
SPI SCLK and slave-select activity checks
UART done/busy checks
Interrupt pending/enable/IRQ checks
DMA copy and done checks
Power sleep and counter checks
```

Expected final simulation result:

```text
PASS=83 FAIL=0
ALL TESTS PASSED
```

---

# 13. Final Speaker Summary

Use this in viva or presentation:

```text
The MMIO system allows the RISC-V CPU to control all peripherals using normal
load and store instructions. In mem_stage.sv, the effective address is decoded
into AES, sensor/SPI, UART, interrupt controller, DMA-lite, or power-management
regions. Each peripheral has its own local register offsets and returns read
data through a common read-data mux.

AES MMIO controls key, plaintext, nonce, counter, ECB/CTR mode, status, and
ciphertext. Sensor/SPI MMIO provides sensor data and external SPI access. UART
MMIO sends encrypted bytes through the uart_tx pin. The interrupt controller
stores AES, UART, sensor, and DMA events in pending registers. DMA-lite performs
simple word transfers, and power MMIO records activity and sleep cycles.

This MMIO design keeps the RISC-V pipeline mostly unchanged while converting it
into a complete IoT security processor.
```


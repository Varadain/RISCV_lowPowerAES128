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

# 13. Code-Level Explanation Of Each MMIO Block

This section explains the important MMIO code snippets from each module. The
goal is to understand how the CPU address, write data, read data, and control
signals move through the MMIO system.

---

## 13.1 `mem_stage.sv` MMIO Decoder

The MEM stage receives the effective address from the execute stage. This
address is used to decide whether the CPU is accessing normal RAM or a
peripheral.

### Address Select Code

```systemverilog
assign aes_sel    = (eff_addr[31:8] == 24'h000003);
assign sensor_sel = (eff_addr[31:8] == 24'h000004);
assign uart_sel   = (eff_addr[31:8] == 24'h000005);
assign intc_sel   = (eff_addr[31:8] == 24'h000006);
assign dma_sel    = (eff_addr[31:8] == 24'h000007);
assign power_sel  = (eff_addr[31:8] == 24'h000008);
assign mmio_sel   = aes_sel | sensor_sel | uart_sel | intc_sel | dma_sel | power_sel;
```

Explanation:

```text
eff_addr[31:8] compares the upper address bits.
0x0000_0300 to 0x0000_03FF selects AES.
0x0000_0400 to 0x0000_04FF selects sensor/SPI.
0x0000_0500 to 0x0000_05FF selects UART.
0x0000_0600 to 0x0000_06FF selects interrupt controller.
0x0000_0700 to 0x0000_07FF selects DMA.
0x0000_0800 to 0x0000_08FF selects power/activity counters.
```

This gives each peripheral a 256-byte MMIO window.

### Read/Write Enable Code

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

Explanation:

```text
mem_write_i comes from a store instruction.
mem_read_i comes from a load instruction.
The select signal decides which peripheral gets the access.
```

Example:

```text
If CPU executes sw to 0x0000_0500:
uart_sel = 1
mem_write_i = 1
uart_write_en = 1
```

### Data Memory Disable For MMIO

```systemverilog
assign data_mem_read_en  = (mem_read_i | mem_write_i) & ~mmio_sel & ~custom_valid_i;
assign data_mem_write_en = mem_write_i & ~mmio_sel & ~custom_valid_i;
```

Explanation:

```text
If address is MMIO, normal RAM is not selected.
If address is not MMIO, load/store goes to data_mem.sv.
If custom instruction is active, normal memory access is disabled.
```

This prevents RAM and peripherals from responding at the same time.

### Read Data Mux Code

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

Explanation:

```text
For custom instruction -> return custom result.
For AES read -> return AES register data.
For sensor read -> return sensor/SPI register data.
For UART read -> return UART status/config data.
For interrupt read -> return IRQ pending/enable data.
For DMA read -> return DMA register/status data.
For power read -> return activity counter data.
Otherwise -> return normal data memory read data.
```

Speaker note:

> `mem_stage.sv` is the central MMIO interconnect. It decodes the address,
> creates one read/write enable, disables normal RAM during MMIO access, and
> multiplexes the selected peripheral read data back to the CPU.

---

## 13.2 `aes_mmio.sv`

AES MMIO allows the CPU to control the AES accelerator using load/store
instructions.

### Register Offset Code

```systemverilog
localparam logic [7:0] OFF_CTRL   = 8'h00;
localparam logic [7:0] OFF_STATUS = 8'h04;
localparam logic [7:0] OFF_KEY0   = 8'h08;
localparam logic [7:0] OFF_KEY1   = 8'h0C;
localparam logic [7:0] OFF_KEY2   = 8'h10;
localparam logic [7:0] OFF_KEY3   = 8'h14;
localparam logic [7:0] OFF_PT0    = 8'h18;
localparam logic [7:0] OFF_PT1    = 8'h1C;
localparam logic [7:0] OFF_PT2    = 8'h20;
localparam logic [7:0] OFF_PT3    = 8'h24;
localparam logic [7:0] OFF_CT0    = 8'h28;
localparam logic [7:0] OFF_CT1    = 8'h2C;
localparam logic [7:0] OFF_CT2    = 8'h30;
localparam logic [7:0] OFF_CT3    = 8'h34;
localparam logic [7:0] OFF_NONCE0 = 8'h38;
localparam logic [7:0] OFF_NONCE1 = 8'h3C;
localparam logic [7:0] OFF_COUNT0 = 8'h40;
localparam logic [7:0] OFF_COUNT1 = 8'h44;
```

Explanation:

```text
These localparams define internal register offsets.
The base address is decoded in mem_stage.sv.
Inside aes_mmio.sv, only the lower address bits are used.
```

### Internal AES Registers

```systemverilog
logic [127:0] key_reg;
logic [127:0] pt_reg;
logic [127:0] ct_reg;
logic [63:0]  nonce_reg;
logic [63:0]  counter_reg;
logic busy_reg;
logic done_reg;
logic mode_ctr_reg;
```

Explanation:

```text
key_reg stores the 128-bit AES key.
pt_reg stores the 128-bit plaintext block.
ct_reg stores the 128-bit ciphertext block.
nonce_reg and counter_reg are used for AES-CTR mode.
busy_reg tells whether AES is running.
done_reg tells whether AES completed.
mode_ctr_reg selects ECB or CTR mode.
```

### AES Input Block Selection

```systemverilog
assign aes_input_block = mode_ctr_reg ? {nonce_reg, counter_reg} : pt_reg;
```

Explanation:

```text
In ECB mode, AES encrypts plaintext directly.
In CTR mode, AES encrypts nonce || counter to create a keystream.
```

### AES Control Write Code

```systemverilog
OFF_CTRL: begin
    mode_ctr_reg <= write_data_i[2];
    if (write_data_i[0] && !busy_reg) begin
        busy_reg <= 1'b1;
        done_reg <= 1'b0;
    end
    if (write_data_i[1]) begin
        done_reg <= 1'b0;
    end
end
```

Explanation:

```text
write_data_i[0] starts AES.
write_data_i[1] clears the done flag.
write_data_i[2] selects CTR mode.
AES only starts if busy_reg is 0.
```

### AES Key And Plaintext Write Code

```systemverilog
OFF_KEY0:   key_reg[31:0]    <= write_data_i;
OFF_KEY1:   key_reg[63:32]   <= write_data_i;
OFF_KEY2:   key_reg[95:64]   <= write_data_i;
OFF_KEY3:   key_reg[127:96]  <= write_data_i;
OFF_PT0:    pt_reg[31:0]     <= write_data_i;
OFF_PT1:    pt_reg[63:32]    <= write_data_i;
OFF_PT2:    pt_reg[95:64]    <= write_data_i;
OFF_PT3:    pt_reg[127:96]   <= write_data_i;
```

Explanation:

```text
The 128-bit key is written as four 32-bit words.
The 128-bit plaintext is written as four 32-bit words.
This matches a 32-bit RISC-V data path.
```

### AES-CTR Nonce And Counter Write Code

```systemverilog
OFF_NONCE0: nonce_reg[31:0]    <= write_data_i;
OFF_NONCE1: nonce_reg[63:32]   <= write_data_i;
OFF_COUNT0: counter_reg[31:0]  <= write_data_i;
OFF_COUNT1: counter_reg[63:32] <= write_data_i;
```

Explanation:

```text
AES-CTR uses a 64-bit nonce and a 64-bit counter.
Together they form the 128-bit input block for AES encryption.
```

### AES Completion Code

```systemverilog
if (clk_en_i && aes_done && busy_reg) begin
    ct_reg   <= mode_ctr_reg ? (pt_reg ^ aes_ciphertext) : aes_ciphertext;
    busy_reg <= 1'b0;
    done_reg <= 1'b1;
    if (mode_ctr_reg) begin
        counter_reg <= counter_reg + 64'd1;
    end
end
```

Explanation:

```text
When AES core finishes, aes_done becomes 1.
In ECB mode, ciphertext is AES output.
In CTR mode, ciphertext is plaintext XOR AES output.
busy clears after completion.
done sets after completion.
counter increments automatically in CTR mode.
```

### AES Read Code

```systemverilog
OFF_STATUS: read_data_o = {29'h0, mode_ctr_reg, done_reg, busy_reg};
OFF_CT0:    read_data_o = ct_reg[31:0];
OFF_CT1:    read_data_o = ct_reg[63:32];
OFF_CT2:    read_data_o = ct_reg[95:64];
OFF_CT3:    read_data_o = ct_reg[127:96];
```

Explanation:

```text
CPU reads STATUS to check busy/done.
CPU reads CT0 to CT3 to get the 128-bit ciphertext.
```

---

## 13.3 `sensor_mmio.sv`

This is the simple sensor MMIO model. It is useful for simulation and demo
without needing real SPI/I2C hardware.

### Register Offset Code

```systemverilog
localparam logic [5:0] OFF_DATA    = 6'h00;
localparam logic [5:0] OFF_STATUS  = 6'h04;
localparam logic [5:0] OFF_CONTROL = 6'h08;
```

Explanation:

```text
0x00 is sensor data.
0x04 is sensor status.
0x08 is sensor control.
```

### Reset Code

```systemverilog
sensor_data_reg <= 32'h1234_5678;
data_ready_reg  <= 1'b1;
enable_reg      <= 1'b1;
sample_tick     <= 8'h0;
```

Explanation:

```text
After reset, the sensor has a default sample value.
data_ready is set, so the CPU can immediately read a sample.
enable is set, so the sample generator is active.
```

### Sample Update Code

```systemverilog
if (enable_reg) begin
    sample_tick <= sample_tick + 8'd1;
    if (sample_tick == 8'hff) begin
        sensor_data_reg <= sensor_data_reg + 32'h0001_0101;
        data_ready_reg  <= 1'b1;
    end
end
```

Explanation:

```text
This creates a changing sensor value for simulation.
Every time sample_tick reaches 0xFF, sensor data changes.
data_ready becomes 1 to show that a new sample is available.
```

### Sensor Write Code

```systemverilog
OFF_DATA: sensor_data_reg <= write_data_i;
OFF_CONTROL: begin
    enable_reg <= write_data_i[0];
    if (write_data_i[1]) begin
        data_ready_reg <= 1'b0;
    end
end
```

Explanation:

```text
Writing SENSOR_DATA allows test/demo injection of a sample.
CONTROL[0] enables or disables the sensor.
CONTROL[1] clears the data_ready flag.
```

### Sensor Read Code

```systemverilog
OFF_DATA:    read_data_o = sensor_data_reg;
OFF_STATUS:  read_data_o = {31'h0, data_ready_reg};
OFF_CONTROL: read_data_o = {31'h0, enable_reg};
```

Explanation:

```text
Reading DATA returns the sensor sample.
Reading STATUS returns the data_ready bit.
Reading CONTROL returns the enable bit.
```

### Clear-On-Read Code

```systemverilog
if (read_en_i && (reg_offset == OFF_DATA)) begin
    data_ready_reg <= 1'b0;
end
```

Explanation:

```text
When CPU reads sensor data, the ready flag clears automatically.
This models that the current sample has been consumed.
```

---

## 13.4 `sensor_spi_mmio.sv`

This module extends the simple sensor MMIO model with an SPI register window.

### Sensor And SPI Offset Code

```systemverilog
localparam logic [5:0] OFF_DATA       = 6'h00;
localparam logic [5:0] OFF_STATUS     = 6'h04;
localparam logic [5:0] OFF_CONTROL    = 6'h08;
localparam logic [5:0] OFF_SPI_RXDATA = 6'h10;
localparam logic [5:0] OFF_SPI_TXDATA = 6'h14;
localparam logic [5:0] OFF_SPI_STATUS = 6'h18;
localparam logic [5:0] OFF_SPI_CTRL   = 6'h1c;
localparam logic [5:0] OFF_SPI_SS     = 6'h24;
```

Explanation:

```text
0x00 to 0x08 are simple sensor registers.
0x10 to 0x24 are SPI IP registers.
Both live inside the 0x0000_0400 MMIO window.
```

### SPI Register Select Code

```systemverilog
always_comb begin
    spi_reg_sel = 1'b0;
    spi_addr    = 3'd0;
    case (reg_offset)
        OFF_SPI_RXDATA: begin
            spi_reg_sel = 1'b1;
            spi_addr    = 3'd0;
        end
        OFF_SPI_TXDATA: begin
            spi_reg_sel = 1'b1;
            spi_addr    = 3'd1;
        end
        OFF_SPI_STATUS: begin
            spi_reg_sel = 1'b1;
            spi_addr    = 3'd2;
        end
        OFF_SPI_CTRL: begin
            spi_reg_sel = 1'b1;
            spi_addr    = 3'd3;
        end
        OFF_SPI_SS: begin
            spi_reg_sel = 1'b1;
            spi_addr    = 3'd5;
        end
        default: ;
    endcase
end
```

Explanation:

```text
If the CPU accesses an SPI offset, spi_reg_sel becomes 1.
The MMIO offset is translated into the SPI IP internal address.
```

### SPI IP Connection Code

```systemverilog
sensor_spi_ip u_sensor_spi_ip (
    .clk          (clk),
    .reset_n      (rst_n),
    .spi_select   (spi_reg_sel & clk_en_i),
    .mem_addr     (spi_addr),
    .data_from_cpu(write_data_i[15:0]),
    .read_n       (~(read_en_i  & spi_reg_sel & clk_en_i)),
    .write_n      (~(write_en_i & spi_reg_sel & clk_en_i)),
    .MISO         (spi_miso_i),
    .MOSI         (spi_mosi_o),
    .SCLK         (spi_sclk_o),
    .SS_n         (spi_ss_n_o),
    .data_to_cpu  (spi_data_to_cpu),
    .irq          (spi_irq),
    .readyfordata (spi_readyfordata)
);
```

Explanation:

```text
The CPU's MMIO read/write is converted to SPI IP read/write signals.
read_n and write_n are active-low because the SPI IP expects active-low controls.
MISO, MOSI, SCLK, and SS_n are the actual SPI pins.
```

### SPI Dataavailable Code

```systemverilog
if (spi_dataavailable) begin
    sensor_data_reg <= {24'h0, spi_data_to_cpu[7:0]};
    data_ready_reg  <= 1'b1;
end
```

Explanation:

```text
When SPI receives data, the lower 8 bits are copied into SENSOR_DATA.
data_ready becomes 1, so the CPU knows new sensor data is available.
```

---

## 13.5 `uart_mmio.sv`

UART MMIO lets the CPU send encrypted bytes through the `uart_tx` pin.

### Register Offset Code

```systemverilog
localparam logic [5:0] OFF_TXDATA   = 6'h00;
localparam logic [5:0] OFF_STATUS   = 6'h04;
localparam logic [5:0] OFF_CONTROL  = 6'h08;
localparam logic [5:0] OFF_BAUD_DIV = 6'h0C;
```

Explanation:

```text
TXDATA starts transmission.
STATUS reports busy/done.
CONTROL enables UART and clears done.
BAUD_DIV controls transmission speed.
```

### Reset Code

```systemverilog
baud_div_reg   <= 16'd15;
enable_reg     <= 1'b1;
done_latched   <= 1'b0;
```

Explanation:

```text
UART starts enabled.
Default baud divisor is 15.
done flag starts cleared.
```

### TXDATA Write Code

```systemverilog
OFF_TXDATA: begin
    tx_data_reg <= write_data_i[7:0];
    if (enable_reg && !tx_busy_o) begin
        tx_start       <= 1'b1;
        done_latched   <= 1'b0;
    end
end
```

Explanation:

```text
CPU writes the low byte to transmit.
If UART is enabled and idle, tx_start pulses.
done_latched clears because a new transfer has started.
```

### Control Write Code

```systemverilog
OFF_CONTROL: begin
    enable_reg <= write_data_i[0];
    if (write_data_i[1]) begin
        done_latched <= 1'b0;
    end
end
```

Explanation:

```text
CONTROL[0] enables UART.
CONTROL[1] clears the done flag.
```

### Baud Divisor Code

```systemverilog
OFF_BAUD_DIV: baud_div_reg <= write_data_i[15:0];
```

Explanation:

```text
CPU can program UART speed.
One UART bit lasts baud_div + 1 clock cycles.
```

### UART Read Code

```systemverilog
OFF_TXDATA:   read_data_o = {24'h0, tx_data_reg};
OFF_STATUS:   read_data_o = {30'h0, done_latched, tx_busy_o};
OFF_CONTROL:  read_data_o = {31'h0, enable_reg};
OFF_BAUD_DIV: read_data_o = {16'h0, baud_div_reg};
```

Explanation:

```text
CPU can read last TX byte.
CPU can check busy/done status.
CPU can read enable state.
CPU can read configured baud divisor.
```

### UART Transmitter Instance

```systemverilog
uart_tx u_uart_tx (
    .clk       (clk),
    .rst_n     (rst_n),
    .clk_en_i  (clk_en_i),
    .start_i   (tx_start),
    .data_i    (tx_data_reg),
    .baud_div_i(baud_div_reg),
    .tx_o      (uart_tx_o),
    .busy_o    (tx_busy_o),
    .done_o    (tx_done_pulse)
);
```

Explanation:

```text
uart_mmio stores register values.
uart_tx performs actual serial transmission.
tx_done_pulse is latched into done_latched for CPU visibility.
```

---

## 13.6 `uart_tx.sv`

This module is not an MMIO register file by itself, but it is the UART engine
controlled by `uart_mmio.sv`.

### Start Code

```systemverilog
if (start_i && !busy_o) begin
    shifter    <= {1'b1, data_i, 1'b0}; // stop, data, start
    bit_count  <= 4'd10;
    baud_count <= baud_div_i;
    busy_o     <= 1'b1;
    tx_o       <= 1'b0;
end
```

Explanation:

```text
UART frame has 10 bits: start + 8 data + stop.
Start bit is 0.
Stop bit is 1.
Data is shifted serially.
```

### Baud Counter Code

```systemverilog
if (baud_count != 16'd0) begin
    baud_count <= baud_count - 16'd1;
end else begin
    baud_count <= baud_div_i;
    shifter    <= {1'b1, shifter[9:1]};
    bit_count  <= bit_count - 4'd1;
end
```

Explanation:

```text
baud_count controls how long each serial bit remains on uart_tx.
When baud_count reaches zero, the next bit is shifted out.
```

### Done Code

```systemverilog
if (bit_count == 4'd1) begin
    busy_o <= 1'b0;
    done_o <= 1'b1;
end
```

Explanation:

```text
After all 10 bits are transmitted, busy clears and done pulses.
```

---

## 13.7 `simple_intc.sv`

The interrupt controller stores peripheral events and produces one combined IRQ.

### Register Offset Code

```systemverilog
localparam logic [5:0] OFF_PENDING = 6'h00;
localparam logic [5:0] OFF_ENABLE  = 6'h04;
localparam logic [5:0] OFF_CLEAR   = 6'h08;
```

Explanation:

```text
PENDING shows which events occurred.
ENABLE selects which events can raise irq_o.
CLEAR clears selected pending bits.
```

### IRQ Source Packing

```systemverilog
assign irq_sources = {
    dma_done_irq_i,
    sensor_data_ready_irq_i,
    uart_tx_done_irq_i,
    aes_done_irq_i
};
```

Explanation:

```text
bit 0 = AES done
bit 1 = UART done
bit 2 = sensor ready
bit 3 = DMA done
```

### Pending And Enable Code

```systemverilog
pending_reg <= pending_reg | irq_sources;

if (write_en_i) begin
    case (reg_offset)
        OFF_ENABLE: enable_reg <= write_data_i[3:0];
        OFF_CLEAR:  pending_reg <= (pending_reg | irq_sources) & ~write_data_i[3:0];
        default: ;
    endcase
end
```

Explanation:

```text
Any interrupt source sets its pending bit.
Writing ENABLE changes which sources are allowed.
Writing CLEAR with 1s clears selected pending bits.
```

### Combined IRQ Code

```systemverilog
assign irq_o = |(pending_reg & enable_reg);
```

Explanation:

```text
If a bit is both pending and enabled, irq_o becomes 1.
```

### Read Code

```systemverilog
OFF_PENDING: read_data_o = {28'h0, pending_reg};
OFF_ENABLE:  read_data_o = {28'h0, enable_reg};
```

Explanation:

```text
CPU reads PENDING to know which event occurred.
CPU reads ENABLE to know which events are enabled.
```

---

## 13.8 `dma_lite.sv`

DMA-lite copies words through a lightweight memory port.

### Register Offset Code

```systemverilog
localparam logic [5:0] OFF_SRC    = 6'h00;
localparam logic [5:0] OFF_DST    = 6'h04;
localparam logic [5:0] OFF_LEN    = 6'h08;
localparam logic [5:0] OFF_CTRL   = 6'h0C;
localparam logic [5:0] OFF_STATUS = 6'h10;
```

Explanation:

```text
SRC stores source address.
DST stores destination address.
LEN stores number of words.
CTRL starts DMA or clears done.
STATUS reports busy/done.
```

### DMA Address Code

```systemverilog
assign dma_read_addr_o  = src_addr_reg + {index_reg[29:0], 2'b00};
assign dma_write_addr_o = dst_addr_reg + {index_reg[29:0], 2'b00};
assign dma_write_data_o = dma_read_data_i;
assign dma_write_en_o   = clk_en_i && busy_o;
```

Explanation:

```text
DMA copies word by word.
Each word address increments by 4 bytes.
Read data is directly written to destination.
Write enable is active while DMA is busy.
```

### DMA Register Write Code

```systemverilog
OFF_SRC: src_addr_reg <= write_data_i;
OFF_DST: dst_addr_reg <= write_data_i;
OFF_LEN: len_reg      <= write_data_i;
OFF_CTRL: begin
    if (write_data_i[1]) begin
        done_o <= 1'b0;
    end
    if (write_data_i[0] && !busy_o) begin
        index_reg <= 32'h0;
        busy_o    <= (len_reg != 32'h0);
        done_o    <= (len_reg == 32'h0);
    end
end
```

Explanation:

```text
CPU programs source, destination, and length.
CTRL[0] starts DMA.
CTRL[1] clears done.
If length is zero, DMA immediately reports done.
```

### DMA Progress Code

```systemverilog
if (busy_o) begin
    if (index_reg + 32'd1 >= len_reg) begin
        busy_o <= 1'b0;
        done_o <= 1'b1;
    end
    index_reg <= index_reg + 32'd1;
end
```

Explanation:

```text
Each cycle, DMA transfers one word and increments index.
When final word is transferred, busy clears and done sets.
```

### DMA Read Code

```systemverilog
OFF_SRC:    read_data_o = src_addr_reg;
OFF_DST:    read_data_o = dst_addr_reg;
OFF_LEN:    read_data_o = len_reg;
OFF_STATUS: read_data_o = {30'h0, done_o, busy_o};
```

Explanation:

```text
CPU can read programmed addresses, length, and status.
STATUS[0] is busy.
STATUS[1] is done.
```

---

## 13.9 `power_mgmt_mmio.sv`

This MMIO block controls sleep request and records activity counters.

### Register Offset Code

```systemverilog
localparam logic [5:0] OFF_CTRL   = 6'h00;
localparam logic [5:0] OFF_CPU    = 6'h04;
localparam logic [5:0] OFF_AES    = 6'h08;
localparam logic [5:0] OFF_UART   = 6'h0C;
localparam logic [5:0] OFF_SLEEP  = 6'h10;
localparam logic [5:0] OFF_DMA    = 6'h14;
localparam logic [5:0] OFF_SENSOR = 6'h18;
```

Explanation:

```text
CTRL controls sleep and counter clear.
Other offsets expose activity counters.
```

### Control And Clear Code

```systemverilog
assign clear_counters = write_en_i && (reg_offset == OFF_CTRL) && write_data_i[1];

if (write_en_i && (reg_offset == OFF_CTRL)) begin
    sleep_o <= write_data_i[0];
end
```

Explanation:

```text
POWER_CTRL[0] sets sleep request.
POWER_CTRL[1] clears all counters.
```

### Counter Increment Code

```systemverilog
if (clear_counters) begin
    cpu_active_cycles    <= 32'h0;
    aes_active_cycles    <= 32'h0;
    uart_active_cycles   <= 32'h0;
    sleep_cycles         <= 32'h0;
    dma_active_cycles    <= 32'h0;
    sensor_active_cycles <= 32'h0;
end else begin
    if (cpu_active_i && !sleep_o) cpu_active_cycles <= cpu_active_cycles + 32'd1;
    if (aes_active_i)             aes_active_cycles <= aes_active_cycles + 32'd1;
    if (uart_active_i)            uart_active_cycles <= uart_active_cycles + 32'd1;
    if (sleep_o)                  sleep_cycles <= sleep_cycles + 32'd1;
    if (dma_active_i)             dma_active_cycles <= dma_active_cycles + 32'd1;
    if (sensor_active_i)          sensor_active_cycles <= sensor_active_cycles + 32'd1;
end
```

Explanation:

```text
When clear is written, all counters reset to zero.
Otherwise each counter increments when its activity input is high.
CPU active counter does not increment during sleep.
Sleep counter increments when sleep_o is set.
```

### Power Read Code

```systemverilog
OFF_CTRL:   read_data_o = {31'h0, sleep_o};
OFF_CPU:    read_data_o = cpu_active_cycles;
OFF_AES:    read_data_o = aes_active_cycles;
OFF_UART:   read_data_o = uart_active_cycles;
OFF_SLEEP:  read_data_o = sleep_cycles;
OFF_DMA:    read_data_o = dma_active_cycles;
OFF_SENSOR: read_data_o = sensor_active_cycles;
```

Explanation:

```text
CPU can read sleep status and each activity counter.
These values help compare MMIO, custom ISA, DMA, interrupt, and sleep behavior.
```

### Debug Counter Code

```systemverilog
assign activity_counter_debug_o =
    aes_active_cycles ^ uart_active_cycles ^ sleep_cycles ^ dma_active_cycles;
```

Explanation:

```text
This creates an observable debug value from internal counters.
It helps keep activity-counter logic visible at the top level.
```

---

## 13.10 Common MMIO Coding Pattern

All MMIO modules follow the same basic structure.

### 1. Define Register Offsets

```systemverilog
localparam logic [5:0] OFF_STATUS = 6'h04;
```

Purpose:

```text
Gives each register a fixed offset inside the peripheral window.
```

### 2. Extract Lower Address Bits

```systemverilog
assign reg_offset = addr_i[5:0];
```

Purpose:

```text
The top-level decoder selects the peripheral.
The local module uses lower bits to select the internal register.
```

### 3. Sequential Write Logic

```systemverilog
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // reset registers
    end else if (clk_en_i) begin
        if (write_en_i) begin
            case (reg_offset)
                // update selected register
            endcase
        end
    end
end
```

Purpose:

```text
Writes change internal registers only on clock edges.
Reset gives known initial values.
Clock enable supports low-power style activity control.
```

### 4. Combinational Read Logic

```systemverilog
always_comb begin
    read_data_o = 32'h0;
    if (read_en_i) begin
        case (reg_offset)
            // return selected register
            default: read_data_o = 32'h0;
        endcase
    end
end
```

Purpose:

```text
Loads return the selected register value.
Unmapped offsets return zero.
```

### 5. Status And IRQ Outputs

```systemverilog
assign active_o = busy_o;
assign done_irq_o = done_o;
```

Purpose:

```text
Peripheral status can feed power counters and interrupt controller.
```

Speaker note:

> Every MMIO module uses the same clean pattern: fixed offsets, local register
> decode, clocked writes, combinational reads, status outputs, and optional
> interrupt/activity outputs. This makes the design modular and easy to extend.

---

# 14. Final Speaker Summary

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

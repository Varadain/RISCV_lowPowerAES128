# Interrupt and Power-Management RTL: In-Depth Code Walkthrough

## Purpose

This document explains why the Lightweight RISC-V IoT Security Processor contains:

- `simple_intc.sv`, the interrupt controller;
- `power_mgmt_mmio.sv`, the sleep and activity-monitoring block.

It follows the exact SystemVerilog code and also shows how the testbench verifies the behavior.

The simple reason is:

```text
Interrupt controller:
Remember peripheral completion events so that software does not miss them.

Power-management block:
Reduce unnecessary peripheral activity and measure active and sleep cycles.
```

AES encryption can work without these modules. They are present because the thesis implements a small security SoC, not only an AES core.

> Line numbers refer to the current RTL revision. They may move if code is added above the referenced blocks.

---

## 1. Why Peripheral Events Are Needed

AES, UART, DMA and SPI do not finish in the same cycle in which the CPU starts them.

For example:

```text
CPU writes AES START
        |
        v
AES becomes busy
        |
        | many clock cycles
        v
AES produces a completion event
```

The same behavior occurs for UART transmission and DMA transfer.

Without an event controller, software must repeatedly read status:

```text
read status
if not done, read status again
if not done, read status again
...
```

This is polling. Polling is valid, but it keeps the CPU active and may waste cycles.

An interrupt controller provides three useful functions:

1. It remembers short completion events.
2. It lets software choose which events are important.
3. It combines several event sources into one output line.

---

# Part I: Interrupt Controller

## 2. Interrupt-Controller MMIO Map

The interrupt controller is located at base address `0x0000_0600`.

Source: [`simple_intc.sv`, lines 1-12](simple_intc.sv#L1-L12)

```systemverilog
// Base address: 0x0000_0600
//   0x00 IRQ_PENDING [0] AES, [1] UART TX done,
//                    [2] sensor ready, [3] DMA done
//   0x04 IRQ_ENABLE  same bit layout
//   0x08 IRQ_CLEAR   write 1 to clear pending bits
```

The absolute addresses are:

| Register | Address | Purpose |
|---|---:|---|
| `IRQ_PENDING` | `0x0000_0600` | Shows remembered events. |
| `IRQ_ENABLE` | `0x0000_0604` | Selects events that may assert `irq_o`. |
| `IRQ_CLEAR` | `0x0000_0608` | Clears selected pending bits. |

The bit assignment is:

| Bit | Source |
|---:|---|
| 0 | AES completed |
| 1 | UART transmission completed |
| 2 | Sensor data became ready |
| 3 | DMA transfer completed |

---

## 3. Interrupt-Controller Interface

Source: [`simple_intc.sv`, lines 13-27](simple_intc.sv#L13-L27)

```systemverilog
module simple_intc (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        clk_en_i,
    input  logic [31:0] addr_i,
    input  logic [31:0] write_data_i,
    input  logic        write_en_i,
    input  logic        read_en_i,
    input  logic        aes_done_irq_i,
    input  logic        uart_tx_done_irq_i,
    input  logic        sensor_data_ready_irq_i,
    input  logic        dma_done_irq_i,
    output logic [31:0] read_data_o,
    output logic        irq_o
);
```

### Interface meaning

| Port | Meaning |
|---|---|
| `addr_i` | CPU MMIO address. |
| `write_data_i` | Value written by the CPU. |
| `write_en_i` | CPU is writing an interrupt register. |
| `read_en_i` | CPU is reading an interrupt register. |
| `aes_done_irq_i` | AES completion event. |
| `uart_tx_done_irq_i` | UART completion event. |
| `sensor_data_ready_irq_i` | Sensor-ready event. |
| `dma_done_irq_i` | DMA completion event. |
| `read_data_o` | Pending or enable register returned to the CPU. |
| `irq_o` | Combined enabled interrupt indication. |

---

## 4. Internal Interrupt Registers

Source: [`simple_intc.sv`, lines 29-38](simple_intc.sv#L29-L38)

```systemverilog
localparam logic [5:0] OFF_PENDING = 6'h00;
localparam logic [5:0] OFF_ENABLE  = 6'h04;
localparam logic [5:0] OFF_CLEAR   = 6'h08;

logic [5:0] reg_offset;
logic [3:0] pending_reg;
logic [3:0] enable_reg;
logic [3:0] irq_sources;
```

| Register | Function |
|---|---|
| `pending_reg` | Remembers which events occurred. |
| `enable_reg` | Selects which pending events may assert `irq_o`. |
| `irq_sources` | Current raw event values from the peripherals. |

`pending_reg` and `enable_reg` are four bits because the design currently has four interrupt sources.

---

## 5. Combining Peripheral Events

Source: [`simple_intc.sv`, lines 40-47](simple_intc.sv#L40-L47)

```systemverilog
assign reg_offset = addr_i[5:0];

assign irq_sources = {
    dma_done_irq_i,
    sensor_data_ready_irq_i,
    uart_tx_done_irq_i,
    aes_done_irq_i
};
```

The concatenation creates this vector:

```text
irq_sources[3] = DMA done
irq_sources[2] = sensor ready
irq_sources[1] = UART done
irq_sources[0] = AES done
```

This ordering matches the documented software register map.

---

## 6. Sticky Pending Bits

Peripheral events may be short. A one-cycle event could disappear before software reads it.

The interrupt controller makes events sticky.

Source: [`simple_intc.sv`, lines 51-59](simple_intc.sv#L51-L59)

```systemverilog
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pending_reg <= 4'h0;
        enable_reg  <= 4'h0;
    end else if (clk_en_i) begin
        pending_reg <= pending_reg | irq_sources;
```

The OR operation means:

```text
old pending bit = 0, new event = 0 -> pending remains 0
old pending bit = 0, new event = 1 -> pending becomes 1
old pending bit = 1, new event = 0 -> pending remains 1
old pending bit = 1, new event = 1 -> pending remains 1
```

Once set, a pending bit remains set until software clears it.

### Example

```text
Cycle 100: aes_done_irq_i = 1
Cycle 101: aes_done_irq_i = 0

pending_reg[0] remains 1 after cycle 101.
```

The CPU can therefore read the event later without losing it.

---

## 7. Interrupt Enable Register

Source: [`simple_intc.sv`, lines 60-65](simple_intc.sv#L60-L65)

```systemverilog
if (write_en_i) begin
    case (reg_offset)
        OFF_ENABLE: enable_reg <= write_data_i[3:0];
```

Writing `0xF` to `0x604` enables all four sources:

```text
enable_reg = 4'b1111
```

Writing `0x1` enables only AES:

```text
enable_reg = 4'b0001
```

An event can still be stored in `pending_reg` even when its enable bit is zero. The enable bit only controls the combined `irq_o` output.

---

## 8. Write-One-to-Clear Behavior

Source: [`simple_intc.sv`, lines 66-69](simple_intc.sv#L66-L69)

```systemverilog
OFF_CLEAR:
    pending_reg <= (pending_reg | irq_sources)
                   & ~write_data_i[3:0];
```

This is called write-one-to-clear.

Examples:

```text
write 0x1 -> clear AES pending bit
write 0x2 -> clear UART pending bit
write 0x4 -> clear sensor pending bit
write 0x8 -> clear DMA pending bit
write 0xF -> clear all four pending bits
```

The expression first includes any event arriving in the same clock cycle. It then clears the bits selected by `write_data_i`.

This gives deterministic behavior when an event and a clear operation occur together.

---

## 9. Combined Interrupt Output

Source: [`simple_intc.sv`, lines 48-49](simple_intc.sv#L48-L49)

```systemverilog
assign irq_o = |(pending_reg & enable_reg);
```

This expression has two operations.

### Step 1: AND pending with enable

```text
pending_reg = 0101
enable_reg  = 0011
             ----
result      = 0001
```

Only pending sources that are enabled remain one.

### Step 2: Reduction OR

The `|` before the brackets means:

```text
irq_o = result[3] OR result[2] OR result[1] OR result[0]
```

If at least one enabled event is pending, `irq_o` becomes one.

---

## 10. CPU Readback

Source: [`simple_intc.sv`, lines 75-84](simple_intc.sv#L75-L84)

```systemverilog
always_comb begin
    read_data_o = 32'h0;
    if (read_en_i) begin
        case (reg_offset)
            OFF_PENDING: read_data_o = {28'h0, pending_reg};
            OFF_ENABLE:  read_data_o = {28'h0, enable_reg};
            default:     read_data_o = 32'h0;
        endcase
    end
end
```

The internal registers are four bits, but the CPU read bus is 32 bits. The upper 28 bits are therefore filled with zeros.

```text
CPU reads 0x600 -> {28'b0, pending_reg}
CPU reads 0x604 -> {28'b0, enable_reg}
```

---

## 11. Exact Peripheral Event Sources

### AES event

Source: [`aes_mmio.sv`, lines 101-106](aes_mmio.sv#L101-L106)

```systemverilog
assign aes_done_irq_o = done_reg;
assign active_o       = busy_reg;
```

AES interrupt becomes active when its sticky `done_reg` is set.

### UART event

Source: [`uart_mmio.sv`, lines 47-48](uart_mmio.sv#L47-L48)

```systemverilog
assign tx_done_irq_o = done_latched;
assign active_o      = tx_busy_o;
```

UART interrupt is produced after the transmitted byte completes.

### Sensor event

Source: [`sensor_spi_mmio.sv`, lines 61-62](sensor_spi_mmio.sv#L61-L62)

```systemverilog
assign data_ready_irq_o = data_ready_reg;
assign active_o         = enable_reg | spi_reg_sel;
```

The sensor event indicates that readable sensor data is available.

### DMA event

Source: [`dma_lite.sv`, lines 56-57](dma_lite.sv#L56-L57)

```systemverilog
assign done_irq_o = done_o;
assign active_o   = busy_o;
```

DMA interrupt indicates that the requested transfer has completed.

---

## 12. Interrupt Integration in the MEM Stage

Source: [`mem_stage.sv`, lines 223-239](mem_stage.sv#L223-L239)

```systemverilog
simple_intc u_simple_intc (
    .clk                    (clk),
    .rst_n                  (rst_n),
    .clk_en_i               (1'b1),
    .addr_i                 (eff_addr),
    .write_data_i           (write_data_i),
    .write_en_i             (intc_write_en),
    .read_en_i              (intc_read_en),
    .aes_done_irq_i         (aes_done_irq),
    .uart_tx_done_irq_i     (uart_done_irq),
    .sensor_data_ready_irq_i(sensor_ready_irq),
    .dma_done_irq_i         (dma_done_irq),
    .read_data_o            (intc_read_data),
    .irq_o                  (irq_o)
);
```

The interrupt controller stays enabled even when `sleep_o` is one:

```systemverilog
.clk_en_i(1'b1)
```

This is intentional. A sleeping or idle system must not lose an incoming event.

In a future processor, `irq_o` can participate in wake-up and trap handling.

---

## 13. Top-Level Interrupt Debug Output

Source: [`riscv_aes_advancements.sv`, lines 494-496](riscv_aes_advancements.sv#L494-L496)

```systemverilog
assign irq_debug              = irq_mem;
assign sleep_debug            = sleep_mem;
assign activity_counter_debug = activity_counter_mem;
```

The top-level `irq_debug` output keeps the interrupt result observable in simulation and FPGA synthesis.

### Current limitation

The CPU does not yet implement complete RISC-V privileged interrupt support such as:

- machine interrupt enable CSRs;
- trap vector selection;
- program-counter save and restore;
- `mret` return handling;
- hardware wake from `WFI`.

Therefore, `irq_o` is currently an event/debug output. Software can still read `IRQ_PENDING`, but a full automatic interrupt-service routine is future work.

---

## 14. Complete AES Interrupt Example

```text
1. CPU writes 0x1 to IRQ_ENABLE at 0x604.
   enable_reg = 0001, so AES is enabled.

2. CPU programs AES key, plaintext, nonce and counter.

3. CPU starts AES.
   AES busy_reg becomes 1.

4. AES finishes.
   aes_mmio.done_reg becomes 1.

5. aes_done_irq_o becomes 1.

6. simple_intc receives irq_sources[0] = 1.

7. pending_reg[0] becomes 1 and remains sticky.

8. irq_o becomes 1 because:
   pending_reg[0] = 1 and enable_reg[0] = 1.

9. CPU reads 0x600 and observes bit 0.

10. CPU writes 0x1 to 0x608.
    pending_reg[0] is cleared.
```

---

# Part II: Power and Activity Management

## 15. Why a Power-Management Block Is Included

The thesis describes a lightweight low-power security processor. A useful low-power study needs more than an AES result. It should also answer:

- How many cycles was the CPU considered active?
- How many cycles was AES busy?
- How long was UART transmitting?
- How long was DMA active?
- How long was the sensor interface active?
- How many cycles were counted as sleep?

`power_mgmt_mmio.sv` provides this system-level activity evidence.

It also produces a software-controlled `sleep_o` signal. This signal is used as a clock enable for selected peripherals.

The module does not measure watts directly.

---

## 16. Power-Management MMIO Map

Source: [`power_mgmt_mmio.sv`, lines 1-16](power_mgmt_mmio.sv#L1-L16)

```systemverilog
// Base address: 0x0000_0800
//   0x00 POWER_CTRL          [0] sleep_request, [1] clear counters
//   0x04 CPU_ACTIVE_CYCLES
//   0x08 AES_ACTIVE_CYCLES
//   0x0C UART_ACTIVE_CYCLES
//   0x10 SLEEP_CYCLES
//   0x14 DMA_ACTIVE_CYCLES
//   0x18 SENSOR_ACTIVE_CYCLES
```

The absolute addresses are:

| Register | Address | Purpose |
|---|---:|---|
| `POWER_CTRL` | `0x0800` | Sleep request and counter clear. |
| `CPU_ACTIVE_CYCLES` | `0x0804` | CPU active-cycle count. |
| `AES_ACTIVE_CYCLES` | `0x0808` | AES busy-cycle count. |
| `UART_ACTIVE_CYCLES` | `0x080C` | UART busy-cycle count. |
| `SLEEP_CYCLES` | `0x0810` | Sleep-state cycle count. |
| `DMA_ACTIVE_CYCLES` | `0x0814` | DMA busy-cycle count. |
| `SENSOR_ACTIVE_CYCLES` | `0x0818` | Sensor/SPI active-cycle count. |

---

## 17. Power-Management Interface

Source: [`power_mgmt_mmio.sv`, lines 17-32](power_mgmt_mmio.sv#L17-L32)

```systemverilog
module power_mgmt_mmio (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [31:0] addr_i,
    input  logic [31:0] write_data_i,
    input  logic        write_en_i,
    input  logic        read_en_i,
    input  logic        cpu_active_i,
    input  logic        aes_active_i,
    input  logic        uart_active_i,
    input  logic        dma_active_i,
    input  logic        sensor_active_i,
    output logic [31:0] read_data_o,
    output logic        sleep_o,
    output logic [31:0] activity_counter_debug_o
);
```

Each `*_active_i` input tells the block whether one subsystem is active in the current cycle.

---

## 18. Internal Cycle Counters

Source: [`power_mgmt_mmio.sv`, lines 34-51](power_mgmt_mmio.sv#L34-L51)

```systemverilog
localparam logic [5:0] OFF_CTRL   = 6'h00;
localparam logic [5:0] OFF_CPU    = 6'h04;
localparam logic [5:0] OFF_AES    = 6'h08;
localparam logic [5:0] OFF_UART   = 6'h0C;
localparam logic [5:0] OFF_SLEEP  = 6'h10;
localparam logic [5:0] OFF_DMA    = 6'h14;
localparam logic [5:0] OFF_SENSOR = 6'h18;

logic [31:0] cpu_active_cycles;
logic [31:0] aes_active_cycles;
logic [31:0] uart_active_cycles;
logic [31:0] sleep_cycles;
logic [31:0] dma_active_cycles;
logic [31:0] sensor_active_cycles;
```

Every counter is 32 bits wide. At one count per clock, the maximum measurable duration depends on the clock frequency.

At 50 MHz:

```text
maximum time before wraparound
= (2^32 - 1) / 50,000,000
approximately 85.9 seconds
```

Longer experiments would require wider counters or software accumulation.

---

## 19. Debug Activity Value

Source: [`power_mgmt_mmio.sv`, lines 53-58](power_mgmt_mmio.sv#L53-L58)

```systemverilog
assign activity_counter_debug_o =
       aes_active_cycles
     ^ uart_active_cycles
     ^ sleep_cycles
     ^ dma_active_cycles;

assign clear_counters = write_en_i
                     && (reg_offset == OFF_CTRL)
                     && write_data_i[1];
```

The debug output is an XOR of selected counters. It is not a total and is not a power measurement.

Its purpose is to provide one changing top-level signal so that synthesis tools preserve observable activity logic.

Individual exact counter values remain available through MMIO.

---

## 20. Sleep Request

Source: [`power_mgmt_mmio.sv`, lines 60-74](power_mgmt_mmio.sv#L60-L74)

```systemverilog
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sleep_o <= 1'b0;
        // counters reset here
    end else begin
        if (write_en_i && (reg_offset == OFF_CTRL)) begin
            sleep_o <= write_data_i[0];
        end
```

The CPU controls sleep through `POWER_CTRL[0]`:

```text
write 0x00000001 to 0x0800 -> sleep_o = 1
write 0x00000000 to 0x0800 -> sleep_o = 0
```

This is a software-requested activity-control state.

---

## 21. Clearing All Counters

Source: [`power_mgmt_mmio.sv`, lines 76-84](power_mgmt_mmio.sv#L76-L84)

```systemverilog
if (clear_counters) begin
    cpu_active_cycles    <= 32'h0;
    aes_active_cycles    <= 32'h0;
    uart_active_cycles   <= 32'h0;
    sleep_cycles         <= 32'h0;
    dma_active_cycles    <= 32'h0;
    sensor_active_cycles <= 32'h0;
end
```

Writing bit one of `POWER_CTRL` clears every counter:

```text
write 0x00000002 to 0x0800 -> clear counters
```

Software should clear counters before starting a new activity experiment.

---

## 22. Counter Update Logic

Source: [`power_mgmt_mmio.sv`, lines 84-95](power_mgmt_mmio.sv#L84-L95)

```systemverilog
else begin
    if (cpu_active_i && !sleep_o)
        cpu_active_cycles <= cpu_active_cycles + 32'd1;

    if (aes_active_i)
        aes_active_cycles <= aes_active_cycles + 32'd1;

    if (uart_active_i)
        uart_active_cycles <= uart_active_cycles + 32'd1;

    if (sleep_o)
        sleep_cycles <= sleep_cycles + 32'd1;

    if (dma_active_i)
        dma_active_cycles <= dma_active_cycles + 32'd1;

    if (sensor_active_i)
        sensor_active_cycles <= sensor_active_cycles + 32'd1;
end
```

### Meaning

| Condition | Counter action |
|---|---|
| CPU active and not sleeping | Increment CPU counter. |
| AES busy | Increment AES counter. |
| UART busy | Increment UART counter. |
| `sleep_o = 1` | Increment sleep counter. |
| DMA busy | Increment DMA counter. |
| Sensor/SPI active | Increment sensor counter. |

Several counters can increment in the same clock cycle. For example, AES and DMA may be active together.

These counters measure active cycles, not exclusive operating modes.

---

## 23. Reading the Counters

Source: [`power_mgmt_mmio.sv`, lines 99-113](power_mgmt_mmio.sv#L99-L113)

```systemverilog
always_comb begin
    read_data_o = 32'h0;
    if (read_en_i) begin
        case (reg_offset)
            OFF_CTRL:   read_data_o = {31'h0, sleep_o};
            OFF_CPU:    read_data_o = cpu_active_cycles;
            OFF_AES:    read_data_o = aes_active_cycles;
            OFF_UART:   read_data_o = uart_active_cycles;
            OFF_SLEEP:  read_data_o = sleep_cycles;
            OFF_DMA:    read_data_o = dma_active_cycles;
            OFF_SENSOR: read_data_o = sensor_active_cycles;
            default:    read_data_o = 32'h0;
        endcase
    end
end
```

The CPU uses ordinary `LW` instructions to read each 32-bit counter.

---

## 24. Where the Activity Inputs Come From

The activity signals are created directly from each peripheral's working state.

| Power input | Source expression | Meaning |
|---|---|---|
| `aes_active_i` | `aes_mmio.active_o = busy_reg` | AES operation is active. |
| `uart_active_i` | `uart_mmio.active_o = tx_busy_o` | UART is transmitting. |
| `dma_active_i` | `dma_lite.active_o = busy_o` | DMA transfer is active. |
| `sensor_active_i` | `enable_reg | spi_reg_sel` | Sensor or SPI interface is active. |

The MEM stage connects these signals to the power block.

Source: [`mem_stage.sv`, lines 264-278](mem_stage.sv#L264-L278)

```systemverilog
power_mgmt_mmio u_power_mgmt_mmio (
    .clk                     (clk),
    .rst_n                   (rst_n),
    .addr_i                  (eff_addr),
    .write_data_i            (write_data_i),
    .write_en_i              (power_write_en),
    .read_en_i               (power_read_en),
    .cpu_active_i            (1'b1),
    .aes_active_i            (aes_active),
    .uart_active_i           (uart_active),
    .dma_active_i            (dma_active),
    .sensor_active_i         (sensor_active),
    .read_data_o             (power_read_data),
    .sleep_o                 (sleep_o),
    .activity_counter_debug_o(activity_counter_debug_o)
);
```

`cpu_active_i` is currently tied to one. Inside the power module, CPU cycles are counted only while `sleep_o` is zero.

---

## 25. How Sleep Controls Peripheral Activity

The project does not generate a new clock. It uses the main clock and controls register updates through clock-enable inputs.

### AES

Source: [`mem_stage.sv`, lines 166-176](mem_stage.sv#L166-L176)

```systemverilog
aes_mmio u_aes_mmio (
    .clk      (clk),
    .rst_n    (rst_n),
    .clk_en_i (!sleep_o),
    // remaining ports
);
```

### Sensor/SPI

Source: [`mem_stage.sv`, line 192](mem_stage.sv#L192)

```systemverilog
.clk_en_i(!sleep_o)
```

### UART

Source: [`mem_stage.sv`, line 210](mem_stage.sv#L210)

```systemverilog
.clk_en_i(!sleep_o)
```

### DMA

Source: [`mem_stage.sv`, lines 241-245](mem_stage.sv#L241-L245)

```systemverilog
dma_lite u_dma_lite (
    .clk      (clk),
    .rst_n    (rst_n),
    .clk_en_i (!sleep_o),
```

When `sleep_o = 1`, these blocks receive `clk_en_i = 0` and hold their controlled state.

The physical clock is not ANDed with combinational logic. This avoids unsafe generated-clock behavior.

---

## 26. Blocks That Remain Active During Sleep

Two blocks remain active:

1. The interrupt controller, so it can remember events.
2. The power-management block, so it can count sleep cycles and later clear sleep.

This is visible in the integration:

```systemverilog
simple_intc:
    .clk_en_i(1'b1)

power_mgmt_mmio:
    no external clk_en_i input
```

This resembles an always-on control domain, although the current RTL does not implement physical power domains or retention cells.

---

## 27. Important Current Sleep Limitation

The current `sleep_o` does not stop the CPU pipeline clock.

Evidence:

- `sleep_o` is connected to peripheral clock enables in `mem_stage.sv`.
- In the top module, `sleep_mem` is assigned only to the `sleep_debug` output.
- No PC or pipeline-register enable is driven by `sleep_mem`.

Source: [`riscv_aes_advancements.sv`, lines 494-496](riscv_aes_advancements.sv#L494-L496)

```systemverilog
assign irq_debug              = irq_mem;
assign sleep_debug            = sleep_mem;
assign activity_counter_debug = activity_counter_mem;
```

Therefore, the accurate statement is:

```text
Implemented now:
Peripheral activity hold, sleep indication and activity counting.

Not yet implemented:
Complete CPU pipeline halt and interrupt-driven wake-up.
```

A future implementation should add:

- a `WFI` instruction;
- a PC and pipeline clock enable;
- an interrupt wake-up condition;
- complete CSR and trap handling;
- physical clock gating through proper library cells;
- power-domain intent using UPF if true power gating is required.

---

## 28. Activity Counters Are Not Power Measurements

The comments in `power_mgmt_mmio.sv` explicitly state:

Source: [`power_mgmt_mmio.sv`, lines 13-15](power_mgmt_mmio.sv#L13-L15)

```systemverilog
// These counters measure clock-cycle activity, not physical power directly.
// They provide comparable switching/activity evidence for experiments. Actual
// FPGA or ASIC power must still be obtained from a power-analysis tool.
```

The counters provide activity information:

```text
activity time = active_cycles / clock_frequency
```

At a 50 MHz clock, one cycle is 20 ns.

Example:

```text
AES active counter = 120 cycles

AES active time = 120 / 50,000,000
                = 2.4 microseconds
```

Power requires additional information such as capacitance, voltage and switching factors.

```text
Dynamic power is approximately proportional to:
activity factor x capacitance x voltage squared x frequency
```

Quartus or Genus power reports are still required for a power estimate.

---

# Part III: Verification

## 29. Directed Interrupt Test

The testbench loads a short CPU program that enables the sensor interrupt, reads pending status and clears the event.

Source: [`riscv_core_tb.sv`, lines 957-971](riscv_core_tb.sv#L957-L971)

```systemverilog
task automatic run_interrupt_tests();
    begin
        clear_mem_and_regs();

        // x1 = INTC base 0x600
        dut.u_if_stage.u_instr_mem.rom[0] =
            enc_itype(12'h600, 5'd0, 3'b000, 5'd1, 7'b0010011);

        // x2 = 0x4, enable sensor interrupt
        dut.u_if_stage.u_instr_mem.rom[1] =
            enc_itype(12'h004, 5'd0, 3'b000, 5'd2, 7'b0010011);

        // SW x2, 4(x1): IRQ_ENABLE = 0x4
        dut.u_if_stage.u_instr_mem.rom[2] =
            enc_stype(12'd4, 5'd2, 5'd1, 3'b010, 7'b0100011);

        // LW x3, 0(x1): read IRQ_PENDING
        dut.u_if_stage.u_instr_mem.rom[3] =
            enc_itype(12'd0, 5'd1, 3'b010, 5'd3, 7'b0000011);

        // SW x2, 8(x1): clear sensor pending
        dut.u_if_stage.u_instr_mem.rom[4] =
            enc_stype(12'd8, 5'd2, 5'd1, 3'b010, 7'b0100011);

        apply_reset();
        run_cycles(35);

        check_and_report("INTC", "PENDING",
            "sensor-ready pending bit observed",
            dut.u_id_stage.u_reg_file.regs[3] & 32'h4,
            32'h4);

        check_and_report("INTC", "IRQ",
            "combined irq line asserted when enabled",
            {31'h0, dut.irq_debug},
            32'h1);
    end
endtask
```

The two important checks prove:

1. The sensor event was remembered in pending bit two.
2. The enabled pending event asserted the combined interrupt line.

---

## 30. Directed Power Test

Source: [`riscv_core_tb.sv`, lines 996-1012](riscv_core_tb.sv#L996-L1012)

```systemverilog
task automatic run_power_activity_tests();
    begin
        clear_mem_and_regs();

        // Construct power base 0x800 in x1.
        dut.u_if_stage.u_instr_mem.rom[0] =
            enc_itype(12'h7FF, 5'd0, 3'b000, 5'd1, 7'b0010011);
        dut.u_if_stage.u_instr_mem.rom[1] =
            enc_itype(12'd1, 5'd1, 3'b000, 5'd1, 7'b0010011);

        // Write 0x2: clear counters.
        dut.u_if_stage.u_instr_mem.rom[2] =
            enc_itype(12'd2, 5'd0, 3'b000, 5'd2, 7'b0010011);
        dut.u_if_stage.u_instr_mem.rom[3] =
            enc_stype(12'd0, 5'd2, 5'd1, 3'b010, 7'b0100011);

        // Write 0x1: request sleep.
        dut.u_if_stage.u_instr_mem.rom[4] =
            enc_itype(12'd1, 5'd0, 3'b000, 5'd2, 7'b0010011);
        dut.u_if_stage.u_instr_mem.rom[5] =
            enc_stype(12'd0, 5'd2, 5'd1, 3'b010, 7'b0100011);

        apply_reset();
        run_cycles(35);

        check_and_report("POWER", "SLEEP",
            "sleep control bit set",
            {31'h0, dut.sleep_debug},
            32'h1);

        check_and_report("POWER", "COUNT",
            "sleep cycles incremented",
            (dut.u_mem_stage.u_power_mgmt_mmio.sleep_cycles > 0),
            1'b1);

        check_and_report("POWER", "DEBUG",
            "activity debug output observable",
            dut.activity_counter_debug,
            dut.u_mem_stage.u_power_mgmt_mmio.activity_counter_debug_o);
    end
endtask
```

This test proves:

- software can request sleep;
- sleep cycles increase;
- the activity debug output remains observable.

---

## 31. Full-SoC Scenario Verification

The complete scenario enables all interrupt sources and clears activity counters before starting the application.

Source: [`riscv_core_tb.sv`, lines 1183-1194](riscv_core_tb.sv#L1183-L1194)

```systemverilog
// x3 = interrupt-controller base
rom[p++] = enc_itype(12'h600, 5'd0, 3'b000, 5'd3, 7'b0010011);

// x6 = power base 0x800
rom[p++] = enc_itype(12'h7ff, 5'd0, 3'b000, 5'd6, 7'b0010011);
rom[p++] = enc_itype(12'd1, 5'd6, 3'b000, 5'd6, 7'b0010011);

// Enable all four interrupt sources.
rom[p++] = enc_itype(12'd15, 5'd0, 3'b000, 5'd7, 7'b0010011);
rom[p++] = enc_stype(12'd4, 5'd7, 5'd3, 3'b010, 7'b0100011);

// Clear activity counters.
rom[p++] = enc_itype(12'd2, 5'd0, 3'b000, 5'd8, 7'b0010011);
rom[p++] = enc_stype(12'd0, 5'd8, 5'd6, 3'b010, 7'b0100011);
```

After sensor, SPI, DMA, AES and UART activity, the CPU reads pending and activity registers and requests sleep.

Source: [`riscv_core_tb.sv`, lines 1262-1276](riscv_core_tb.sv#L1262-L1276)

```systemverilog
// Read interrupt pending register.
rom[p++] = enc_itype(12'd0, 5'd3, 3'b010, 5'd21, 7'b0000011);

// Read AES, UART, DMA and sensor activity counters.
rom[p++] = enc_itype(12'd8,  5'd6, 3'b010, 5'd22, 7'b0000011);
rom[p++] = enc_itype(12'd12, 5'd6, 3'b010, 5'd23, 7'b0000011);
rom[p++] = enc_itype(12'd20, 5'd6, 3'b010, 5'd24, 7'b0000011);
rom[p++] = enc_itype(12'd24, 5'd6, 3'b010, 5'd25, 7'b0000011);

// Request sleep.
rom[p++] = enc_itype(12'd1, 5'd0, 3'b000, 5'd15, 7'b0010011);
rom[p++] = enc_stype(12'd0, 5'd15, 5'd6, 3'b010, 7'b0100011);
```

The final checks are:

Source: [`riscv_core_tb.sv`, lines 1300-1307](riscv_core_tb.sv#L1300-L1307)

```systemverilog
check_and_report("FULL-SOC", "IRQ_PENDING",
    "AES/UART/sensor/DMA pending bits captured",
    dut.u_id_stage.u_reg_file.regs[21] & 32'hf,
    32'hf);

check_and_report("FULL-SOC", "IRQ_LINE",
    "combined enabled interrupt line asserted",
    {31'h0, dut.irq_debug},
    32'h1);

check_and_report("FULL-SOC", "AES_ACTIVITY",
    "CPU-observed AES active counter is nonzero",
    (dut.u_id_stage.u_reg_file.regs[22] > 0),
    1'b1);

check_and_report("FULL-SOC", "UART_ACTIVITY",
    "CPU-observed UART active counter is nonzero",
    (dut.u_id_stage.u_reg_file.regs[23] > 0),
    1'b1);

check_and_report("FULL-SOC", "DMA_ACTIVITY",
    "CPU-observed DMA active counter is nonzero",
    (dut.u_id_stage.u_reg_file.regs[24] > 0),
    1'b1);

check_and_report("FULL-SOC", "SENSOR_ACTIVITY",
    "CPU-observed sensor active counter is nonzero",
    (dut.u_id_stage.u_reg_file.regs[25] > 0),
    1'b1);

check_and_report("FULL-SOC", "SLEEP",
    "CPU requested low-power sleep after transmission",
    {31'h0, dut.sleep_debug},
    32'h1);

check_and_report("FULL-SOC", "SLEEP_CYCLES",
    "sleep activity counter incremented",
    (dut.u_mem_stage.u_power_mgmt_mmio.sleep_cycles > 0),
    1'b1);
```

This scenario proves that all four event sources were captured and all major activity counters changed during one integrated application.

---

## 32. What Happens If These Modules Are Removed?

### Without `simple_intc.sv`

- AES can still encrypt.
- UART can still transmit.
- DMA can still transfer data.
- The CPU must poll each peripheral separately.
- Short completion events may be lost if they are not stored inside the peripheral.
- There is no combined event output or future wake-up path.

### Without `power_mgmt_mmio.sv`

- The processor and AES can still operate.
- Software cannot request the implemented peripheral sleep state.
- AES, UART, DMA and sensor clock enables lose their common sleep control.
- Active-cycle and sleep-cycle measurements are unavailable.
- The thesis has less evidence for system-level low-power behavior.

---

## 33. Accurate Claims for the Current RTL

### Correct claims

```text
The controller captures AES, UART, sensor and DMA events.
Pending bits are sticky and software-clearable.
Enabled pending events create one combined IRQ output.

The power block provides a software sleep request.
Sleep controls peripheral state updates through clock-enable signals.
The design counts CPU, AES, UART, DMA, sensor and sleep cycles.
```

### Claims that would be too strong

```text
The CPU executes a complete interrupt-service routine automatically.
The CPU pipeline is fully stopped in sleep.
The design contains physical power gating.
The counters directly measure power in watts.
The current prototype is automotive qualified.
```

---

## 34. Viva-Ready Explanation

Use this answer in a viva:

> The interrupt controller is required because AES, UART, DMA and the sensor interface complete their work after several clock cycles. Their events are stored in sticky pending bits so that software cannot miss a short completion pulse. Software can enable selected sources, read pending status and clear events. The enabled pending events are combined into one IRQ output. In the present processor, this output is verified as a debug and event signal because full CSR and trap handling is future work.
>
> The power-management module provides a software sleep request and cycle counters for CPU, AES, UART, DMA, sensor and sleep activity. The sleep signal is connected to peripheral clock-enable inputs, so the normal system clock is not unsafely gated. These counters measure how many cycles each block was active; they do not directly measure watts. The current sleep state holds peripheral activity but does not yet halt the complete CPU pipeline. A future version should add WFI, CSR interrupt handling and interrupt-based wake-up.

---

## 35. Final Summary

```text
simple_intc.sv
    receives four peripheral events
    remembers them in pending bits
    applies software enable bits
    creates one combined irq_o
    allows write-one-to-clear

power_mgmt_mmio.sv
    accepts a software sleep request
    controls peripheral activity through clock enables
    counts CPU, AES, UART, DMA, sensor and sleep cycles
    provides MMIO and debug readback

Current implementation
    verified in directed and full-SoC tests
    does not yet include full CSR/trap interrupt handling
    does not yet stop the complete CPU pipeline
    does not directly measure physical power
```

These blocks turn the AES-equipped processor into a more complete research SoC. They provide event handling, low-activity control and measurable system behavior around the encryption engine.

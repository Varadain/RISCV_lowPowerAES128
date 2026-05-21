## AES / AES-CTR Register Map

Base address: `0x0000_0300`

| Offset | Register | Description |
|---|---|---|
| `0x00` | `AES_CTRL` | Write bit 0 start, bit 1 clear done, bit 2 CTR mode |
| `0x04` | `AES_STATUS` | Read bit 0 busy, bit 1 done, bit 2 CTR mode |
| `0x08` | `AES_KEY0` | AES key bits `[31:0]` |
| `0x0C` | `AES_KEY1` | AES key bits `[63:32]` |
| `0x10` | `AES_KEY2` | AES key bits `[95:64]` |
| `0x14` | `AES_KEY3` | AES key bits `[127:96]` |
| `0x18` | `AES_PT0` | Plaintext bits `[31:0]` |
| `0x1C` | `AES_PT1` | Plaintext bits `[63:32]` |
| `0x20` | `AES_PT2` | Plaintext bits `[95:64]` |
| `0x24` | `AES_PT3` | Plaintext bits `[127:96]` |
| `0x28` | `AES_CT0` | Ciphertext bits `[31:0]` |
| `0x2C` | `AES_CT1` | Ciphertext bits `[63:32]` |
| `0x30` | `AES_CT2` | Ciphertext bits `[95:64]` |
| `0x34` | `AES_CT3` | Ciphertext bits `[127:96]` |
| `0x38` | `AES_NONCE0` | CTR nonce bits `[31:0]` |
| `0x3C` | `AES_NONCE1` | CTR nonce bits `[63:32]` |
| `0x40` | `AES_COUNT0` | CTR counter bits `[31:0]` |
| `0x44` | `AES_COUNT1` | CTR counter bits `[63:32]` |

---

## Sensor / SPI Register Map

Base address: `0x0000_0400`

| Offset | Register | Description |
|---|---|---|
| `0x00` | `SENSOR_DATA` | Current sensor sample; writable for test/demo injection |
| `0x04` | `SENSOR_STATUS` | Bit 0 data ready |
| `0x08` | `SENSOR_CONTROL` | Bit 0 enable, bit 1 clear data ready |
| `0x10` | `SPI_RXDATA` | Intel `altera_avalon_spi` receive data |
| `0x14` | `SPI_TXDATA` | Intel `altera_avalon_spi` transmit data |
| `0x18` | `SPI_STATUS` | Intel `altera_avalon_spi` status register |
| `0x1C` | `SPI_CONTROL` | Intel `altera_avalon_spi` control register |
| `0x24` | `SPI_SLAVE_SELECT` | Intel `altera_avalon_spi` slave-select register |

---

## UART Register Map

Base address: `0x0000_0500`

| Offset | Register | Description |
|---|---|---|
| `0x00` | `UART_TXDATA` | Write low byte to start an 8-N-1 transmit when idle |
| `0x04` | `UART_STATUS` | Bit 0 busy, bit 1 done |
| `0x08` | `UART_CONTROL` | Bit 0 enable, bit 1 clear done |
| `0x0C` | `UART_BAUD_DIV` | Baud tick divisor |

---

## Interrupt Controller Register Map

Base address: `0x0000_0600`

| Offset | Register | Description |
|---|---|---|
| `0x00` | `IRQ_PENDING` | Bit 0 AES done, bit 1 UART done, bit 2 sensor ready, bit 3 DMA done |
| `0x04` | `IRQ_ENABLE` | Same bit layout as `IRQ_PENDING` |
| `0x08` | `IRQ_CLEAR` | Write 1s to clear pending bits |

---

## DMA-lite Register Map

Base address: `0x0000_0700`

| Offset | Register | Description |
|---|---|---|
| `0x00` | `DMA_SRC_ADDR` | Source byte address |
| `0x04` | `DMA_DST_ADDR` | Destination byte address |
| `0x08` | `DMA_LEN` | Word count |
| `0x0C` | `DMA_CTRL` | Bit 0 start, bit 1 clear done |
| `0x10` | `DMA_STATUS` | Bit 0 busy, bit 1 done |

---

## Power / Activity Register Map

Base address: `0x0000_0800`

| Offset | Register | Description |
|---|---|---|
| `0x00` | `POWER_CTRL` | Bit 0 sleep request, bit 1 clear counters |
| `0x04` | `CPU_ACTIVE_CYCLES` | CPU-active counter |
| `0x08` | `AES_ACTIVE_CYCLES` | AES busy counter |
| `0x0C` | `UART_ACTIVE_CYCLES` | UART busy counter |
| `0x10` | `SLEEP_CYCLES` | Sleep-mode counter |
| `0x14` | `DMA_ACTIVE_CYCLES` | DMA busy counter |
| `0x18` | `SENSOR_ACTIVE_CYCLES` | Sensor enabled counter |
```,
------


- riscv_aes_advancements.sv
        |
        +-- pc_reg.sv
        +-- if_stage.sv
        |       +-- instr_mem.sv
        |
        +-- id_stage.sv
        |       +-- reg_file.sv
        |       +-- imm_gen.sv
        |       +-- control_unit.sv
        |
        +-- ex_stage.sv
        |       +-- alu.sv
        |       +-- forwarding_unit.sv
        |
        +-- mem_stage.sv
        |       +-- data_mem.sv
        |       +-- load_store_unit.sv
        |       +-- aes_mmio.sv
        |       |       +-- aes128_lowpower.sv
        |       |               +-- sub_bytes
        |       |               +-- shift_rows
        |       |               +-- mix_columns
        |       |               +-- key_expand
        |       |               +-- aes_sbox
        |       |
        |       +-- sensor_mmio.sv
        |       +-- sensor_spi_mmio.sv
        |       |       +-- ip/sensor_spi_ip/sensor_spi_ip.v
        |       |
        |       +-- uart_mmio.sv
        |       |       +-- uart_tx.sv
        |       |
        |       +-- simple_intc.sv
        |       +-- dma_lite.sv
        |       +-- power_mgmt_mmio.sv
        |
        +-- wb_stage.sv
        +-- hazard_unit.sv

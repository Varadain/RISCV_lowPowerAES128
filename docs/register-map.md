# Register reference

[Home](../README.md) · [Integration explanation](02-riscv-integration.md) · [Interrupt explanation](03-interrupts-and-power.md)

Addresses below are CPU-visible byte addresses. Multiword AES values are packed least-significant word first. The RTL links are the authority for simultaneous-write behavior and side effects.

## AES / AES-CTR: base `0x300`

[aes_mmio.sv](../rtl/aes/aes_mmio.sv)

| Offset | Name | Use |
| --- | --- | --- |
| `0x00` | CTRL | Write bit 0 start, bit 1 clear done, bit 2 CTR mode |
| `0x04` | STATUS | Read bit 0 busy, bit 1 done, bit 2 CTR mode |
| `0x08..0x14` | KEY0..KEY3 | Four 32-bit key words |
| `0x18..0x24` | PT0..PT3 | Four 32-bit input words |
| `0x28..0x34` | CT0..CT3 | Read four ciphertext words |
| `0x38, 0x3c` | NONCE0, NONCE1 | Low/high halves of the 64-bit nonce |
| `0x40, 0x44` | COUNT0, COUNT1 | Low/high halves of the 64-bit counter |

CTRL is not a set-only bit register: a write also assigns CTR mode from bit 2. For example, use `0x5` to start CTR, `0x6` to clear done while retaining CTR, and `0x1` to start a direct block-encryption test. Finish configuration before start and do not modify inputs while busy.

## Sensor / SPI: base `0x400`

[sensor_spi_mmio.sv](../rtl/peripherals/sensor_spi_mmio.sv)

| Offset | Name | Use |
| --- | --- | --- |
| `0x00` | SENSOR_DATA | Read current 32-bit sample |
| `0x04` | SENSOR_STATUS | Read bit 0 data-ready |
| `0x08` | SENSOR_CONTROL | Local sensor enable and ready-clear control |
| `0x10` | SPI_RXDATA | Read received byte |
| `0x14` | SPI_TXDATA | Write transmit byte |
| `0x18` | SPI_STATUS | Generated SPI IP status |
| `0x1c` | SPI_CONTROL | Generated SPI IP control |
| `0x24` | SPI_SS | Slave-select mask |

The wrapper also has a synthetic fallback sample generator. SPI waveform activity and synthetic sample reads are not proof that a physical sensor was connected.

## UART: base `0x500`

[uart_mmio.sv](../rtl/peripherals/uart_mmio.sv)

| Offset | Name | Use |
| --- | --- | --- |
| `0x00` | TXDATA | Low byte; writing starts TX when enabled and idle |
| `0x04` | STATUS | Read bit 0 busy, bit 1 sticky done |
| `0x08` | CONTROL | Bit 0 enable, bit 1 clear done |
| `0x0c` | BAUD_DIV | 16-bit baud divisor |

## Interrupt controller: base `0x600`

[simple_intc.sv](../rtl/peripherals/simple_intc.sv)

| Offset | Name | Use |
| --- | --- | --- |
| `0x00` | IRQ_PENDING | Read sticky bits: AES 0, UART 1, sensor 2, DMA 3 |
| `0x04` | IRQ_ENABLE | Write/read source enables |
| `0x08` | IRQ_CLEAR | Write-one-to-clear pending bits |

## DMA-lite: base `0x700`

[dma_lite.sv](../rtl/peripherals/dma_lite.sv)

| Offset | Name | Use |
| --- | --- | --- |
| `0x00` | SRC_ADDR | RAM source byte address |
| `0x04` | DST_ADDR | RAM destination byte address |
| `0x08` | LEN | Number of 32-bit words |
| `0x0c` | CTRL | Bit 0 start, bit 1 clear done |
| `0x10` | STATUS | Bit 0 busy, bit 1 done |

## Power/activity: base `0x800`

[power_mgmt_mmio.sv](../rtl/peripherals/power_mgmt_mmio.sv)

| Offset | Name | Use |
| --- | --- | --- |
| `0x00` | POWER_CTRL | Bit 0 sleep request, bit 1 counter clear |
| `0x04` | CPU cycles | CPU-active count, excluding sleep |
| `0x08` | AES cycles | AES-active count |
| `0x0c` | UART cycles | UART-active count |
| `0x10` | SLEEP cycles | Sleep-cycle count |
| `0x14` | DMA cycles | DMA-active count |
| `0x18` | SENSOR cycles | Sensor-active count |

Counters are 32-bit values and can wrap. They are not measured power values.

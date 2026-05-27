# Sensor to Encrypted Output Flow

## Project Application

This project can be presented as a:

```text
Lightweight RISC-V Based Secure Health-Monitoring IoT Processor
with AES-CTR Encryption and Custom Security ISA
```

The system is designed for an IoT health-monitoring node where sensor data is
collected, encrypted using hardware AES, and transmitted as encrypted output.

## Overall Flow

```text
Health Sensor
   ->
Sensor / SPI MMIO
   ->
5-stage RISC-V CPU
   ->
AES-CTR Hardware Accelerator
   ->
UART Transmitter
   ->
Encrypted Output
```

## 1. Sensor Produces Health Data

A practical health-monitoring application can use sensors such as:

| Sensor | Data Measured |
| --- | --- |
| MAX30102 | Heart rate and SpO2 |
| LM35 / DS18B20 | Body temperature |
| MPU6050 | Motion or fall detection |

Example raw sensor data:

```text
Patient ID       = 05
Heart Rate       = 78 bpm
SpO2             = 97%
Body Temperature = 36.8 C
Status           = Normal
```

This is sensitive biomedical data and should not be transmitted directly.

## 2. Sensor Data Enters Sensor MMIO / SPI Block

The sensor data is made available to the RISC-V processor through memory-mapped
registers.

Sensor base address:

```text
0x0000_0400
```

Important sensor registers:

| Address | Register | Function |
| --- | --- | --- |
| `0x0000_0400` | `SENSOR_DATA` | Current sensor sample |
| `0x0000_0404` | `SENSOR_STATUS` | Data-ready flag |
| `0x0000_0408` | `SENSOR_CONTROL` | Enable and clear control |

The CPU first checks `SENSOR_STATUS`. If the data-ready bit is set, the CPU
reads the sensor value from `SENSOR_DATA`.

If SPI is used, the SPI register window is also mapped in the sensor address
region.

## 3. RISC-V CPU Packs The Data

The RISC-V CPU reads the sensor data and forms a 128-bit plaintext packet.

Example packet fields:

```text
[patient_id | heart_rate | spo2 | temperature | status | timestamp | padding]
```

Example 128-bit plaintext packet:

```text
05 4E 61 17 01 00 00 00 00 00 00 00 00 00 00 00
```

Meaning:

| Field | Value |
| --- | --- |
| `05` | Patient ID |
| `4E` | 78 bpm heart rate |
| `61` | 97% SpO2 |
| `17` | Encoded temperature |
| `01` | Normal status |

This plaintext packet is not transmitted directly. It is given to the AES-CTR
hardware accelerator for encryption.

## 4. CPU Writes Data To AES MMIO

AES base address:

```text
0x0000_0300
```

Important AES registers:

| Address | Register | Function |
| --- | --- | --- |
| `0x0000_0300` | `AES_CTRL` | Start, clear done, mode control |
| `0x0000_0304` | `AES_STATUS` | Busy, done, CTR mode status |
| `0x0000_0308` | `AES_KEY0` | AES key word 0 |
| `0x0000_030C` | `AES_KEY1` | AES key word 1 |
| `0x0000_0310` | `AES_KEY2` | AES key word 2 |
| `0x0000_0314` | `AES_KEY3` | AES key word 3 |
| `0x0000_0318` | `AES_PT0` | Plaintext word 0 |
| `0x0000_031C` | `AES_PT1` | Plaintext word 1 |
| `0x0000_0320` | `AES_PT2` | Plaintext word 2 |
| `0x0000_0324` | `AES_PT3` | Plaintext word 3 |
| `0x0000_0328` | `AES_CT0` | Ciphertext word 0 |
| `0x0000_032C` | `AES_CT1` | Ciphertext word 1 |
| `0x0000_0330` | `AES_CT2` | Ciphertext word 2 |
| `0x0000_0334` | `AES_CT3` | Ciphertext word 3 |
| `0x0000_0338` | `AES_NONCE0` | Nonce lower word |
| `0x0000_033C` | `AES_NONCE1` | Nonce upper word |
| `0x0000_0340` | `AES_COUNT0` | Counter lower word |
| `0x0000_0344` | `AES_COUNT1` | Counter upper word |

The CPU writes:

1. AES key
2. Plaintext health packet
3. Nonce
4. Counter
5. AES control register with start and CTR mode enabled

## 5. AES-CTR Encrypts The Sensor Data

AES-CTR mode converts the AES block cipher into a stream-like encryption mode.

Encryption operation:

```text
Keystream  = AES_encrypt(nonce || counter)
Ciphertext = Plaintext XOR Keystream
```

The plaintext health packet is XORed with the AES-generated keystream. The
result is encrypted ciphertext.

The counter is automatically incremented after each block, so the next sensor
packet uses a new counter value.

This is important because repeated health values should not generate repeated
ciphertext.

## 6. CPU Waits For AES Done

The CPU reads the AES status register:

```text
AES_STATUS at 0x0000_0304
```

Important status bits:

| Bit | Meaning |
| --- | --- |
| bit 0 | AES busy |
| bit 1 | AES done |
| bit 2 | CTR mode |

When the done bit becomes `1`, encryption is complete.

Then the CPU reads:

```text
AES_CT0
AES_CT1
AES_CT2
AES_CT3
```

These four 32-bit words form the 128-bit encrypted health packet.

Example ciphertext:

```text
A7 3C 91 4E 20 D5 6B F0 8C 1A 77 42 9E 13 C0 B6
```

## 7. CPU Sends Ciphertext To UART

UART base address:

```text
0x0000_0500
```

UART registers:

| Address | Register | Function |
| --- | --- | --- |
| `0x0000_0500` | `UART_TXDATA` | Byte to transmit |
| `0x0000_0504` | `UART_STATUS` | Busy and done flags |
| `0x0000_0508` | `UART_CONTROL` | Enable and clear done |
| `0x0000_050C` | `UART_BAUD_DIV` | Baud-rate divisor |

The CPU configures the UART by setting:

1. `UART_BAUD_DIV`
2. `UART_CONTROL`

Then it writes ciphertext bytes to:

```text
UART_TXDATA
```

The UART serializes the encrypted data on the `uart_tx` output pin.

## 8. Final Output

The communication link carries only encrypted bytes.

Example output:

```text
A7 3C 91 4E 20 D5 6B F0 8C 1A 77 42 9E 13 C0 B6
```

The output can be connected to:

- Bluetooth module
- Wi-Fi module
- hospital gateway
- PC serial receiver
- edge server
- another microcontroller

The transmitted output is ciphertext, not readable health data.

## 9. Receiver Decrypts The Data

The authorized receiver must have:

1. Same AES key
2. Same nonce
3. Same counter value
4. Received ciphertext

AES-CTR decryption uses the same AES encryption operation:

```text
Keystream = AES_encrypt(nonce || counter)
Plaintext = Ciphertext XOR Keystream
```

Recovered data:

```text
Patient ID       = 05
Heart Rate       = 78 bpm
SpO2             = 97%
Body Temperature = 36.8 C
Status           = Normal
```

The nonce does not need to be secret, but it must be unique for a given key.
The AES key must remain secret.

## 10. Complete System Flow

```text
[Health Sensor]
      |
      | raw health data
      v
[Sensor / SPI MMIO at 0x0000_0400]
      |
      | CPU reads SENSOR_DATA
      v
[5-stage RISC-V CPU]
      |
      | prepares 128-bit plaintext packet
      v
[AES-CTR MMIO at 0x0000_0300]
      |
      | hardware encryption
      v
[RISC-V CPU reads AES_CT0 to AES_CT3]
      |
      | writes ciphertext bytes
      v
[UART MMIO at 0x0000_0500]
      |
      | serial encrypted bits
      v
[UART TX pin]
      |
      v
[Receiver / Gateway / Doctor PC]
      |
      | AES-CTR decryption
      v
[Original health data displayed]
```

## 11. Role Of DMA

Without DMA:

```text
CPU manually moves sensor data -> AES -> UART
```

With DMA-lite:

```text
DMA helps move words between sensor/data memory/AES/UART spaces
```

This reduces CPU involvement and can lower CPU active cycles.

DMA base address:

```text
0x0000_0700
```

## 12. Role Of Interrupts

Without interrupts:

```text
CPU repeatedly polls AES_STATUS, UART_STATUS, and SENSOR_STATUS
```

With the interrupt controller:

```text
AES done     -> IRQ pending
UART done    -> IRQ pending
Sensor ready -> IRQ pending
DMA done     -> IRQ pending
```

The CPU can sleep or perform other work until an event occurs.

Interrupt controller base address:

```text
0x0000_0600
```

## 13. Role Of Low-Power Counters

The power/activity block counts how long each subsystem is active.

Counters include:

- CPU active cycles
- AES active cycles
- UART active cycles
- DMA active cycles
- sensor active cycles
- sleep cycles

Power/activity base address:

```text
0x0000_0800
```

These counters help evaluate whether hardware acceleration, DMA, custom ISA,
and sleep mode reduce system activity.

## 14. One-Line Explanation

The sensor produces health data, the RISC-V CPU reads it through MMIO, packs it
into a 128-bit block, AES-CTR encrypts it in hardware, UART transmits only the
ciphertext, and the authorized receiver decrypts it using the same AES key,
nonce, and counter.


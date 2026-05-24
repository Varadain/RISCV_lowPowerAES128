/*
 * Lightweight IoT Security Processor demo program.
 *
 * Flow:
 *   1. Read sensor sample from 0x400.
 *   2. Program AES-CTR key, nonce, and counter.
 *   3. Encrypt a 128-bit block containing the sensor word.
 *   4. Send ciphertext words to UART TXDATA.
 *   5. Enter sleep.
 *
 * This is documentation-oriented RV32I assembly. It uses only load/store,
 * addi, lui, and simple polling patterns supported by the project CPU.
 */

    .section .text
    .globl _start

_start:
    /* Base addresses */
    addi x10, x0, 0x300        /* AES base */
    addi x11, x0, 0x400        /* Sensor base */
    addi x12, x0, 0x500        /* UART base */
    addi x13, x0, 0x600        /* INTC base */
    addi x14, x0, 0x7ff
    addi x14, x14, 1           /* Power base = 0x800 */

    /* Enable sensor/AES/UART interrupt sources: AES, UART, sensor */
    addi x5, x0, 0x7
    sw   x5, 4(x13)

    /* Read one sensor sample */
    lw   x6, 0(x11)

    /* AES-128 key = 000102030405060708090A0B0C0D0E0F */
    lui  x5, 0x0C0D1
    addi x5, x5, -497          /* 0x0C0D0E0F */
    sw   x5, 8(x10)
    lui  x5, 0x08091
    addi x5, x5, -1525         /* 0x08090A0B */
    sw   x5, 12(x10)
    lui  x5, 0x04050
    addi x5, x5, 1543          /* 0x04050607 */
    sw   x5, 16(x10)
    addi x5, x0, 0
    sw   x5, 20(x10)

    /* Plaintext block: sensor word followed by zeros */
    sw   x6, 24(x10)
    sw   x0, 28(x10)
    sw   x0, 32(x10)
    sw   x0, 36(x10)

    /* CTR nonce/counter */
    sw   x0, 56(x10)
    sw   x0, 60(x10)
    addi x5, x0, 1
    sw   x5, 64(x10)
    sw   x0, 68(x10)

    /* Start AES in CTR mode: bit 0 start, bit 2 CTR */
    addi x5, x0, 5
    sw   x5, 0(x10)

poll_aes:
    lw   x7, 4(x10)
    addi x8, x0, 2
    and  x7, x7, x8
    beq  x7, x0, poll_aes

    /* Send ciphertext low bytes/words through UART TXDATA. */
    lw   x7, 40(x10)
    sw   x7, 0(x12)
    lw   x7, 44(x10)
    sw   x7, 0(x12)
    lw   x7, 48(x10)
    sw   x7, 0(x12)
    lw   x7, 52(x10)
    sw   x7, 0(x12)

    /* Enter sleep mode. */
    addi x5, x0, 1
    sw   x5, 0(x14)

done:
    beq x0, x0, done

// =============================================================================
// AES-128 compatibility wrapper
//
// Why this module exists:
//   The SoC was originally connected to an AES block with the simple interface
//   below. The publication-quality reusable AES implementation has an extra
//   "busy" output, so this wrapper adapts that implementation without forcing
//   changes throughout the processor and MMIO logic.
//
// Transaction sequence:
//   1. The caller places plaintext and key on the input buses.
//   2. The caller pulses start while clk_en is high.
//   3. The reusable AES core raises busy internally and processes all rounds.
//   4. The core pulses done when ciphertext is valid.
//
// The SoC keeps its original AES primitive interface while the implementation
// is the exact iterative, hardware-reusable AES128_updated_new architecture
// copied under rtl/aes128_reusable/. No generated/gated clock is used.
// =============================================================================
module aes128_lowpower (
    input  logic         clk,
    input  logic         reset,
    input  logic         clk_en,
    input  logic         start,
    input  logic [127:0] plaintext,
    input  logic [127:0] key,
    output logic [127:0] ciphertext,
    output logic         done
);

    // busy is used locally to reject a second start while encryption is active.
    logic core_busy;

    // Clock enable is applied to the start request, not to the physical clock.
    // This avoids unsafe clock gating. Once a request is accepted, the AES core
    // continues until the full ten-round AES-128 operation is complete.
    AES128_updated_new u_reusable_aes (
        .clk       (clk),
        .reset     (reset),
        .start     (start && clk_en && !core_busy),
        .busy      (core_busy),
        .done      (done),
        .plaintext (plaintext),
        .key       (key),
        .ciphertext(ciphertext)
    );

endmodule

"""Rebuild the documentation's SVG diagrams using only the Python standard library."""
from html import escape
from pathlib import Path

OUT = Path(__file__).resolve().parents[1] / 'docs' / 'figures'
BG, INK, MUTED = '#F5EFE1', '#293B3B', '#65736A'
TEAL, GOLD, PAPER = '#3E706B', '#B3874D', '#FFFCF5'


class Figure:
    def __init__(self, title, description, height=560):
        self.height = height
        self.parts = [f'<svg xmlns="http://www.w3.org/2000/svg" width="1100" height="{height}" viewBox="0 0 1100 {height}" role="img" aria-labelledby="title desc">',
                      f'<title id="title">{escape(title)}</title><desc id="desc">{escape(description)}</desc>',
                      f'<rect width="1100" height="{height}" fill="{BG}"/>',
                      f'<defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0 0 L10 5 L0 10 Z" fill="{TEAL}"/></marker></defs>']
        self.text(50, 48, 'LOW-POWER AES / RISC-V', 13, MUTED, 'bold')
        self.text(50, 91, title, 29, INK, 'bold')

    def text(self, x, y, content, size=17, color=INK, weight='normal', anchor='start'):
        self.parts.append(f'<text x="{x}" y="{y}" fill="{color}" font-family="Arial, sans-serif" font-size="{size}" font-weight="{weight}" text-anchor="{anchor}">{escape(content)}</text>')

    def box(self, x, y, w, h, title, lines=(), accent=TEAL):
        self.parts.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="4" fill="{PAPER}" stroke="{accent}" stroke-width="1.5"/>')
        self.text(x + 16, y + 31, title, 19, accent, 'bold')
        for i, line in enumerate(lines):
            self.text(x + 16, y + 58 + i * 25, line, 16)

    def arrow(self, points, dashed=False):
        path = 'M' + ' L'.join(f'{x} {y}' for x, y in points)
        dash = ' stroke-dasharray="6 5"' if dashed else ''
        self.parts.append(f'<path d="{path}" fill="none" stroke="{TEAL}" stroke-width="2" marker-end="url(#arrow)"{dash}/>')

    def note(self, content, y=None):
        self.text(50, y or self.height - 30, content, 15, MUTED)

    def save(self, name):
        OUT.mkdir(parents=True, exist_ok=True)
        (OUT / name).write_text('\n'.join(self.parts) + '\n</svg>\n', encoding='utf-8')


def roadmap():
    f = Figure('From one cipher core to a small security processor',
               'Three learning stages: standalone reusable AES, processor integration, and event/activity coordination.', 470)
    cards = [(50, '01  Reusable AES', ['128-bit block and key', 'Sequential round hardware', 'Standalone synthesis study', 'GCON 2026']),
             (400, '02  Processor integration', ['Five-stage RV32I-style core', 'MMIO + AES-CTR + custom-0', 'Sensor/SPI and UART', 'ISAIA 2026']),
             (750, '03  System coordination', ['Sticky interrupt status', 'DMA-lite word copying', 'Activity counters + sleep', 'Later integration / verification'])]
    for x, title, lines in cards:
        f.box(x, 165, 300, 175, title, lines)
    f.arrow([(350, 251), (393, 251)])
    f.arrow([(700, 251), (743, 251)])
    f.note('Read in this order. The current branch combines the stages; it is not three separate frozen releases.', 398)
    f.save('project-roadmap.svg')


def aes_rounds():
    f = Figure('One datapath, reused across ten AES rounds',
               'Stored state flows through SubBytes, ShiftRows, optional MixColumns and AddRoundKey; the controller reuses this path.', 570)
    f.text(50, 130, 'Initial plaintext XOR key occurs before round 1.', 16, MUTED)
    boxes = [(50, 'Stored state', ['128-bit register']), (260, 'SubBytes', ['One byte at a time']),
             (470, 'ShiftRows', ['Byte reordering']), (680, 'MixColumns', ['Rounds 1-9 only']),
             (890, 'AddRoundKey', ['XOR round key'])]
    for x, title, lines in boxes:
        f.box(x, 165, 160, 105, title, lines)
    for x in [210, 420, 630, 840]:
        f.arrow([(x, 215), (x + 43, 215)])
    f.arrow([(1050, 215), (1070, 215), (1070, 307), (130, 307), (130, 275)])
    f.text(350, 330, 'Intermediate state feeds the next round', 16, MUTED)
    f.box(50, 375, 300, 110, 'Round controller', ['START / WAIT handshakes', 'Rounds 1 to 10'])
    f.box(435, 375, 310, 110, 'Key expansion', ['Reuse the key-expansion unit', 'Its own S-box resources'])
    f.box(890, 375, 160, 110, 'Ciphertext', ['After round 10'])
    f.arrow([(745, 400), (840, 400), (840, 284), (970, 284), (970, 275)])
    f.arrow([(1030, 275), (1030, 365)])
    f.arrow([(200, 375), (200, 346), (340, 346), (340, 275)], True)
    f.note('Conceptual round flow. Round 10 bypasses MixColumns; see the FSM for exact cycle-by-cycle scheduling.')
    f.save('aes-rounds.svg')


def architecture():
    f = Figure('Processor pipeline and the MEM-stage integration point',
               'A five-stage pipeline routes MMIO requests through the memory stage to AES, sensor SPI, UART, interrupt, DMA and power blocks.', 700)
    for i, (title, sub) in enumerate([('IF', 'Fetch'), ('ID', 'Decode'), ('EX', 'ALU / address'), ('MEM', 'RAM / MMIO'), ('WB', 'Writeback')]):
        x = 50 + i * 205
        f.box(x, 145, 180, 90, title, [sub])
        if i < 4:
            f.arrow([(x + 180, 190), (x + 198, 190)])
    f.box(50, 290, 1000, 70, 'MEM-stage address decode and read-data multiplexer', [])
    f.arrow([(755, 235), (755, 283)])
    top = [(50, 'AES / AES-CTR', ['0x300', 'Reusable 128-bit core']),
           (310, 'Sensor / SPI', ['0x400', 'SPI IP + sensor wrapper']),
           (570, 'UART TX', ['0x500', 'Byte serial output']),
           (830, 'Data RAM', ['256 x 32-bit words', 'CPU and DMA ports'])]
    for x, title, lines in top:
        f.arrow([(x + 105, 360), (x + 105, 400)])
        f.box(x, 407, 220, 110, title, lines)
    bottom = [(180, 'Interrupt status', ['0x600 / sticky pending', 'IRQ exposed; no CPU trap path']),
              (480, 'DMA-lite', ['0x700 / RAM word copy', 'Direct second RAM port']),
              (780, 'Power / activity', ['0x800 / counters + sleep', 'Selected peripheral enables'])]
    for (x, title, lines), branch_x in zip(bottom, [290, 550, 810]):
        f.arrow([(branch_x, 360), (branch_x, 535), (x + 135, 535), (x + 135, 550)], True)
        f.box(x, 557, 270, 110, title, lines)
    f.note('Solid paths show major integration points; dashed branches are schematic, not a bus protocol.', 687)
    f.save('system-architecture.svg')


def word_order():
    f = Figure('Four 32-bit MMIO stores form one 128-bit AES key',
               'KEY0 is the least significant word and KEY3 is the most significant word of the sample NIST key.', 530)
    words = [('KEY3  @ 0x314', 'bits 127:96 = 00010203'), ('KEY2  @ 0x310', 'bits 95:64  = 04050607'),
             ('KEY1  @ 0x30c', 'bits 63:32  = 08090a0b'), ('KEY0  @ 0x308', 'bits 31:0   = 0c0d0e0f')]
    for i, (title, line) in enumerate(words):
        y = 145 + i * 76
        f.box(50, y, 400, 68, title, [])
        f.text(245, y + 47, line, 14)
        f.arrow([(450, y + 34), (555, y + 34), (555, 310), (620, 310)])
    f.box(630, 245, 420, 135, 'AES key register', ['{ KEY3, KEY2, KEY1, KEY0 }'])
    f.text(646, 345, '000102030405060708090a0b0c0d0e0f', 15)
    f.note('Lowest register number means least-significant word. PT0..PT3 and CT0..CT3 use the same packing.', 497)
    f.save('mmio-word-order.svg')


def interrupts():
    f = Figure('From peripheral completion to software acknowledgement',
               'Six conceptual steps record and mask a peripheral event, expose IRQ status, service the source and clear pending.', 630)
    steps = [(50, 155, '1  Peripheral event', ['AES / UART / sensor / DMA', 'May be a pulse or held level']),
             (410, 155, '2  Sticky pending', ['pending OR source bits', 'Keeps an observed event']),
             (770, 155, '3  Enable mask', ['IRQ = OR(pending & enable)', 'Masking does not erase pending']),
             (770, 355, '4  Read and handle', ['Observe pending / IRQ', 'No CPU trap-handler path here']),
             (410, 355, '5  Clear source flag', ['Acknowledge the peripheral', 'Stop a held level retriggering']),
             (50, 355, '6  Clear INTC bit', ['Write 1 to IRQ_CLEAR', 'Recheck for new events'])]
    for x, y, title, lines in steps:
        f.box(x, y, 280, 115, title, lines)
    f.arrow([(330, 213), (403, 213)])
    f.arrow([(690, 213), (763, 213)])
    f.arrow([(910, 270), (910, 348)])
    f.arrow([(770, 413), (697, 413)])
    f.arrow([(410, 413), (337, 413)])
    f.note('Current logic: (pending | sources) & ~clear_mask. Same-edge clear wins for the selected bit.', 540)
    f.note('This is a conceptual service sequence, not an implemented ISR or automatic wake-up mechanism.', 578)
    f.save('interrupt-sequence.svg')


def verification():
    f = Figure('Independent checks for the AES / UART subsystem',
               'Randomized inputs feed RTL and an independent C AES reference; comparison and UART reconstruction check results.', 680)
    f.box(400, 145, 300, 90, 'Randomized transaction', ['Plaintext / key / nonce / counter'])
    f.arrow([(470, 235), (470, 265), (240, 265), (240, 290)])
    f.arrow([(630, 235), (630, 265), (820, 265), (820, 290)])
    f.box(100, 297, 280, 95, 'RTL AES-CTR', ['MMIO programming by driver'])
    f.box(680, 297, 280, 95, 'Independent C reference', ['DPI expected cipher / decrypt'])
    f.box(420, 432, 270, 95, 'Cipher / decrypt checks', ['Expected versus RTL result'])
    f.arrow([(380, 345), (402, 345), (402, 460), (413, 460)])
    f.arrow([(820, 392), (820, 417), (620, 417), (620, 425)])
    f.box(100, 545, 280, 90, 'UART monitor', ['Reconstruct actual serial TX'])
    f.box(680, 545, 280, 90, 'Scoreboard / coverage', ['Compare transcript + bin hits'])
    f.arrow([(240, 392), (240, 538)])
    f.text(255, 470, 'RTL UART', 15, MUTED)
    f.arrow([(380, 590), (673, 590)])
    f.arrow([(690, 490), (820, 490), (820, 538)])
    f.note('The UVM top contains AES and UART, not the CPU. The full-SoC CPU scenario is a separate test.', 665)
    f.save('verification-flow.svg')


def measurement():
    f = Figure('Keep functional checks, ASIC estimates and FPGA results separate',
               'Three evidence types: standalone AES Genus reports, integrated FPGA fit, and functional simulation.', 480)
    for x, title, lines in [
        (50, 'Standalone AES / ASIC', ['2,694 mapped cells', '11,841.480 um^2', '0.853125 mW estimated', 'Genus / original mapped report']),
        (400, 'Integrated system / FPGA', ['13,257 ALMs', '11,154 registers', '50 MHz timing target', 'Quartus / archived Cyclone V fit']),
        (750, 'Functional simulation', ['Ciphertext and interface checks', 'CPU-driven scenario', 'AES/UART UVM reference match', 'No electrical power measurement'])]:
        f.box(x, 170, 300, 180, title, lines)
    f.note('Different targets and assumptions. These are not interchangeable power-saving measurements.', 411)
    f.save('measurement-scope.svg')


def handshake():
    f = Figure('AES handshake: accept, work, complete, retain',
               'An illustrative timing diagram shows start, busy and done, and labels input acceptance and retained ciphertext.', 520)
    xs = [200 + i * 70 for i in range(12)]
    for x in xs:
        f.parts.append(f'<path d="M{x} 150 L{x} 425" stroke="#D5D0C4" stroke-width="1"/>')
    def wave(label, y, values):
        f.text(50, y + 7, label, 19, TEAL, 'bold')
        points = []
        for i, value in enumerate(values):
            yy = y - 18 if value else y + 18
            if i:
                points.append((xs[i], y - 18 if values[i-1] else y + 18))
            points.append((xs[i], yy))
        path = 'M' + ' L'.join(f'{x} {yy}' for x, yy in points)
        f.parts.append(f'<path d="{path}" fill="none" stroke="{TEAL}" stroke-width="2.5"/>')
    wave('start', 205, [0,1,0,0,0,0,0,0,0,0,0,0])
    wave('busy', 295, [0,1,1,1,1,1,1,1,0,0,0,0])
    wave('done', 385, [0,0,0,0,0,0,0,0,1,0,0,0])
    f.text(265, 143, 'Input accepted', 16, MUTED)
    f.text(570, 260, 'Many internal cycles', 17, MUTED)
    f.text(760, 443, 'Ciphertext retained', 16, MUTED)
    f.note('Illustrative, not to scale. MMIO done is sticky; core done clears after its completion state.', 492)
    f.save('aes-handshake.svg')


if __name__ == '__main__':
    for draw in [roadmap, aes_rounds, architecture, word_order, interrupts, verification, measurement, handshake]:
        draw()
    print(f'Built 8 SVG figures in {OUT}')

"""Check local documentation links, simulator lists, FPGA paths and SVG assets."""
import re
import sys
import xml.etree.ElementTree as ET
from collections import Counter
from pathlib import Path
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]


def heading_ids(text):
    ids, counts, fenced = set(), Counter(), False
    for line in text.splitlines():
        if line.startswith('```'):
            fenced = not fenced
        if fenced:
            continue
        match = re.match(r'^#{1,6}\s+(.+?)\s*#*$', line)
        if match:
            heading = re.sub(r'[^\w\- ]', '', match[1].lower().replace('`', ''))
            slug = heading.replace(' ', '-')
            suffix = f'-{counts[slug]}' if counts[slug] else ''
            ids.add(slug + suffix)
            counts[slug] += 1
    return ids


def check_links(root):
    issues = []
    for file in root.rglob('*.md'):
        if '.git' in file.parts or 'build' in file.parts:
            continue
        text = file.read_text(encoding='utf-8')
        # Remove code fences so example commands are not parsed as links.
        text = re.sub(r'```.*?```', '', text, flags=re.S)
        for match in re.finditer(r'!?\[[^\]]*\]\(([^)\n]+)\)', text):
            raw = match[1].strip().strip('<>')
            parsed = urlsplit(raw)
            if parsed.scheme or parsed.netloc:
                continue
            target = (file.parent / unquote(parsed.path)).resolve() if parsed.path else file
            label = str(file.relative_to(root))
            if not target.exists():
                issues.append(f'{label}: missing link target {raw}')
            elif parsed.fragment and target.suffix == '.md':
                if unquote(parsed.fragment) not in heading_ids(target.read_text(encoding='utf-8')):
                    issues.append(f'{label}: missing heading anchor {raw}')
    return issues


def check_manifests(root):
    issues = []
    for file in (root / 'tb' / 'filelists').glob('*.f'):
        seen = set()
        for line in file.read_text(encoding='utf-8').splitlines():
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            if line in seen:
                issues.append(f'{file.name}: duplicate source {line}')
            if not (root / line).is_file():
                issues.append(f'{file.name}: missing source {line}')
            seen.add(line)
    return issues


def check_qsf(root):
    issues = []
    file = root / 'fpga' / 'quartus' / 'riscv_aes_advancements.qsf'
    for line in file.read_text(encoding='utf-8').splitlines():
        match = re.search(r'-name (SYSTEMVERILOG_FILE|QIP_FILE|SDC_FILE|EDA_TEST_BENCH_FILE)\s+(\S+)', line)
        if match and not (file.parent / match[2].strip('"')).is_file():
            issues.append(f'Quartus: missing {match[1]} {match[2]}')
    return issues


def check_figures(root):
    issues = []
    ns = {'svg': 'http://www.w3.org/2000/svg'}
    for file in (root / 'docs' / 'figures').glob('*.svg'):
        try:
            svg = ET.parse(file).getroot()
            if svg.find('svg:title', ns) is None or svg.find('svg:desc', ns) is None:
                issues.append(f'{file.name}: missing accessible title/description')
            rect = svg.find('svg:rect', ns)
            if rect is None or rect.attrib.get('fill') != '#F5EFE1':
                issues.append(f'{file.name}: background must be #F5EFE1')
        except ET.ParseError as error:
            issues.append(f'{file.name}: invalid SVG: {error}')
    return issues


def run_checks(root=ROOT):
    return check_links(root) + check_manifests(root) + check_qsf(root) + check_figures(root)


if __name__ == '__main__':
    failures = run_checks()
    for failure in failures:
        print('ERROR:', failure)
    if failures:
        sys.exit(1)
    print('PASS: local links/anchors, simulator source lists, Quartus paths and SVG palette/accessibility')

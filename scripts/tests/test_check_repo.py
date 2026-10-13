import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import check_repo


class RepositoryChecks(unittest.TestCase):
    def test_current_repository(self):
        self.assertEqual(check_repo.run_checks(), [])

    def test_heading_ids(self):
        self.assertEqual(check_repo.heading_ids('# One\n## A 32-bit CPU\n## One\n'),
                         {'one', 'a-32-bit-cpu', 'one-1'})

    def test_missing_link_is_detected(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / 'README.md').write_text('[missing](gone.md)\n', encoding='utf-8')
            self.assertTrue(check_repo.check_links(root))

    def test_valid_and_invalid_anchors(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            file = root / 'README.md'
            file.write_text('# Start here\n[read](#start-here)\n', encoding='utf-8')
            self.assertEqual(check_repo.check_links(root), [])
            file.write_text('# Start here\n[read](#wrong)\n', encoding='utf-8')
            self.assertTrue(check_repo.check_links(root))

    def test_missing_manifest_source(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            path = root / 'tb' / 'filelists'
            path.mkdir(parents=True)
            (path / 'soc.f').write_text('missing.sv\n', encoding='utf-8')
            self.assertTrue(check_repo.check_manifests(root))

    def test_wrong_svg_palette(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            path = root / 'docs' / 'figures'
            path.mkdir(parents=True)
            (path / 'bad.svg').write_text('<svg xmlns="http://www.w3.org/2000/svg"><title>x</title><desc>x</desc><rect fill="#ffffff"/></svg>', encoding='utf-8')
            self.assertTrue(check_repo.check_figures(root))


if __name__ == '__main__':
    unittest.main()

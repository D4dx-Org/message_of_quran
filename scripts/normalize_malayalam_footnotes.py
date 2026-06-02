from __future__ import annotations

import argparse
import sqlite3
from pathlib import Path


DB_PATH = Path(__file__).resolve().parent.parent / 'assets' / 'db' / 'quran_asad_malayalam_nw.db'
MALAYALAM_RANGE = ('\u0D00', '\u0D7F')


def _is_malayalam_char(value: str) -> bool:
    return bool(value) and MALAYALAM_RANGE[0] <= value <= MALAYALAM_RANGE[1]


def normalize_footnote_prefix(text: str) -> str:
    stripped = text.lstrip()
    if not stripped:
        return text

    if stripped.startswith('.'):
        candidate = stripped[1:].lstrip()
        if _is_malayalam_char(candidate[:1]):
            return candidate

    if _is_malayalam_char(stripped[:1]):
        return stripped

    return text


def update_footnotes(db_path: Path, dry_run: bool) -> tuple[int, list[tuple[int, int, str, str]]]:
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    rows = cursor.execute(
        'SELECT id, footnote_number, content FROM footnotes ORDER BY id'
    ).fetchall()

    changes: list[tuple[int, int, str, str]] = []
    for row_id, footnote_number, content in rows:
        original = content or ''
        normalized = normalize_footnote_prefix(original)
        if normalized != original:
            changes.append((row_id, footnote_number, original, normalized))

    if not dry_run and changes:
        cursor.executemany(
            'UPDATE footnotes SET content = ? WHERE id = ?',
            [(normalized, row_id) for row_id, _, _, normalized in changes],
        )
        conn.commit()

    conn.close()
    return len(changes), changes[:10]


def main() -> None:
    parser = argparse.ArgumentParser(
        description='Normalize leading dot/space prefixes in Malayalam footnotes.'
    )
    parser.add_argument(
        '--apply',
        action='store_true',
        help='Write the normalized content back to the bundled database asset.',
    )
    args = parser.parse_args()

    count, samples = update_footnotes(DB_PATH, dry_run=not args.apply)

    mode = 'apply' if args.apply else 'dry-run'
    print(f'mode={mode}')
    print(f'database={DB_PATH}')
    print(f'updated_rows={count}')
    if not samples:
        print('No changes needed.')
        return

    print('sample_changes=')
    for row_id, footnote_number, original, normalized in samples:
        print(
            f'  id={row_id} footnote_number={footnote_number}\n'
            f'    before={original[:80]!r}\n'
            f'    after ={normalized[:80]!r}'
        )


if __name__ == '__main__':
    main()
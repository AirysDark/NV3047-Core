#!/usr/bin/env python3
"""Compare a rebuilt ESP32-S3 SDK tree with the repository baseline.

The comparison is content-addressed and deterministic: regular files are
compared by SHA-256. versions.txt is outside the esp32s3 subtree and therefore
not part of this target comparison.

By default differences are reported but do not fail. Use --require-identical
when the historical rebuild has been proven deterministic enough to make exact
identity a CI gate.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def scan(root: Path) -> dict[str, tuple[int, str]]:
    result: dict[str, tuple[int, str]] = {}
    for p in sorted(root.rglob("*")):
        if p.is_file():
            rel = p.relative_to(root).as_posix()
            result[rel] = (p.stat().st_size, sha256(p))
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("baseline", type=Path)
    parser.add_argument("rebuilt", type=Path)
    parser.add_argument("--json", type=Path)
    parser.add_argument("--require-identical", action="store_true")
    args = parser.parse_args()

    for p in (args.baseline, args.rebuilt):
        if not p.is_dir():
            raise SystemExit(f"Not a directory: {p}")

    base = scan(args.baseline)
    new = scan(args.rebuilt)
    paths = sorted(set(base) | set(new))

    same: list[str] = []
    changed: list[dict[str, object]] = []
    missing: list[str] = []
    extra: list[str] = []

    for rel in paths:
        b = base.get(rel)
        n = new.get(rel)
        if b is None:
            extra.append(rel)
        elif n is None:
            missing.append(rel)
        elif b == n:
            same.append(rel)
        else:
            changed.append(
                {
                    "path": rel,
                    "baseline_size": b[0],
                    "rebuilt_size": n[0],
                    "baseline_sha256": b[1],
                    "rebuilt_sha256": n[1],
                }
            )

    summary = {
        "baseline_files": len(base),
        "rebuilt_files": len(new),
        "same": len(same),
        "changed": len(changed),
        "missing": len(missing),
        "extra": len(extra),
        "identical": not (changed or missing or extra),
    }

    report = {
        "summary": summary,
        "changed": changed,
        "missing": missing,
        "extra": extra,
    }

    print(json.dumps(summary, indent=2))
    if changed:
        print("\nChanged files:")
        for item in changed[:100]:
            print(
                f"  {item['path']} "
                f"({item['baseline_size']} -> {item['rebuilt_size']} bytes)"
            )
        if len(changed) > 100:
            print(f"  ... {len(changed) - 100} more")
    if missing:
        print("\nMissing files:")
        for rel in missing[:100]:
            print(f"  {rel}")
    if extra:
        print("\nExtra files:")
        for rel in extra[:100]:
            print(f"  {rel}")

    if args.json:
        args.json.parent.mkdir(parents=True, exist_ok=True)
        args.json.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")

    if args.require_identical and not summary["identical"]:
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

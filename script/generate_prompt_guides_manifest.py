#!/usr/bin/env python3
import argparse
import datetime as dt
import hashlib
import json
from pathlib import Path
import sys


REQUIRED_FIELDS = {"id", "displayName", "aliases", "modality", "tasks", "summary"}


def parse_front_matter(text):
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        raise ValueError("missing front matter")

    values = {}
    key = None
    for line in lines[1:]:
        stripped = line.strip()
        if stripped == "---":
            return values
        if not stripped:
            continue
        if stripped.startswith("- "):
            if key is None:
                raise ValueError("list item without key")
            values.setdefault(key, []).append(stripped[2:].strip())
            continue
        if ":" not in line:
            raise ValueError(f"invalid front matter line: {line}")
        key, raw_value = line.split(":", 1)
        key = key.strip()
        raw_value = raw_value.strip()
        values[key] = raw_value if raw_value else []

    raise ValueError("unterminated front matter")


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def guide_entry(root, path):
    text = path.read_text(encoding="utf-8")
    meta = parse_front_matter(text)
    missing = sorted(REQUIRED_FIELDS - set(meta))
    if missing:
        raise ValueError(f"missing required fields: {', '.join(missing)}")

    for list_key in ("aliases", "tasks"):
        if not isinstance(meta[list_key], list) or not meta[list_key]:
            raise ValueError(f"{list_key} must be a non-empty list")

    relative_path = path.relative_to(root).as_posix()
    stat = path.stat()
    return {
        "id": meta["id"],
        "displayName": meta["displayName"],
        "aliases": meta["aliases"],
        "modality": meta["modality"],
        "tasks": meta["tasks"],
        "summary": meta["summary"],
        "path": relative_path,
        "bytes": stat.st_size,
        "sha256": sha256(path),
    }


def main():
    parser = argparse.ArgumentParser(description="Generate FuguFableFlow prompt guide manifest.")
    parser.add_argument(
        "--root",
        default="prompt-guides",
        help="Prompt guide root folder. Default: prompt-guides",
    )
    args = parser.parse_args()

    root = Path(args.root).resolve()
    guides_dir = root / "guides"
    manifest_path = root / "manifest.json"
    if not guides_dir.exists():
        print(f"Missing guide folder: {guides_dir}", file=sys.stderr)
        return 2

    entries = []
    errors = []
    for path in sorted(guides_dir.rglob("*.md")):
        try:
            entries.append(guide_entry(root, path))
        except ValueError as error:
            errors.append(f"{path.relative_to(root)}: {error}")

    if errors:
        print("Manifest generation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    manifest = {
        "schemaVersion": 1,
        "generatedAt": dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "guides": entries,
    }
    manifest_path.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"Wrote {manifest_path} with {len(entries)} guide(s).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

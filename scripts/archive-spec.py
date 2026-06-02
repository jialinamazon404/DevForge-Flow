#!/usr/bin/env python3
"""Archive a spec by updating its YAML frontmatter status.

Usage: scripts/archive-spec.py <issue-number> implemented [pr-number]
   or: scripts/archive-spec.py <issue-number> deprecated [reason]

The script reads specs/issue-<N>/product.md, adds or updates the YAML
frontmatter with the given status, and writes it back in-place.

Status values: active (default), implemented, deprecated
"""

import argparse
import re
import sys
from datetime import date
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[1]


FRONTMATTER_RE = re.compile(
    r"^---\s*\n(.*?)\n---\s*\n",
    re.DOTALL,
)
FRONTMATTER_FIELD_RE = re.compile(r"^(\w+):\s*(.*)$", re.MULTILINE)


def read_product_md(issue_number: int) -> tuple[Path, str | None, dict[str, str], str]:
    path = REPO_ROOT / "specs" / f"issue-{issue_number}" / "product.md"
    if not path.exists():
        print(f"Error: {path} not found", file=sys.stderr)
        sys.exit(1)

    text = path.read_text(encoding="utf-8")
    match = FRONTMATTER_RE.match(text)

    if match:
        raw = match.group(1)
        body = text[match.end():]
        fields = {}
        for fm_match in FRONTMATTER_FIELD_RE.finditer(raw):
            fields[fm_match.group(1)] = fm_match.group(2).strip()
        return path, raw, fields, body
    else:
        return path, None, {}, text


def write_frontmatter(
    path: Path,
    issue_number: int,
    status: str,
    pr_number: str | None,
    reason: str | None,
) -> None:
    _, existing_raw, fields, body = read_product_md(issue_number)
    today = date.today().isoformat()

    fields["status"] = status
    fields["issue"] = str(issue_number)

    if "created_at" not in fields:
        fields["created_at"] = today

    if status == "implemented":
        fields["implemented_at"] = fields.get("implemented_at", "") or today
        if pr_number:
            fields["implementation_pr"] = pr_number
    elif status == "deprecated":
        fields["deprecated_at"] = fields.get("deprecated_at", "") or today
        if reason:
            fields["deprecation_reason"] = reason
    elif status == "active":
        pass

    frontmatter_lines = ["---"]
    for key in ("status", "issue", "created_at", "implemented_at",
                "implementation_pr", "deprecated_at", "deprecation_reason"):
        val = fields.get(key, "")
        if val or key in ("status", "issue", "created_at"):
            frontmatter_lines.append(f"{key}: {val}")
    frontmatter_lines.append("---")

    new_text = "\n".join(frontmatter_lines) + "\n\n" + body.lstrip("\n")
    path.write_text(new_text, encoding="utf-8")

    print(f"Updated {path}")
    print(f"  status: {status}")
    print(f"  issue: #{issue_number}")
    if pr_number:
        print(f"  implementation_pr: #{pr_number}")
    if reason:
        print(f"  reason: {reason}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Archive a spec")
    parser.add_argument("issue", type=int, help="Issue number")
    parser.add_argument("status", choices=["active", "implemented", "deprecated"],
                        help="New spec status")
    parser.add_argument("value", nargs="?", default="",
                        help="PR number (for implemented) or reason (for deprecated)")
    args = parser.parse_args()

    pr_number = args.value if args.status == "implemented" and args.value else None
    reason = args.value if args.status == "deprecated" and args.value else None

    path, _, _, _ = read_product_md(args.issue)
    write_frontmatter(path, args.issue, args.status, pr_number, reason)


if __name__ == "__main__":
    main()

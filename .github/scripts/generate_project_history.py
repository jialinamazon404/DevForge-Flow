#!/usr/bin/env python3
"""Generate PROJECT-HISTORY.md from all specs in the specs/ directory."""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
SPECS_DIR = REPO_ROOT / "specs"
OUTPUT_FILE = REPO_ROOT / "docs" / "PROJECT-HISTORY.md"

SUMMARY_RE = re.compile(r"^##\s+1\.\s*Summary", re.MULTILINE)
TITLE_RE = re.compile(r"^#\s+(.+)", re.MULTILINE)
FRONTMATTER_RE = re.compile(
    r"^---\s*\n(.*?)\n---\s*\n",
    re.DOTALL,
)
FRONTMATTER_FIELD_RE = re.compile(r"^(\w+):\s*(.*)$", re.MULTILINE)


def get_git_date(filepath: Path) -> str | None:
    """Get the author date of the first commit that added this file."""
    try:
        rel = filepath.relative_to(REPO_ROOT)
        result = subprocess.run(
            ["git", "log", "--follow", "--diff-filter=A", "--format=%aI", "--", str(rel)],
            capture_output=True,
            text=True,
            check=True,
            cwd=REPO_ROOT,
        )
        dates = [d.strip() for d in result.stdout.strip().splitlines() if d.strip()]
        if dates:
            dt = datetime.fromisoformat(dates[0])
            return dt.strftime("%Y-%m-%d")
    except (subprocess.CalledProcessError, ValueError, OSError):
        pass
    return None


def extract_title(text: str) -> str | None:
    m = TITLE_RE.search(text)
    return m.group(1).strip() if m else None


def parse_frontmatter(text: str) -> dict[str, str]:
    m = FRONTMATTER_RE.match(text)
    if not m:
        return {}
    fields = {}
    for fm_match in FRONTMATTER_FIELD_RE.finditer(m.group(1)):
        fields[fm_match.group(1)] = fm_match.group(2).strip()
    return fields


def extract_summary(text: str) -> str | None:
    m = SUMMARY_RE.search(text)
    if not m:
        return None
    # Collect lines after the heading until a blank line or next heading
    after = text[m.end():].lstrip("\n")
    lines = []
    for line in after.splitlines():
        stripped = line.strip()
        if not stripped:
            break
        if stripped.startswith("## "):
            break
        lines.append(stripped)
    return " ".join(lines) if lines else None


def collect_specs() -> list[dict]:
    specs: list[dict] = []
    product_paths = sorted(SPECS_DIR.glob("issue-*/product.md"))

    for path in product_paths:
        issue_dir = path.parent
        issue_match = re.search(r"issue-(\d+)", issue_dir.name)
        issue_num = int(issue_match.group(1)) if issue_match else None

        tech_path = issue_dir / "tech.md"
        has_tech = tech_path.exists()

        text = path.read_text(encoding="utf-8")
        title = extract_title(text)
        summary = extract_summary(text)
        created = get_git_date(path)
        frontmatter = parse_frontmatter(text)
        status = frontmatter.get("status", "unknown")
        fm_created = frontmatter.get("created_at")

        specs.append({
            "issue": issue_num,
            "title": title or f"Issue #{issue_num}" if issue_num else "Unknown",
            "summary": summary or "No summary found.",
            "created": fm_created or created or "Unknown",
            "has_tech": has_tech,
            "status": status,
            "product_path": str(path.relative_to(REPO_ROOT)),
            "tech_path": str(tech_path.relative_to(REPO_ROOT)) if has_tech else None,
            "text": text,
        })

    return specs


def generate_markdown(specs: list[dict], *, no_timestamp: bool = False) -> str:
    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    total = len(specs)

    lines: list[str] = []
    lines.append("# Project History")
    lines.append("")
    if not no_timestamp:
        lines.append(f"> 生成时间: {now} | 共 {total} 个 Spec")
        lines.append("")
    lines.append("## Spec 列表")
    lines.append("")
    lines.append("| Issue | 标题 | 状态 | 创建时间 | 文件 |")
    lines.append("|-------|------|------|----------|------|")

    for spec in specs:
        issue_link = f"#{spec['issue']}" if spec["issue"] else "-"
        title = spec["title"]
        status = spec["status"]
        created = spec["created"]
        files = f"[product.md]({spec['product_path']})"
        if spec["has_tech"]:
            files += f" / [tech.md]({spec['tech_path']})"
        lines.append(f"| {issue_link} | {title} | {status} | {created} | {files} |")

    lines.append("")
    lines.append("> 状态说明: `active` = 进行中 | `implemented` = 已实现 | `deprecated` = 已弃用 | `unknown` = 未标记")
    lines.append("")

    lines.append("## 详情")
    lines.append("")

    for spec in specs:
        issue_label = f"#{spec['issue']}" if spec["issue"] else "?"
        lines.append(f"### {issue_label} — {spec['title']}")
        lines.append("")
        lines.append(f"- **状态:** {spec['status']}")
        lines.append(f"- **创建时间:** {spec['created']}")
        lines.append(f"- **Issue:** #{spec['issue']}" if spec['issue'] else "- **Issue:** -")
        lines.append(f"- **Product spec:** [`{spec['product_path']}`]({spec['product_path']})")
        if spec["has_tech"]:
            lines.append(f"- **Tech spec:** [`{spec['tech_path']}`]({spec['tech_path']})")
        else:
            lines.append("- **Tech spec:** 无")
        summary = spec["summary"]
        if summary:
            lines.append(f"- **摘要:** {summary}")
        lines.append("")

    return "\n".join(lines) + "\n"


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate PROJECT-HISTORY.md from specs")
    parser.add_argument(
        "--check",
        action="store_true",
        help="Check if the output would differ from the current file (exit 1 if changed)",
    )
    args = parser.parse_args()

    specs = collect_specs()
    if not specs:
        print("No specs found.", file=sys.stderr)
        sys.exit(1)

    markdown = generate_markdown(specs)

    if args.check:
        clean = generate_markdown(specs, no_timestamp=True)
        if OUTPUT_FILE.exists():
            current_lines = OUTPUT_FILE.read_text(encoding="utf-8").splitlines()
            # Strip the timestamp line (index 2) and its trailing empty line (index 3)
            current_clean = "\n".join(
                line for i, line in enumerate(current_lines) if i not in (2, 3)
            ) + "\n"
            if current_clean == clean:
                print("Project history is up to date.")
                return
            print("Project history is out of date. Regenerate with generate_project_history.py")
            sys.exit(1)
        print("Project history does not exist yet. Generate with generate_project_history.py")
        sys.exit(1)

    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_FILE.write_text(markdown, encoding="utf-8")
    print(f"Generated {OUTPUT_FILE.relative_to(REPO_ROOT)} ({len(specs)} specs)")


if __name__ == "__main__":
    main()

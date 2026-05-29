#!/usr/bin/env python3
"""Verify implementation against spec for a given issue.

Usage: scripts/verify-impl.sh <issue-number> [base-ref]

Reads specs/issue-<N>/product.md and tech.md, compares with git diff
between HEAD and base-ref (default: main), and outputs a structured report.

This is a local-only tool. It does not require gh, GitHub Actions, or AI.
"""

import argparse
import re
import subprocess
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
SPECS_DIR = REPO_ROOT / "specs"


SECTION_RE = re.compile(r"^##\s+(\d+)\.\s*(.+)$", re.MULTILINE)
SUBSECTION_RE = re.compile(r"^###\s+(.+)$", re.MULTILINE)
CHECKBOX_RE = re.compile(r"^-\s*\[\s*[ xX]?\s*\]\s*(.+)$", re.MULTILINE)
BULLET_RE = re.compile(r"^-\s+(.+)$", re.MULTILINE)


def read_file(path: Path) -> str | None:
    if not path.exists():
        return None
    return path.read_text(encoding="utf-8")


def extract_section(text: str, section_num: int) -> str | None:
    """Extract a top-level section (e.g. ## 7. Success criteria) from markdown."""
    sections = list(SECTION_RE.finditer(text))
    for i, match in enumerate(sections):
        if match.group(1) == str(section_num):
            start = match.end()
            end = sections[i + 1].start() if i + 1 < len(sections) else len(text)
            return text[start:end].strip()
    return None


def extract_checkboxes(text: str) -> list[str]:
    """Extract - [ ] items as acceptance criteria checkboxes."""
    return [m.group(1).strip() for m in CHECKBOX_RE.finditer(text)]


def extract_bullets(text: str) -> list[str]:
    """Extract - items that are not checkboxes."""
    checkbox_positions = {m.start() for m in CHECKBOX_RE.finditer(text)}
    bullets = []
    for m in BULLET_RE.finditer(text):
        if m.start() not in checkbox_positions:
            bullets.append(m.group(1).strip())
    return bullets


def extract_file_paths(text: str) -> list[str]:
    """Extract likely file paths from tech spec text."""
    paths = re.findall(r"`([^`]+)`", text)
    return [p for p in paths if "/" in p and not p.startswith("http")]


def get_git_diff(base_ref: str = "main") -> str | None:
    try:
        result = subprocess.run(
            ["git", "diff", f"{base_ref}...HEAD", "--stat"],
            capture_output=True, text=True, check=True,
            cwd=REPO_ROOT,
        )
        return result.stdout.strip() or None
    except subprocess.CalledProcessError:
        return None


def get_changed_files(base_ref: str = "main") -> list[str]:
    try:
        result = subprocess.run(
            ["git", "diff", f"{base_ref}...HEAD", "--name-only"],
            capture_output=True, text=True, check=True,
            cwd=REPO_ROOT,
        )
        return [f.strip() for f in result.stdout.strip().splitlines() if f.strip()]
    except subprocess.CalledProcessError:
        return []


def verify_impl(issue_number: int, base_ref: str) -> dict:
    issue_dir = SPECS_DIR / f"issue-{issue_number}"
    product_text = read_file(issue_dir / "product.md")
    tech_text = read_file(issue_dir / "tech.md")

    if not product_text:
        return {"error": f"product.md not found for issue #{issue_number}"}

    product_title = ""
    title_match = re.search(r"^#\s+(.+)$", product_text, re.MULTILINE)
    if title_match:
        product_title = title_match.group(1).strip()

    criteria = extract_checkboxes(extract_section(product_text, 7) or "")
    if not criteria:
        criteria = extract_checkboxes(product_text)

    tech_section_4 = extract_section(tech_text, 4) if tech_text else None
    expected_files = extract_file_paths(tech_section_4 or (tech_text or ""))

    changed_files = get_changed_files(base_ref)
    diff_stat = get_git_diff(base_ref)

    matched_files = [f for f in expected_files if f in changed_files]
    unmatched_files = [f for f in expected_files if f not in changed_files]

    return {
        "issue_number": issue_number,
        "product_title": product_title,
        "criteria": criteria,
        "expected_files": expected_files,
        "matched_files": matched_files,
        "unmatched_files": unmatched_files,
        "changed_files": changed_files,
        "diff_stat": diff_stat,
    }


def format_report(result: dict) -> str:
    if "error" in result:
        return f"❌ Error: {result['error']}\n"

    lines: list[str] = []
    lines.append("# Implementation Verification Report")
    lines.append("")
    lines.append(f"**Issue:** #{result['issue_number']} — {result['product_title']}")
    lines.append("")
    lines.append("---")
    lines.append("")

    # Acceptance criteria
    lines.append("## 📋 Acceptance Criteria")
    lines.append("")
    criteria = result["criteria"]
    if criteria:
        for i, c in enumerate(criteria, 1):
            lines.append(f"- [ ] #{i}: {c}")
        lines.append("")
        lines.append(f"> ⚠️  Mark each checkbox after manual verification.")
    else:
        lines.append("(No structured acceptance criteria found.)")
    lines.append("")

    lines.append("---")
    lines.append("")

    # Expected vs actual file changes
    lines.append("## 📄 File Changes")
    lines.append("")
    unmatched = result["unmatched_files"]
    matched = result["matched_files"]

    if matched:
        lines.append("### ✅ Matched (expected in tech spec, found in diff)")
        for f in matched:
            lines.append(f"- `{f}`")
        lines.append("")

    if unmatched:
        lines.append("### ❌ Not in diff (expected in tech spec, not found)")
        for f in unmatched:
            lines.append(f"- `{f}`")
        lines.append("")

    if result["expected_files"]:
        lines.append("> Note: File path extraction is heuristic. Some relevant files may be missed.")
        lines.append("")
    else:
        lines.append("(No file paths extracted from tech spec Section 4.)")
        lines.append("")

    lines.append("### Changed files in this branch")
    lines.append("")
    for f in result["changed_files"]:
        lines.append(f"- `{f}`")

    lines.append("")
    lines.append("---")
    lines.append("")

    # Diff stats
    lines.append("## 📊 Diff Summary")
    lines.append("")
    if result["diff_stat"]:
        lines.append("```")
        lines.append(result["diff_stat"])
        lines.append("```")
    else:
        lines.append("(No diff or unable to compute.)")
    lines.append("")

    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description="Verify implementation against spec")
    parser.add_argument("issue", type=int, help="Issue number")
    parser.add_argument("--base", default="main", help="Base ref for git diff (default: main)")
    args = parser.parse_args()

    result = verify_impl(args.issue, args.base)
    report = format_report(result)
    print(report)


if __name__ == "__main__":
    main()

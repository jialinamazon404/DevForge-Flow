#!/usr/bin/env python3
"""Update spec frontmatter status and create an archive PR.

Usage:
  # From workflow_dispatch (manual)
  python3 archive_spec.py --issue 42 --status implemented --pr-number 123 --repo owner/repo

  # From PR merge event
  python3 archive_spec.py --status implemented --repo owner/repo --github-output "$GITHUB_OUTPUT"

In PR merge mode, the script parses the issue number from the merged PR body
(Closes #N) and auto-sets implemented status.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import tempfile
from datetime import date
from pathlib import Path
from typing import Any


FRONTMATTER_RE = re.compile(
    r"^---\s*\n(.*?)\n---\s*\n",
    re.DOTALL,
)
FRONTMATTER_FIELD_RE = re.compile(r"^(\w+):\s*(.*)$", re.MULTILINE)
ISSUE_FROM_TEXT_RE = re.compile(
    r"(?<![A-Za-z0-9-])(?:close[sd]?|fix(?:e[sd])?|resolve[sd]?)\s+#(\d+)",
    re.IGNORECASE,
)
ARCHIVE_BRANCH_PREFIX = "feat/archive-spec"


def run_gh(args: list[str], *, capture: bool = False) -> str:
    result = subprocess.run(
        ["gh", *args],
        check=True,
        stdout=subprocess.PIPE if capture else None,
        stderr=subprocess.PIPE if capture else None,
        text=True,
    )
    return result.stdout.strip() if capture else ""


def parse_issue_from_pr(repo: str, pr_number: int) -> int | None:
    pr = json.loads(
        run_gh(
            ["api", f"repos/{repo}/pulls/{pr_number}", "--jq", "{body, title, headRef: .head.ref}"],
            capture=True,
        )
    )
    for text in [pr.get("body") or "", pr.get("title") or "", pr.get("headRef") or ""]:
        m = ISSUE_FROM_TEXT_RE.search(text)
        if m:
            return int(m.group(1))
    return None


def fetch_product_md(repo: str, issue_number: int, ref: str) -> str | None:
    try:
        return run_gh(
            ["api", f"repos/{repo}/contents/specs/issue-{issue_number}/product.md?ref={ref}"],
            capture=True,
        )
    except subprocess.CalledProcessError:
        return None


def read_product_md_text(text: str) -> tuple[dict[str, str], str]:
    match = FRONTMATTER_RE.match(text)
    if match:
        raw = match.group(1)
        body = text[match.end():]
        fields = {}
        for fm_match in FRONTMATTER_FIELD_RE.finditer(raw):
            fields[fm_match.group(1)] = fm_match.group(2).strip()
        return fields, body
    return {}, text


def build_archive_frontmatter(
    existing_fields: dict[str, str],
    issue_number: int,
    status: str,
    pr_number: str | None = None,
    reason: str | None = None,
) -> str:
    today = date.today().isoformat()
    fields = dict(existing_fields)

    fields.setdefault("status", "active")
    fields.setdefault("issue", str(issue_number))
    fields.setdefault("created_at", today)

    if status == "implemented":
        fields["status"] = "implemented"
        if not fields.get("implemented_at"):
            fields["implemented_at"] = today
        if pr_number:
            fields["implementation_pr"] = pr_number
    elif status == "deprecated":
        fields["status"] = "deprecated"
        if not fields.get("deprecated_at"):
            fields["deprecated_at"] = today
        if reason:
            fields["deprecation_reason"] = reason

    lines = ["---"]
    for key in ("status", "issue", "created_at", "implemented_at",
                "implementation_pr", "deprecated_at", "deprecation_reason"):
        val = fields.get(key, "")
        if val or key in ("status", "issue", "created_at"):
            lines.append(f"{key}: {val}")
    lines.append("---")
    return "\n".join(lines)


def find_base64_content(api_response: str) -> tuple[str, str] | None:
    try:
        data = json.loads(api_response)
        if isinstance(data, dict) and data.get("encoding") == "base64" and data.get("content"):
            import base64
            content = base64.b64decode(data["content"]).decode("utf-8")
            sha = data.get("sha", "")
            return content, sha
    except (json.JSONDecodeError, UnicodeDecodeError):
        pass
    return None


def archive_spec(
    repo: str,
    issue_number: int,
    status: str,
    pr_number: str | None,
    reason: str | None,
    default_branch: str,
    author_name: str,
    author_email: str,
) -> dict[str, str]:
    branch = f"{ARCHIVE_BRANCH_PREFIX}-{issue_number}"

    # Fetch current product.md from default branch
    api_result = fetch_product_md(repo, issue_number, default_branch)
    if not api_result:
        return {"changed": "false", "skip_reason": f"specs/issue-{issue_number}/product.md not found"}

    decoded = find_base64_content(api_result)
    if not decoded:
        return {"changed": "false", "skip_reason": "unable to decode product.md"}

    current_text, file_sha = decoded
    existing_fields, body = read_product_md_text(current_text)

    if existing_fields.get("status") == status:
        return {"changed": "false", "skip_reason": f"spec is already {status}"}

    frontmatter = build_archive_frontmatter(existing_fields, issue_number, status, pr_number, reason)
    new_text = frontmatter + "\n\n" + body.lstrip("\n")

    # Checkout default branch, write, commit, push, PR
    worktree_dir = tempfile.mkdtemp(prefix="archive-worktree-")
    worktree = Path(worktree_dir)
    run_gh(["repo", "clone", repo, "--", "--depth=1", "--branch", default_branch, str(worktree)])

    spec_path = worktree / "specs" / f"issue-{issue_number}" / "product.md"
    spec_path.parent.mkdir(parents=True, exist_ok=True)
    spec_path.write_text(new_text, encoding="utf-8")

    subprocess.run(["git", "config", "user.name", author_name], cwd=worktree, capture_output=True)
    subprocess.run(["git", "config", "user.email", author_email], cwd=worktree, capture_output=True)

    # Check if remote branch exists, create/switch accordingly
    ls_remote = subprocess.run(
        ["git", "ls-remote", "--exit-code", "--heads", "origin", branch],
        cwd=worktree, capture_output=True,
    )
    if ls_remote.returncode == 0:
        subprocess.run(["git", "fetch", "origin", branch], cwd=worktree, capture_output=True)
        subprocess.run(["git", "switch", branch], cwd=worktree, capture_output=True)
        # Overwrite with our version
        spec_path.write_text(new_text, encoding="utf-8")

    subprocess.run(["git", "add", str(spec_path.relative_to(worktree))], cwd=worktree, capture_output=True)

    changed = subprocess.run(
        ["git", "diff", "--cached", "--exit-code"],
        cwd=worktree, capture_output=True,
    ).returncode != 0

    if not changed:
        return {"changed": "false", "skip_reason": "no changes to commit"}

    title = f"chore(spec): archive issue #{issue_number} as {status}"
    body = (
        f"This PR archives spec #{issue_number} as **{status}**.\n\n"
        f"Refs #{issue_number}\n"
    )
    if pr_number:
        body += f"The implementation was completed in PR #{pr_number}.\n"
    if reason:
        body += f"\nReason: {reason}\n"

    subprocess.run(["git", "commit", "-m", title], cwd=worktree, check=True)
    subprocess.run(["git", "push", "-u", "origin", branch], cwd=worktree, check=True)

    # Create or update PR
    existing_pr = json.loads(
        run_gh(
            [
                "api",
                f"repos/{repo}/pulls?state=open&head={repo.split('/')[0]}:{branch}",
            ],
            capture=True,
        )
    )
    if isinstance(existing_pr, list) and existing_pr:
        pr_number_str = str(existing_pr[0]["number"])
        run_gh(["pr", "edit", pr_number_str, "--repo", repo, "--title", title, "--body", body])
    else:
        pr_url = run_gh(
            ["pr", "create", "--repo", repo, "--base", default_branch, "--head", branch,
             "--title", title, "--body", body],
            capture=True,
        )

    return {"changed": "true", "branch": branch, "sha": ""}


def load_event(path: str | None) -> dict[str, Any]:
    if not path:
        return {}
    return json.loads(Path(path).read_text(encoding="utf-8"))


def write_github_output(path: str | None, values: dict[str, str]) -> None:
    if not path:
        return
    with Path(path).open("a", encoding="utf-8") as handle:
        for key, value in values.items():
            handle.write(f"{key}={value}\n")


def main() -> None:
    parser = argparse.ArgumentParser(description="Archive a spec")
    parser.add_argument("--repo", default=os.environ.get("GITHUB_REPOSITORY", ""))
    parser.add_argument("--issue", type=int, default=0, help="Issue number")
    parser.add_argument("--status", default="implemented", choices=["implemented", "deprecated"])
    parser.add_argument("--pr-number", default="", help="Implementation PR number")
    parser.add_argument("--reason", default="", help="Deprecation reason")
    parser.add_argument("--default-branch", default="main")
    parser.add_argument("--event-path", default=os.environ.get("GITHUB_EVENT_PATH", ""))
    parser.add_argument("--author-name", default="github-actions[bot]")
    parser.add_argument("--author-email", default="41898282+github-actions[bot]@users.noreply.github.com")
    parser.add_argument("--github-output", default=os.environ.get("GITHUB_OUTPUT", ""))
    args = parser.parse_args()

    event = load_event(args.event_path)

    # Resolve issue number
    issue_number = args.issue
    pr_number = args.pr_number

    # Auto-detect from merge event
    if not issue_number and event.get("action") == "closed" and event.get("pull_request", {}).get("merged"):
        merged_pr = event["pull_request"]
        issue_number = parse_issue_from_pr(args.repo, int(merged_pr["number"])) or 0
        pr_number = str(merged_pr["number"])
        if issue_number and not args.status:
            args.status = "implemented"

    if not issue_number:
        print("issue number is required (pass --issue or trigger from a merged PR with Closes #N)")
        write_github_output(args.github_output, {"changed": "false", "skip_reason": "missing issue number"})
        return

    result = archive_spec(
        args.repo, issue_number, args.status,
        pr_number or None, args.reason or None,
        args.default_branch,
        args.author_name, args.author_email,
    )
    for key, value in result.items():
        print(f"{key}={value}")
    write_github_output(args.github_output, result)


if __name__ == "__main__":
    main()

from __future__ import annotations
import subprocess
from dataclasses import dataclass
from pathlib import Path

@dataclass(frozen=True)
class GitCommit:
    commit_hash: str
    subject: str

def run_git(repo: Path, *args: str) -> str:
    p = subprocess.run(
        ["git", *args],
        cwd=repo,
        text=True,
        encoding="utf-8",
        errors="replace",
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if p.returncode != 0:
        message = p.stderr.strip() or p.stdout.strip()
        raise RuntimeError(f"Commande Git échouée : git {' '.join(args)}\n{message}")
    return p.stdout.strip()

def ensure_git_repository(repo: Path) -> None:
    if run_git(repo, "rev-parse", "--is-inside-work-tree").lower() != "true":
        raise RuntimeError(f"{repo} n'est pas un dépôt Git.")

def has_uncommitted_changes(repo: Path) -> bool:
    return bool(run_git(repo, "status", "--porcelain"))

def get_commits_for_path(repo: Path, relative_path: str, revision_range: str | None = None) -> list[GitCommit]:
    args = ["log", "--reverse", "--pretty=format:%H%x1f%s"]
    if revision_range:
        args.append(revision_range)
    args.extend(["--", relative_path])

    output = run_git(repo, *args)
    commits: list[GitCommit] = []
    for line in output.splitlines():
        commit_hash, sep, subject = line.partition("\x1f")
        if sep:
            commits.append(GitCommit(commit_hash, subject))
    return commits

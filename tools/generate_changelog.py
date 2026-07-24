from __future__ import annotations
import argparse
import re
from dataclasses import dataclass

from git_utils import ensure_git_repository, get_commits_for_path
from utils import lua_quote, project_root, read_package_version, read_text, write_text

COMMIT_RE = re.compile(r"^(add|fix|remove)\(([^)]+)\)\s*:\s*(.+?)\s*$", re.IGNORECASE)
MARKERS = {"add": "+", "fix": "~", "remove": "-"}
LABELS = {"add": "Ajout", "fix": "Modification", "remove": "Suppression"}

@dataclass(frozen=True)
class Change:
    kind: str
    description: str

    @property
    def rendered(self) -> str:
        return f"{MARKERS[self.kind]} {LABELS[self.kind]} : {self.description}"

def parse_changes(package_name: str, package_path: str, revision_range: str | None) -> list[Change]:
    commits = get_commits_for_path(project_root(), package_path, revision_range)
    changes = []
    for commit in commits:
        match = COMMIT_RE.match(commit.subject)
        if not match:
            continue
        kind, scope, description = match.groups()
        if scope.strip().lower() == package_name.lower():
            changes.append(Change(kind.lower(), description.strip()))
    return changes

def extract_existing_strings(text: str) -> set[str]:
    return set(re.findall(r'"((?:\\.|[^"\\])*)"', text))

def prepend_entry(existing_text: str, version: str, changes: list[Change]) -> str:
    entry = [
        "    {",
        f'        version = "{lua_quote(version)}",',
        "        changes = {",
    ]
    entry += [f'            "{lua_quote(change.rendered)}",' for change in changes]
    entry += ["        },", "    },"]

    stripped = existing_text.strip()
    if not stripped:
        return "return {\n" + "\n".join(entry) + "\n}\n"

    if not stripped.startswith("return"):
        raise ValueError("Le changelog existant ne commence pas par 'return'.")

    brace = stripped.find("{")
    if brace < 0:
        raise ValueError("Structure Lua invalide.")

    return stripped[:brace + 1] + "\n" + "\n".join(entry) + "\n" + stripped[brace + 1:].lstrip() + "\n"

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("package")
    parser.add_argument("--since")
    args = parser.parse_args()

    root = project_root()
    ensure_git_repository(root)

    package = args.package.strip()
    package_dir = root / "packages" / package
    package_file = package_dir / "package.lua"
    changelog_file = package_dir / "changelog.lua"

    if not package_dir.is_dir():
        raise FileNotFoundError(f"Package introuvable : {package_dir}")

    version = read_package_version(package_file)
    revision_range = f"{args.since}..HEAD" if args.since else None
    package_path = package_dir.relative_to(root).as_posix()

    existing = read_text(changelog_file) if changelog_file.exists() else ""
    existing_strings = extract_existing_strings(existing)

    changes = [
        change for change in parse_changes(package, package_path, revision_range)
        if change.rendered not in existing_strings
    ]

    if not changes:
        print(f"Aucun nouveau commit add/fix/remove({package}) à ajouter.")
        return 0

    if re.search(rf'version\s*=\s*"{re.escape(version)}"', existing):
        raise RuntimeError(
            f"La version {version} existe déjà dans changelog.lua. "
            "Incrémente d'abord la version dans package.lua."
        )

    write_text(changelog_file, prepend_entry(existing, version, changes))

    print(f"changelog.lua mis à jour pour {package} {version} :")
    for change in changes:
        print(f"  {change.rendered}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())

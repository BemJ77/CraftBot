from __future__ import annotations
import argparse
import subprocess
import sys
from pathlib import Path

from git_utils import ensure_git_repository, has_uncommitted_changes
from utils import project_root, read_package_version

def run_python(script: Path, *args: str) -> None:
    p = subprocess.run([sys.executable, str(script), *args], cwd=project_root())
    if p.returncode != 0:
        raise RuntimeError(f"Échec de {script.name}")

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("package")
    parser.add_argument("--since")
    parser.add_argument("--allow-dirty", action="store_true")
    args = parser.parse_args()

    root = project_root()
    ensure_git_repository(root)

    package_dir = root / "packages" / args.package
    package_file = package_dir / "package.lua"
    if not package_file.is_file():
        raise FileNotFoundError(f"Package introuvable : {package_dir}")

    if has_uncommitted_changes(root) and not args.allow_dirty:
        raise RuntimeError(
            "Le dépôt contient des modifications non commitées. "
            "Commite d'abord tes changements, ou utilise --allow-dirty."
        )

    version = read_package_version(package_file)
    tools_dir = Path(__file__).resolve().parent

    changelog_args = [args.package]
    if args.since:
        changelog_args += ["--since", args.since]

    print(f"Préparation de {args.package} {version}\n")
    run_python(tools_dir / "generate_changelog.py", *changelog_args)
    run_python(tools_dir / "generate_catalog.py")

    print("\nRelease préparée.")
    print(f'git add packages/{args.package}/changelog.lua catalog.lua')
    print(f'git commit -m "update({args.package}): release {version}"')
    print("git push")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())

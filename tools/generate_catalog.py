from __future__ import annotations
import argparse
from datetime import datetime, timezone
from pathlib import Path

from utils import lua_quote, project_root, read_package_version, write_text

IGNORED_NAMES = {".git", ".gitignore", "__pycache__", "manager.log"}
IGNORED_SUFFIXES = {".log", ".bak", ".old", ".pyc"}

def should_ignore(path: Path) -> bool:
    return any(part in IGNORED_NAMES for part in path.parts) or path.suffix.lower() in IGNORED_SUFFIXES

def catalog_path_for(package_dir: Path, file_path: Path) -> str:
    relative = file_path.relative_to(package_dir).as_posix()
    if relative.startswith("files/") and relative.endswith(".lua"):
        relative = relative[:-4]
    return relative

def collect_package_files(package_dir: Path) -> list[str]:
    result = []
    for file_path in package_dir.rglob("*"):
        if file_path.is_file():
            rel = file_path.relative_to(package_dir)
            if not should_ignore(rel):
                result.append(catalog_path_for(package_dir, file_path))
    return sorted(result, key=str.lower)

def render_catalog(packages_dir: Path) -> str:
    packages = []
    for package_dir in sorted((p for p in packages_dir.iterdir() if p.is_dir()), key=lambda p: p.name.lower()):
        package_file = package_dir / "package.lua"
        if package_file.is_file():
            packages.append((package_dir.name, read_package_version(package_file), collect_package_files(package_dir)))

    generated = datetime.now(timezone.utc).replace(microsecond=0).isoformat()
    lines = [
        "return {",
        "    schema = 1,",
        f'    generated = "{generated}",',
        "    packages = {",
    ]

    for folder, version, package_files in packages:
        lines += [
            "        {",
            f'            folder = "{lua_quote(folder)}",',
            f'            version = "{lua_quote(version)}",',
            "            files = {",
        ]
        lines += [f'                "{lua_quote(name)}",' for name in package_files]
        lines += ["            },", "        },"]

    lines += ["    },", "}", ""]
    return "\n".join(lines)

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    root = project_root()
    packages_dir = root / "packages"
    output = root / "catalog.lua"

    if not packages_dir.is_dir():
        raise FileNotFoundError(f"Dossier introuvable : {packages_dir}")

    generated = render_catalog(packages_dir)

    if args.check:
        current = output.read_text(encoding="utf-8") if output.exists() else ""
        if current != generated:
            print("catalog.lua n'est pas à jour.")
            return 1
        print("catalog.lua est à jour.")
        return 0

    write_text(output, generated)
    print(f"catalog.lua généré : {output}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())

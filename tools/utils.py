from __future__ import annotations
import re
from pathlib import Path

VERSION_RE = re.compile(r'version\s*=\s*"([^"]+)"')

def project_root() -> Path:
    return Path(__file__).resolve().parents[1]

def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")

def write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8", newline="\n")

def read_package_version(package_file: Path) -> str:
    if not package_file.is_file():
        raise FileNotFoundError(f"Fichier introuvable : {package_file}")
    match = VERSION_RE.search(read_text(package_file))
    if not match:
        raise ValueError(f"Version introuvable dans {package_file}")
    return match.group(1)

def lua_quote(value: str) -> str:
    return value.replace("\\", "\\\\").replace('"', '\\"').replace("\r", "").replace("\n", "\\n")

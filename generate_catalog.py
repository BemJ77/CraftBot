import os
import re
from datetime import date

ROOT = os.path.dirname(os.path.abspath(__file__))
PACKAGES_DIR = os.path.join(ROOT, "packages")
OUTPUT_FILE = os.path.join(ROOT, "catalog.lua")


def read_version(package_file):
    with open(package_file, "r", encoding="utf-8") as f:
        text = f.read()

    m = re.search(r'version\s*=\s*"([^"]+)"', text)
    if not m:
        raise RuntimeError(f"Version introuvable dans {package_file}")

    return m.group(1)


def build_file_list(package_path):
    result = []

    for root, dirs, files in os.walk(package_path):
        dirs.sort()
        files.sort()

        for file in files:

            # Ignore les logs
            if file.endswith(".log"):
                continue

            full = os.path.join(root, file)
            rel = os.path.relpath(full, package_path).replace("\\", "/")

            # package.lua et changelog.lua gardent leur extension
            if rel in ("package.lua", "changelog.lua"):
                result.append(rel)
                continue

            # uniquement les scripts du dossier files perdent le .lua
            if rel.startswith("files/") and rel.endswith(".lua"):
                rel = rel[:-4]

            result.append(rel)

    return sorted(result)


packages = []

for folder in sorted(os.listdir(PACKAGES_DIR)):

    package_dir = os.path.join(PACKAGES_DIR, folder)

    if not os.path.isdir(package_dir):
        continue

    package_file = os.path.join(package_dir, "package.lua")

    if not os.path.exists(package_file):
        continue

    packages.append({
        "name": folder,
        "version": read_version(package_file),
        "files": build_file_list(package_dir)
    })


with open(OUTPUT_FILE, "w", encoding="utf-8", newline="\n") as f:

    f.write("return {\n")
    f.write(f'    generated = "{date.today()}",\n')
    f.write("    packages = {\n\n")

    for package in packages:

        f.write("        {\n")
        f.write(f'            folder = "{package["name"]}",\n')
        f.write(f'            version = "{package["version"]}",\n')
        f.write("            files = {\n")

        for file in package["files"]:
            f.write(f'                "{file}",\n')

        f.write("            }\n")
        f.write("        },\n\n")

    f.write("    }\n")
    f.write("}\n")

print("catalog.lua généré avec succès.")
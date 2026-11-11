#!/usr/bin/env python3
"""A src/ mappa szkriptjeiből Roblox Studióban megnyitható pályafájlt készít.

Használat (a repó gyökeréből):
    python3 tools/build_place.py

Az eredmény: Silvertune.rbxlx és Silvertune.bundle.json. Ugyanazt a felépítést adja, mint a
default.project.json Rojo-val, csak semmit nem kell hozzá telepíteni.
"""

import json
from datetime import datetime, timezone
from pathlib import Path
from xml.sax.saxutils import escape

ROOT = Path(__file__).resolve().parent.parent
OUTPUT = ROOT / "Silvertune.rbxlx"
BUNDLE = ROOT / "Silvertune.bundle.json"

# (szolgáltatások láncolata, mappa neve a játékban, forrásmappa)
MOUNTS = [
    (["ReplicatedStorage"], "Shared", ROOT / "src" / "shared"),
    (["ServerScriptService"], "Server", ROOT / "src" / "server"),
    (["StarterPlayer", "StarterPlayerScripts"], "Client", ROOT / "src" / "client"),
]

_next_id = 0


def referent() -> str:
    global _next_id
    _next_id += 1
    return f"RBX{_next_id}"


def open_item(class_name: str, name: str, depth: int) -> str:
    pad = "  " * depth
    return (
        f'{pad}<Item class="{class_name}" referent="{referent()}">\n'
        f"{pad}  <Properties>\n"
        f'{pad}    <string name="Name">{escape(name)}</string>\n'
    )


def classify(path: Path) -> tuple[str, str]:
    # A fájlnév végződése dönti el a típust, ugyanúgy, mint Rojo-nál.
    stem = path.name[: -len(".luau")]
    if stem.endswith(".server"):
        return "Script", stem[: -len(".server")]
    if stem.endswith(".client"):
        return "LocalScript", stem[: -len(".client")]
    return "ModuleScript", stem


def script_item(path: Path, depth: int) -> str:
    class_name, name = classify(path)

    source = path.read_text(encoding="utf-8").replace("]]>", "]]]]><![CDATA[>")
    pad = "  " * depth
    return (
        open_item(class_name, name, depth)
        + f'{pad}    <ProtectedString name="Source"><![CDATA[{source}]]></ProtectedString>\n'
        + f"{pad}  </Properties>\n"
        + f"{pad}</Item>\n"
    )


def close_properties(depth: int) -> str:
    return "  " * depth + "  </Properties>\n"


def close_item(depth: int) -> str:
    return "  " * depth + "</Item>\n"


def main() -> None:
    parts = ['<roblox version="4">\n']
    count = 0

    for services, folder_name, source_dir in MOUNTS:
        depth = 1
        for service in services:
            parts.append(open_item(service, service, depth) + close_properties(depth))
            depth += 1

        parts.append(open_item("Folder", folder_name, depth) + close_properties(depth))
        for path in sorted(source_dir.glob("*.luau")):
            parts.append(script_item(path, depth + 1))
            count += 1
        parts.append(close_item(depth))

        for _ in services:
            depth -= 1
            parts.append(close_item(depth))

    parts.append("</roblox>\n")
    OUTPUT.write_text("".join(parts), encoding="utf-8")

    # Ugyanez egyetlen JSON-ben: ezt tölti le a Studio-beli frissítő (tools/studio_update.luau).
    bundle = {
        "builtAt": datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC"),
        "mounts": [
            {
                "services": services,
                "folder": folder_name,
                "scripts": [
                    {
                        "class": classify(path)[0],
                        "name": classify(path)[1],
                        "source": path.read_text(encoding="utf-8"),
                    }
                    for path in sorted(source_dir.glob("*.luau"))
                ],
            }
            for services, folder_name, source_dir in MOUNTS
        ],
    }
    BUNDLE.write_text(json.dumps(bundle, ensure_ascii=False), encoding="utf-8")
    print(f"{OUTPUT.name}: {count} szkript becsomagolva")


if __name__ == "__main__":
    main()

import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
index = json.loads((root / "source-index.json").read_text(encoding="utf-8"))
sources = {}
for entry in index:
    if entry["class"] == "LocalScript":
        continue
    sources[entry["id"]] = {
        "path": ".".join(entry["path"]),
        "class": entry["class"],
        "source": (root / entry["file"]).read_text(encoding="utf-8"),
    }
assert len(sources) >= 159, "Missing required server source entries"
(root / "runtime-bundle.json").write_text(
    json.dumps({"schema": 1, "sources": sources}, ensure_ascii=False, separators=(",", ":")) + "\n",
    encoding="utf-8",
)
print(f"Built {len(sources)} server source entries")

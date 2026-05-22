#!/usr/bin/env bash
set -euo pipefail

CFG="$HOME/.config/cmux/cmux.json"
TS="$(date +%Y%m%d-%H%M%S)"

mkdir -p "$(dirname "$CFG")"

if [[ -f "$CFG" ]]; then
  cp "$CFG" "$CFG.bak.$TS"
  echo "backup: $CFG.bak.$TS"
fi

python3 - "$CFG" <<'PY'
import json, sys, pathlib

p = pathlib.Path(sys.argv[1])

def strip_jsonc(src: str) -> str:
    out = []
    i, n = 0, len(src)
    in_str = False
    esc = False
    while i < n:
        c = src[i]
        if in_str:
            out.append(c)
            if esc:
                esc = False
            elif c == "\\":
                esc = True
            elif c == '"':
                in_str = False
            i += 1
            continue
        if c == '"':
            in_str = True
            out.append(c)
            i += 1
            continue
        if c == "/" and i + 1 < n and src[i + 1] == "/":
            while i < n and src[i] != "\n":
                i += 1
            continue
        if c == "/" and i + 1 < n and src[i + 1] == "*":
            i += 2
            while i + 1 < n and not (src[i] == "*" and src[i + 1] == "/"):
                i += 1
            i += 2
            continue
        out.append(c)
        i += 1
    text = "".join(out)
    import re
    text = re.sub(r",(\s*[}\]])", r"\1", text)
    return text

if p.exists():
    raw = p.read_text()
    try:
        data = json.loads(strip_jsonc(raw))
    except Exception as e:
        print(f"parse error: {e} — writing minimal config", file=sys.stderr)
        data = {}
else:
    data = {}

auto = data.setdefault("automation", {})
auto["socketControlMode"] = "allowAll"
import os, tempfile
fd, tmp = tempfile.mkstemp(prefix=p.name + ".", dir=str(p.parent))
try:
    with os.fdopen(fd, "w") as f:
        f.write(json.dumps(data, indent=2) + "\n")
    os.chmod(tmp, 0o600)
    os.replace(tmp, p)
except Exception:
    try: os.unlink(tmp)
    except OSError: pass
    raise
print("automation.socketControlMode = allowAll")
PY

echo
echo "Restart cmux to apply:"
echo "  osascript -e 'tell application \"cmux\" to quit' && sleep 1 && open -a cmux"

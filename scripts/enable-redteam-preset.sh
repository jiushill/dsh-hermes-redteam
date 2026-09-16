#!/usr/bin/env bash
# ============================================================
#  DSH Hermes RedTeam v6 — Global preset override
#  Writes agent-presets.default = redteam into settings.yaml
#  so every NEW session auto-mounts the Hermes preset.
#
#  Reversible: rename "redteam" back to "standard" in ~/.dsh-desktop/settings.yaml
#              (or run recovery.sh, which already restores it).
# ============================================================
set -euo pipefail

REAL_USER="${SUDO_USER:-${USER}}"
REAL_HOME="$(getent passwd "${REAL_USER}" | cut -d: -f6)"
REAL_HOME="${REAL_HOME:-${HOME}}"

SETTINGS="${REAL_HOME}/.dsh-desktop/settings.yaml"
PRESET_DIR="${REAL_HOME}/.dsh-desktop/.agent-presets/redteam"

if [[ ! -d "${PRESET_DIR}" ]]; then
    echo "[ERROR] preset not installed: ${PRESET_DIR}"
    echo "        Run scripts/install.sh first."
    exit 1
fi

if [[ ! -f "${SETTINGS}" ]]; then
    echo "[ERROR] settings.yaml missing: ${SETTINGS}"
    exit 1
fi

if [[ "$(id -u)" -ne 0 ]] && command -v sudo >/dev/null 2>&1 && [[ -f /opt/dsh-desktop/README.md ]]; then
    SUDO="sudo -S"
else
    SUDO=""
fi
run() {
    if [[ -n "${SUDO}" ]]; then
        if [[ -n "${SUDO_PASSWORD:-}" ]]; then
            echo "${SUDO_PASSWORD}" | ${SUDO} "$@" >/dev/null 2>&1 || ${SUDO} "$@"
        else
            ${SUDO} "$@"
        fi
    else
        "$@"
    fi
}

TS="$(date +%Y%m%d-%H%M%S)"
cp "${SETTINGS}" "${SETTINGS}.bak.${TS}"

# Use python so we get id-stable YAML regardless of comments / ordering.
python3 - "${SETTINGS}" <<'PY'
import sys, re

path = sys.argv[1]
with open(path, encoding='utf-8') as f:
    text = f.read()

# Match the entire agent-presets block (yaml key) and the inner default/modeSelectionEnabled.
# We preserve comments and any other keys not in this schema by scanning the matched scope.

block_re = re.compile(r'(^|\n)(agent-presets:\s*\n(?:[ \t]+.*\n)*)', re.MULTILINE)
m = block_re.search(text)
def inner(lines):
    out = {}
    for ln in lines.splitlines():
        if not ln.startswith('  '):
            continue
        stripped = ln.lstrip()
        if stripped.startswith('#') or not stripped:
            continue
        k = stripped.rstrip(':').strip()
        v = stripped[len(k)+1:].strip()
        # naive quote stripper
        v = v.strip('"\'')
        out[k] = v
    return out

if m:
    inner_lines = m.group(2)
    parsed = inner(inner_lines)
else:
    parsed = {}

parsed['default'] = 'redteam'
parsed.setdefault('modeSelectionEnabled', 'true')

# Render a clean block preserving the key placement.
new_block = 'agent-presets:\n'
for k, v in parsed.items():
    new_block += '  ' + k + ': ' + v + '\n'

if m:
    text = text[:m.start(2)] + new_block + text[m.end(2):]
else:
    # append at end
    if not text.endswith('\n'):
        text += '\n'
    text += '\n' + new_block

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
PY

run chown "${REAL_USER}:$(id -gn "${REAL_USER}")" "${SETTINGS}" 2>/dev/null || true

echo
echo "  agent-presets.default: redteam"
echo "  Backup: ${SETTINGS}.bak.${TS}"
echo
echo "  Next session: DSH will auto-mount the redteam preset"
echo "  (persona + tools filter) on top of the SYSTEM OVERRIDE patch."
echo

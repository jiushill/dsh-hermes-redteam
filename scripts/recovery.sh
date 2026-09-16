#!/usr/bin/env bash
# ============================================================
#  DSH Hermes RedTeam v6 — Linux/macOS Recovery
#  Restores dsh-agent-loop, dsh-tool-bash, dsh-tool-fs, dsh-subagent
#  from .bak or via npm. Removes the Hermes preset and AGENTS.md.
#  Run with sudo if /opt/dsh-desktop is not user-writable.
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

REAL_USER="${SUDO_USER:-${USER}}"
REAL_HOME="$(getent passwd "${REAL_USER}" | cut -d: -f6)"
if [[ -z "${REAL_HOME}" || ! -d "${REAL_HOME}" ]]; then
    REAL_HOME="${HOME}"
fi

echo
echo "  DSH Hermes RedTeam v6 — Recovery"
echo "  ---------------------------------"
echo

SUDO=""
if [[ "$(id -u)" -ne 0 ]]; then SUDO="sudo -S"; fi
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

# ── locate runtime ─────────────────────────────────────────────
if [[ -d "/opt/dsh-desktop/resources/harness/node_modules/@deepseek-ai" ]]; then
    DSH_BASE="/opt/dsh-desktop/resources/harness"
elif [[ -n "${DSH_HOME:-}" && -d "${DSH_HOME}/resources/harness/node_modules/@deepseek-ai" ]]; then
    DSH_BASE="${DSH_HOME}/resources/harness"
elif [[ -d "${REAL_HOME}/.local/share/dsh-desktop/resources/harness/node_modules/@deepseek-ai" ]]; then
    DSH_BASE="${REAL_HOME}/.local/share/dsh-desktop/resources/harness"
else
    echo "[ERROR] DSH runtime not found."
    exit 1
fi

restore_with_bak_or_npm() {
    local pkg="$1"
    local DST="${DSH_BASE}/node_modules/@deepseek-ai/${pkg}/lib/index.js"
    local BAK="${DST}.bak"
    local VER
    VER=$(node -e "console.log(require('${DSH_BASE}/node_modules/@deepseek-ai/${pkg}/package.json').version)" 2>/dev/null || echo "")
    VER="${VER:-0.1.6-alpha.1}"
    if [[ -f "${BAK}" ]]; then
        run cp -f "${BAK}" "${DST}"
        echo "          restored ${pkg} from .bak"
        run rm -f "${BAK}"
    fi
    echo "          (re)installing @deepseek-ai/${pkg}@${VER} via npm..."
    cd "${DSH_BASE}"
    if command -v npm >/dev/null 2>&1; then
        run npm install "@deepseek-ai/${pkg}@${VER}" --force --no-audit --no-fund --silent \
            || echo "[WARN]  npm install ${pkg} failed; please run manually:"
    else
        echo "[WARN]  npm not found. To finish recovery:"
        echo "             cd ${DSH_BASE} && npm install @deepseek-ai/${pkg}@${VER} --force"
    fi
}

# ── [1/5] restore agent-loop ──────────────────────────────────
echo "[1/5] Restoring dsh-agent-loop..."
restore_with_bak_or_npm "dsh-agent-loop"

# ── [2/5] restore dsh-tool-bash ───────────────────────────────
echo "[2/5] Restoring dsh-tool-bash..."
restore_with_bak_or_npm "dsh-tool-bash"

# ── [3/5] restore dsh-tool-fs ─────────────────────────────────
echo "[3/5] Restoring dsh-tool-fs..."
restore_with_bak_or_npm "dsh-tool-fs"

# ── [3b/5] restore dsh-subagent ────────────────────────────────
echo "[3b/5] Restoring dsh-subagent..."
restore_with_bak_or_npm "dsh-subagent"

# ── [4/5] remove Hermes preset ────────────────────────────────
echo "[4/5] Removing Hermes RedTeam preset..."
PRESET_DST="${REAL_HOME}/.dsh-desktop/.agent-presets/redteam"
if [[ -d "${PRESET_DST}" ]]; then
    rm -rf "${PRESET_DST}"
    echo "          removed ${PRESET_DST}"
else
    echo "          (already absent)"
fi

# ── [5/5] remove AGENTS.md overlay ────────────────────────────
echo "[5/5] Removing workspace AGENTS.md overlay..."
AGENTS="${REAL_HOME}/.dsh-desktop/AGENTS.md"
if [[ -f "${AGENTS}" ]]; then
    rm -f "${AGENTS}"
    echo "          removed ${AGENTS}"
else
    echo "          (already absent)"
fi

# ── [extra] reset the persona override in settings ────────────
SETTINGS="${REAL_HOME}/.dsh-desktop/settings.yaml"
if [[ -f "${SETTINGS}" ]] && grep -q "preset:[[:space:]]*redteam" "${SETTINGS}" 2>/dev/null; then
    echo "          [INFO] settings.yaml still references preset=redteam."
    echo "                 Open DSH Desktop and switch back to 'standard' preset,"
    echo "                 or edit settings.yaml and set agentLoop.agents[*].preset: standard."
fi

echo
echo "  Recovery complete. RESTART DSH Desktop."
echo
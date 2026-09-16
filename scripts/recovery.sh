#!/usr/bin/env bash
# DSH Hermes RedTeam v5 — Linux/macOS Recovery
# Restores dsh-agent-loop, dsh-tool-bash, dsh-tool-fs from .bak or via npm.
# Removes the Hermes preset and AGENTS.md overlay.
set -euo pipefail

REAL_USER="${SUDO_USER:-${USER}}"
REAL_HOME="$(getent passwd "${REAL_USER}" | cut -d: -f6)"
REAL_HOME="${REAL_HOME:-${HOME}}"

DSH_BASE="/opt/dsh-desktop/resources/harness"

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

restore_with_bak() {
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
    (cd "${DSH_BASE}" && run npm install "@deepseek-ai/${pkg}@${VER}" --force --no-audit --no-fund --silent) \
        || echo "[WARN]  npm install ${pkg} failed; please run manually"
}

echo "[1/3] Restoring dsh-agent-loop..."
restore_with_bak "dsh-agent-loop"

echo "[2/3] Restoring dsh-tool-bash + ds-tool-fs..."
restore_with_bak "dsh-tool-bash"
restore_with_bak "dsh-tool-fs"

echo "[3/3] Removing Hermes preset + AGENTS.md..."
PRESET_DST="${REAL_HOME}/.dsh-desktop/.agent-presets/redteam"
[[ -d "${PRESET_DST}" ]] && rm -rf "${PRESET_DST}"
[[ -f "${REAL_HOME}/.dsh-desktop/AGENTS.md" ]] && rm -f "${REAL_HOME}/.dsh-desktop/AGENTS.md"

echo "v5 recovery complete. RESTART DSH Desktop."

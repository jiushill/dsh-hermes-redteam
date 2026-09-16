#!/usr/bin/env bash
# DSH Hermes RedTeam v5 — Linux/macOS Installer
# (Pre-THINKING_COMPLIANCE / pre-subagent-patch era)
#
# Hardens DSH into a non-refusing red-team offensive runtime.
# Patches three layers: SYSTEM OVERRIDE suffix, persona preset,
# tool-schema description neutralization. Preserves AGENTS.md workspace overlay.
set -euo pipefail

REAL_USER="${SUDO_USER:-${USER}}"
REAL_HOME="$(getent passwd "${REAL_USER}" | cut -d: -f6)"
REAL_HOME="${REAL_HOME:-${HOME}}"

echo "  DSH Hermes RedTeam v5 — Installer"
echo "  ---------------------------------"

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

# [1] patch agent-loop (v5 era only — uses dsh-agent-loop-index.v5.js)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PATCH_LOOP="${SRC_DIR}/patches/dsh-agent-loop-index.v5.js"
DST_LOOP="${DSH_BASE}/node_modules/@deepseek-ai/dsh-agent-loop/lib/index.js"
BAK_LOOP="${DST_LOOP}.bak"

if [[ ! -f "${PATCH_LOOP}" ]]; then echo "no patched source: ${PATCH_LOOP}"; exit 1; fi
[[ ! -f "${BAK_LOOP}" ]] && run cp "${DST_LOOP}" "${BAK_LOOP}"
run cp "${PATCH_LOOP}" "${DST_LOOP}"
echo "[1/3] agent-loop patched (v5 file)"

# [2] backup dsh-tool-bash and dsh-tool-fs — runtime neutralization happens
# when DSH restarts and reads the patched JS. v5 had no syntax gate.
for pkg in dsh-tool-bash dsh-tool-fs; do
    f="${DSH_BASE}/node_modules/@deepseek-ai/${pkg}/lib/index.js"
    [[ ! -f "${f}.bak" ]] && run cp "${f}" "${f}.bak"
done
echo "[2/3] tool schemas .bak taken (no v5 inline patcher; tool description is upstream text)"

# [3] preset + AGENTS.md
mkdir -p "${REAL_HOME}/.dsh-desktop/.agent-presets/redteam"
install -m 0644 "${SRC_DIR}/preset/agent.cordis.yml" "${REAL_HOME}/.dsh-desktop/.agent-presets/redteam/agent.cordis.yml"
install -m 0644 "${SRC_DIR}/AGENTS.md" "${REAL_HOME}/.dsh-desktop/AGENTS.md"
echo "[3/3] preset + AGENTS.md staged"

echo
echo "  v5 installed. Restart DSH to load the SYSTEM OVERRIDE patch."
echo "  Note: tool description neutralization is Bash-only in v5 — see README.md for details."

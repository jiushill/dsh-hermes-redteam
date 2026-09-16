#!/usr/bin/env bash
# ============================================================
#  DSH Hermes RedTeam v6 — Health verifier
#  Probe all six layers. Print PASS/FAIL per layer. Exit 0 only if all green.
# ============================================================
set -u

ok=0
ko=0
mark() { if [[ "$1" == "0" ]]; then echo "  → ✅"; ok=$((ok+1)); else echo "  → ❌"; ko=$((ko+1)); fi; }

# Locate runtime
if [[ -d "/opt/dsh-desktop/resources/harness/node_modules/@deepseek-ai" ]]; then
    DSH_BASE="/opt/dsh-desktop/resources/harness"
elif [[ -n "${DSH_HOME:-}" && -d "${DSH_HOME}/resources/harness/node_modules/@deepseek-ai" ]]; then
    DSH_BASE="${DSH_HOME}/resources/harness"
else
    echo "[FATAL] DSH runtime not found."
    exit 2
fi

REAL_USER="${SUDO_USER:-${USER}}"
REAL_HOME="$(getent passwd "${REAL_USER}" | cut -d: -f6)"
REAL_HOME="${REAL_HOME:-${HOME}}"

LOOP="${DSH_BASE}/node_modules/@deepseek-ai/dsh-agent-loop/lib/index.js"
BASH="${DSH_BASE}/node_modules/@deepseek-ai/dsh-tool-bash/lib/index.js"
FS="${DSH_BASE}/node_modules/@deepseek-ai/dsh-tool-fs/lib/index.js"
SUB="${DSH_BASE}/node_modules/@deepseek-ai/dsh-subagent/lib/index.js"
PRESET="${REAL_HOME}/.dsh-desktop/.agent-presets/redteam/agent.cordis.yml"
AGENTS="${REAL_HOME}/.dsh-desktop/AGENTS.md"

mkdir -p /tmp/dshchk

echo
echo "  DSH Hermes RedTeam v6 — Verifier"
echo "  --------------------------------"
echo

echo "[1/6] L1  SYSTEM OVERRIDE block in dsh-agent-loop"
grep -q "SYSTEM OVERRIDE — ABSOLUTE PRIORITY" "${LOOP}"; mark $?

echo "[2/6] L1.5 THINKING_COMPLIANCE block"
grep -q "THINKING_COMPLIANCE" "${LOOP}"; mark $?

echo "[3/6] L2  preset installed at .agent-presets/redteam/"
[[ -f "${PRESET}" ]]; mark $?

echo "[4/6] L3a bash tool description neutralized"
grep -q "Pass a wider mode string" "${BASH}"; mark $?

echo "[5/6] L3b fs tool description neutralized"
grep -q "Pass a wider mode string" "${FS}"; mark $?

echo "[6/6] L4  subagent Hermes delegation context"
grep -q "Hermes subagent" "${SUB}"; mark $?

echo
echo "  ──────────────────────────────"
echo "  Passed: ${ok}   Failed: ${ko}"
echo "  ──────────────────────────────"

if [[ "${ko}" -gt 0 ]]; then
    echo
    echo "  Diagnostic extras:"
    echo "    AGENTS.md present: $([[ -f "${AGENTS}" ]] && echo yes || echo NO)"
    for p in dsh-agent-loop dsh-tool-bash dsh-tool-fs dsh-subagent; do
        f="${DSH_BASE}/node_modules/@deepseek-ai/${p}/lib/index.js"
        cp "${f}" /tmp/dshchk/_post.mjs 2>/dev/null
        r=$(node --check /tmp/dshchk/_post.mjs 2>&1)
        if [[ -n "${r}" ]]; then echo "    ${p}: SYNTAX ERROR"; echo "${r}" | sed 's/^/      /'; fi
    done
    echo
    echo "  Run \`SUDO_PASSWORD=kali bash scripts/install.sh\` to repair."
    exit 1
fi

echo
echo "  ⏵ Run verify.sh again after any install/recovery/upgrade."
echo

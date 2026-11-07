#!/usr/bin/env bash
# ==============================================================================
# Apple Silicon Unified Memory Ceiling Query & Tuning Helper
# Author: Howard Liao Ph.D.
# ==============================================================================

set -euo pipefail

TOTAL_RAM_GB=$(sysctl -n hw.memsize | awk '{print int($1/1024/1024/1024)}')
CURRENT_LIMIT=$(sysctl -n iogpu.wired_mem_limit 2>/dev/null || echo "0")

echo "=========================================================="
echo "  Apple Silicon GPU Wired Memory Status"
echo "=========================================================="
echo "Total Physical RAM      : ${TOTAL_RAM_GB} GB"
if [ "$CURRENT_LIMIT" -gt 0 ]; then
  CURRENT_LIMIT_GB=$(echo "$CURRENT_LIMIT" | awk '{print $1/1024/1024/1024}')
  echo "Configured Wired Limit  : ${CURRENT_LIMIT} bytes (~${CURRENT_LIMIT_GB} GB)"
else
  DEFAULT_75_GB=$(echo "$TOTAL_RAM_GB" | awk '{print $1 * 0.75}')
  echo "Configured Wired Limit  : System Default (~75% = ~${DEFAULT_75_GB} GB)"
fi

echo ""
echo "Notice: On a 24GB Mac mini:"
echo "  - Running 14B models (Q5/Q8 ~11-16GB): Default limit is optimal."
echo "  - To unlock 22GB for 32B low-quantization models, run:"
echo "      sudo sysctl iogpu.wired_mem_limit=22000"
echo "  - To reset to system default, run:"
echo "      sudo sysctl -w iogpu.wired_mem_limit=0"
echo "=========================================================="

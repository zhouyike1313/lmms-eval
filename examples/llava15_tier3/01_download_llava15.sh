#!/usr/bin/env bash
set -euo pipefail

MODEL_SIZE="${1:-${MODEL_SIZE:-7b}}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=env.sh
source "${SCRIPT_DIR}/env.sh"

MODEL_PATH="${LMMS_EVAL_ROOT}/models/llava-v1.5-${MODEL_SIZE}"
mkdir -p "${MODEL_PATH}"

if command -v hf >/dev/null 2>&1; then
  hf download "liuhaotian/llava-v1.5-${MODEL_SIZE}" --local-dir "${MODEL_PATH}"
elif command -v huggingface-cli >/dev/null 2>&1; then
  huggingface-cli download "liuhaotian/llava-v1.5-${MODEL_SIZE}" --local-dir "${MODEL_PATH}"
else
  echo "Neither 'hf' nor 'huggingface-cli' is available in this environment." >&2
  exit 1
fi

echo "[download] model ready at ${MODEL_PATH}"

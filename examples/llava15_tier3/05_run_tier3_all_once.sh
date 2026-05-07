#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export USE_ACCELERATE="${USE_ACCELERATE:-1}"
export ALL_IN_ONE="${ALL_IN_ONE:-1}"
export NUM_PROCESSES="${NUM_PROCESSES:-4}"
export CUDA_VISIBLE_DEVICES="${CUDA_VISIBLE_DEVICES:-4,5,6,7}"
export DEVICE_MAP="${DEVICE_MAP:-cuda:0}"
export FORCE_SAFE_LLAVA_BATCH_SIZE="${FORCE_SAFE_LLAVA_BATCH_SIZE:-1}"
if [[ "${FORCE_SAFE_LLAVA_BATCH_SIZE}" == "1" ]]; then
  export BATCH_SIZE=1
else
  export BATCH_SIZE="${BATCH_SIZE:-1}"
fi
export DISABLE_CUDNN="${DISABLE_CUDNN:-1}"
export QUIET_LOGS="${QUIET_LOGS:-1}"

exec bash "${SCRIPT_DIR}/03_run_tier3.sh"

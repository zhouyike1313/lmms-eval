#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=env.sh
source "${SCRIPT_DIR}/env.sh"

SMOKE_TASK="${SMOKE_TASK:-ai2d_lite}"
SMOKE_LIMIT="${SMOKE_LIMIT:-5}"
NUM_PROCESSES="${NUM_PROCESSES:-1}"
BATCH_SIZE="${BATCH_SIZE:-1}"
DEVICE_MAP="${DEVICE_MAP:-cuda:0}"
if [[ -n "${GPU_ID:-}" ]]; then
  export CUDA_VISIBLE_DEVICES="${GPU_ID}"
  DEVICE_MAP="cuda:0"
fi

LOG_DIR="${LOG_DIR:-${OUTPUT_ROOT}/run_logs}"
mkdir -p "${LOG_DIR}"
LOG_FILE="${LOG_FILE:-${LOG_DIR}/smoke_${SMOKE_TASK}_$(date +%Y%m%d_%H%M%S).log}"
exec > >(tee -a "${LOG_FILE}") 2>&1

if [[ "${DISABLE_CUDNN:-0}" == "1" ]]; then
  RUNTIME_PATCH_DIR="${RUNTIME_PATCH_DIR:-${LMMS_EVAL_ROOT}/runtime_patches}"
  mkdir -p "${RUNTIME_PATCH_DIR}"
  cat > "${RUNTIME_PATCH_DIR}/sitecustomize.py" <<'PY'
import warnings
import torch
warnings.filterwarnings("ignore", category=FutureWarning, module=r"transformers\..*")
warnings.filterwarnings("ignore", category=FutureWarning, module=r"huggingface_hub\..*")
torch.backends.cudnn.enabled = False
print("[sitecustomize] torch.backends.cudnn.enabled=False")
PY
  export PYTHONPATH="${RUNTIME_PATCH_DIR}:${PYTHONPATH:-}"
fi

if [[ "${QUIET_LOGS:-0}" == "1" ]]; then
  export TOKENIZERS_PARALLELISM="${TOKENIZERS_PARALLELISM:-false}"
  export TRANSFORMERS_VERBOSITY="${TRANSFORMERS_VERBOSITY:-error}"
  export HF_HUB_DISABLE_PROGRESS_BARS="${HF_HUB_DISABLE_PROGRESS_BARS:-1}"
  export PYTHONWARNINGS="${PYTHONWARNINGS:-ignore::FutureWarning}"
fi

echo "[smoke] log=${LOG_FILE}"
echo "[smoke] task=${SMOKE_TASK} limit=${SMOKE_LIMIT} device_map=${DEVICE_MAP}"
echo "[smoke] CUDA_VISIBLE_DEVICES=${CUDA_VISIBLE_DEVICES:-<unset>}"
echo "[smoke] DISABLE_CUDNN=${DISABLE_CUDNN:-0}"

python "${SCRIPT_DIR}/check_llava_load.py" --model-path "${MODEL_PATH}" --device-map "${DEVICE_MAP}"

if [[ "${USE_ACCELERATE:-0}" == "1" ]]; then
  accelerate launch --num_processes "${NUM_PROCESSES}" -m lmms_eval \
    --model llava \
    --model_args "pretrained=${MODEL_PATH},conv_template=vicuna_v1,device_map=${DEVICE_MAP}" \
    --tasks "${SMOKE_TASK}" \
    --batch_size "${BATCH_SIZE}" \
    --limit "${SMOKE_LIMIT}" \
    --log_samples \
    --log_samples_suffix "smoke_llava_v1.5_${MODEL_SIZE}" \
    --output_path "${OUTPUT_ROOT}/smoke_${SMOKE_TASK}" \
    --use_cache "${CACHE_ROOT}/smoke"
else
  python -m lmms_eval \
    --model llava \
    --model_args "pretrained=${MODEL_PATH},conv_template=vicuna_v1,device_map=${DEVICE_MAP}" \
    --tasks "${SMOKE_TASK}" \
    --batch_size "${BATCH_SIZE}" \
    --limit "${SMOKE_LIMIT}" \
    --log_samples \
    --log_samples_suffix "smoke_llava_v1.5_${MODEL_SIZE}" \
    --output_path "${OUTPUT_ROOT}/smoke_${SMOKE_TASK}" \
    --use_cache "${CACHE_ROOT}/smoke"
fi

echo "[smoke] done: ${OUTPUT_ROOT}/smoke_${SMOKE_TASK}"

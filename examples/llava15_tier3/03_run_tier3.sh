#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=env.sh
source "${SCRIPT_DIR}/env.sh"

# Metric-bearing defaults for the ten requested benchmarks.
# The broader groups vqav2/docvqa/coco_cap/nocaps also include test splits that
# generate submission files; use TASKS=... to override when needed.
TASKS="${TASKS:-vqav2_val,gqa,docvqa_val,chartqa,ocrbench,coco2014_cap_val,ai2d,pope,mmstar,nocaps_val}"
NUM_PROCESSES="${NUM_PROCESSES:-1}"
BATCH_SIZE="${BATCH_SIZE:-1}"
DEVICE_MAP="${DEVICE_MAP:-cuda:0}"
if [[ -n "${GPU_ID:-}" ]]; then
  export CUDA_VISIBLE_DEVICES="${GPU_ID}"
  DEVICE_MAP="cuda:0"
fi

LOG_DIR="${LOG_DIR:-${OUTPUT_ROOT}/run_logs}"
mkdir -p "${LOG_DIR}"
LOG_FILE="${LOG_FILE:-${LOG_DIR}/tier3_$(date +%Y%m%d_%H%M%S).log}"
exec > >(tee -a "${LOG_FILE}") 2>&1

on_error() {
  local status=$?
  local line=${1:-unknown}
  local cmd=${2:-unknown}
  echo "[run] ERROR status=${status} line=${line} command=${cmd}" >&2
  echo "[run] full log: ${LOG_FILE}" >&2
  return "${status}"
}

on_exit() {
  local status=$?
  echo "[run] exit_status=${status} log=${LOG_FILE}"
}

trap 'on_error "$LINENO" "$BASH_COMMAND"' ERR
trap on_exit EXIT

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

echo "[run] log=${LOG_FILE}"
echo "[run] tasks=${TASKS}"
echo "[run] device_map=${DEVICE_MAP} num_processes=${NUM_PROCESSES} batch_size=${BATCH_SIZE}"
echo "[run] CUDA_VISIBLE_DEVICES=${CUDA_VISIBLE_DEVICES:-<unset>}"
echo "[run] DISABLE_CUDNN=${DISABLE_CUDNN:-0}"
echo "[run] USE_ACCELERATE=${USE_ACCELERATE:-0} ALL_IN_ONE=${ALL_IN_ONE:-0}"
echo "[run] USE_RESPONSE_CACHE=${USE_RESPONSE_CACHE:-1} LOG_SAMPLES=${LOG_SAMPLES:-1} QUIET_LOGS=${QUIET_LOGS:-0}"
echo "[run] FORCE_SAFE_LLAVA_BATCH_SIZE=${FORCE_SAFE_LLAVA_BATCH_SIZE:-0}"
echo "[run] MODEL_PATH=${MODEL_PATH}"
echo "[run] OUTPUT_ROOT=${OUTPUT_ROOT}"
echo "[run] CACHE_ROOT=${CACHE_ROOT}"
echo "[run] JAVA_HOME=${JAVA_HOME:-<unset>}"
echo "[run] HF_TOKEN_SET=$([[ -n "${HF_TOKEN:-}" ]] && echo 1 || echo 0)"

LIMIT_ARG=()
if [[ -n "${LIMIT:-}" ]]; then
  LIMIT_ARG=(--limit "${LIMIT}")
  echo "[run] limit=${LIMIT}"
fi

if [[ "${USE_ACCELERATE:-0}" == "1" ]]; then
  BASE_CMD=(accelerate launch
    --num_processes "${NUM_PROCESSES}"
    --num_machines "${NUM_MACHINES:-1}"
    --mixed_precision "${MIXED_PRECISION:-no}"
    --dynamo_backend "${DYNAMO_BACKEND:-no}"
    -m lmms_eval)
else
  BASE_CMD=(python -m lmms_eval)
fi

LOG_SAMPLE_ARGS=()
if [[ "${LOG_SAMPLES:-1}" == "1" ]]; then
  LOG_SAMPLE_ARGS=(--log_samples)
fi

CACHE_ARGS=()
if [[ "${USE_RESPONSE_CACHE:-1}" == "1" ]]; then
  CACHE_ARGS=(--use_cache "${CACHE_ROOT}")
fi

if [[ "${ALL_IN_ONE:-0}" == "1" ]]; then
  echo "[run] mode=all_in_one output=${OUTPUT_ROOT}"
  "${BASE_CMD[@]}" \
    --model llava \
    --model_args "pretrained=${MODEL_PATH},conv_template=vicuna_v1,device_map=${DEVICE_MAP}" \
    --tasks "${TASKS}" \
    --batch_size "${BATCH_SIZE}" \
    "${LIMIT_ARG[@]}" \
    "${LOG_SAMPLE_ARGS[@]}" \
    --log_samples_suffix "llava_v1.5_${MODEL_SIZE}_all" \
    --output_path "${OUTPUT_ROOT}" \
    "${CACHE_ARGS[@]}"
  echo "[run] all-in-one finished under ${OUTPUT_ROOT}"
  exit 0
fi

IFS=',' read -ra TASK_ARRAY <<< "${TASKS}"

for TASK in "${TASK_ARRAY[@]}"; do
  TASK="$(echo "${TASK}" | xargs)"
  [[ -z "${TASK}" ]] && continue

  RUN_NAME="llava_v1.5_${MODEL_SIZE}_${TASK}"
  TASK_OUTPUT="${OUTPUT_ROOT}/${TASK}"
  TASK_CACHE="${CACHE_ROOT}/${TASK}"
  mkdir -p "${TASK_OUTPUT}" "${TASK_CACHE}"

  echo "[run] task=${TASK} output=${TASK_OUTPUT}"

  TASK_CACHE_ARGS=()
  if [[ "${USE_RESPONSE_CACHE:-1}" == "1" ]]; then
    TASK_CACHE_ARGS=(--use_cache "${TASK_CACHE}")
  fi

  if ! "${BASE_CMD[@]}" \
      --model llava \
      --model_args "pretrained=${MODEL_PATH},conv_template=vicuna_v1,device_map=${DEVICE_MAP}" \
      --tasks "${TASK}" \
      --batch_size "${BATCH_SIZE}" \
      "${LIMIT_ARG[@]}" \
      "${LOG_SAMPLE_ARGS[@]}" \
      --log_samples_suffix "${RUN_NAME}" \
      --output_path "${TASK_OUTPUT}" \
      "${TASK_CACHE_ARGS[@]}"; then
    if [[ "${CONTINUE_ON_ERROR:-0}" == "1" ]]; then
      echo "[run] task failed, continuing because CONTINUE_ON_ERROR=1: ${TASK}" >&2
      continue
    fi
    exit 1
  fi
done

echo "[run] all requested tasks finished under ${OUTPUT_ROOT}"

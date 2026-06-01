#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Ten requested benchmark names map to nine lmms-eval task names because MME-P
# and MME-C are emitted by the same `mme` task.
NEW10_TASKS="textvqa_val,infovqa_val,seedbench_2,live_bench_2409,scienceqa_img,mme,mmbench_en_dev,realworldqa,textcaps_val"

export TASKS="${TASKS:-${NEW10_TASKS}}"
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
export USE_RESPONSE_CACHE="${USE_RESPONSE_CACHE:-0}"
export LOG_SAMPLES="${LOG_SAMPLES:-0}"
export LOCAL_DATASET_ROOT="${LOCAL_DATASET_ROOT:-/gemini/space/zhouyike/lmms-eval/datasets_hf_new10}"
export LMMS_EVAL_LOCAL_DATASET_ROOT="${LMMS_EVAL_LOCAL_DATASET_ROOT:-${LOCAL_DATASET_ROOT}}"
export HF_HUB_OFFLINE="${HF_HUB_OFFLINE:-1}"
export HF_DATASETS_OFFLINE="${HF_DATASETS_OFFLINE:-1}"
export TRANSFORMERS_OFFLINE="${TRANSFORMERS_OFFLINE:-1}"

# Keep the new benchmark outputs separate from the original 10-benchmark run.
export OUTPUT_ROOT="${OUTPUT_ROOT:-/gemini/space/zhouyike/lmms-eval/results/llava-v1.5-${MODEL_SIZE:-7b}_new10}"
export CACHE_ROOT="${CACHE_ROOT:-/gemini/space/zhouyike/lmms-eval/eval_cache/llava-v1.5-${MODEL_SIZE:-7b}_new10}"

exec bash "${SCRIPT_DIR}/03_run_tier3.sh"

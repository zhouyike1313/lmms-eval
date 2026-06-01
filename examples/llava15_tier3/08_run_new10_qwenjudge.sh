#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=env.sh
source "${SCRIPT_DIR}/env.sh"

MODEL_SIZE="${MODEL_SIZE:-7b}"
MODEL_PATH="${MODEL_PATH:-/gemini/space/zhouyike/lmms-eval/models/llava-v1.5-${MODEL_SIZE}}"
LOCAL_DATASET_ROOT="${LOCAL_DATASET_ROOT:-/gemini/space/zhouyike/lmms-eval/datasets_hf_new10}"

OUTPUT_ROOT_BASE="${OUTPUT_ROOT_BASE:-/gemini/space/zhouyike/lmms-eval/results/llava-v1.5-${MODEL_SIZE}_new10_qwenjudge}"
CACHE_ROOT_BASE="${CACHE_ROOT_BASE:-/gemini/space/zhouyike/lmms-eval/eval_cache/llava-v1.5-${MODEL_SIZE}_new10_qwenjudge}"

OFFLINE_TASKS="${OFFLINE_TASKS:-textvqa_val,infovqa_val,seedbench_2,scienceqa_img,mme,mmbench_en_dev,realworldqa,textcaps_val}"
LIVEBENCH_TASK="${LIVEBENCH_TASK:-live_bench_2409}"

export HF_HUB_OFFLINE="${HF_HUB_OFFLINE:-1}"
export HF_DATASETS_OFFLINE="${HF_DATASETS_OFFLINE:-1}"
export TRANSFORMERS_OFFLINE="${TRANSFORMERS_OFFLINE:-1}"

# The Qwen judge service is inside the 10.x network. Do not let httpx/curl route
# these requests through a stale proxy from env.sh.
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
export no_proxy="${no_proxy:-10.0.0.0/8,localhost,127.0.0.1,10.0.129.136}"
export NO_PROXY="${NO_PROXY:-10.0.0.0/8,localhost,127.0.0.1,10.0.129.136}"

COMMON_ENV=(
  MODEL_SIZE="${MODEL_SIZE}"
  MODEL_PATH="${MODEL_PATH}"
  LOCAL_DATASET_ROOT="${LOCAL_DATASET_ROOT}"
  USE_RESPONSE_CACHE="${USE_RESPONSE_CACHE:-0}"
  LOG_SAMPLES="${LOG_SAMPLES:-0}"
  QUIET_LOGS="${QUIET_LOGS:-1}"
  BATCH_SIZE="${BATCH_SIZE:-1}"
)

LIMIT_ENV=()
if [[ -n "${LIMIT:-}" ]]; then
  LIMIT_ENV=(LIMIT="${LIMIT}")
fi

echo "[new10-qwen] model=${MODEL_PATH}"
echo "[new10-qwen] local datasets=${LOCAL_DATASET_ROOT}"
echo "[new10-qwen] output base=${OUTPUT_ROOT_BASE}"
echo "[new10-qwen] limit=${LIMIT:-<full>}"

echo "[new10-qwen] phase 1/2: local metrics without LiveBench"
env \
  "${COMMON_ENV[@]}" \
  "${LIMIT_ENV[@]}" \
  TASKS="${OFFLINE_TASKS}" \
  OUTPUT_ROOT="${OUTPUT_ROOT_BASE}/offline8" \
  CACHE_ROOT="${CACHE_ROOT_BASE}/offline8" \
  CUDA_VISIBLE_DEVICES="${CUDA_VISIBLE_DEVICES:-4,5,6,7}" \
  MAIN_PROCESS_PORT="${MAIN_PROCESS_PORT:-29617}" \
  NUM_PROCESSES="${NUM_PROCESSES:-4}" \
  USE_ACCELERATE="${USE_ACCELERATE:-1}" \
  bash "${SCRIPT_DIR}/07_run_new10.sh"

echo "[new10-qwen] phase 2/2: LiveBench with Qwen judge"
mkdir -p "${OUTPUT_ROOT_BASE}/livebench"
env \
  "${COMMON_ENV[@]}" \
  "${LIMIT_ENV[@]}" \
  TASKS="${LIVEBENCH_TASK}" \
  OUTPUT_ROOT="${OUTPUT_ROOT_BASE}/livebench" \
  CACHE_ROOT="${CACHE_ROOT_BASE}/livebench" \
  CUDA_VISIBLE_DEVICES="${LIVEBENCH_CUDA_VISIBLE_DEVICES:-4}" \
  NUM_PROCESSES="${LIVEBENCH_NUM_PROCESSES:-1}" \
  USE_ACCELERATE="${LIVEBENCH_USE_ACCELERATE:-0}" \
  OPENAI_API_BASE="${OPENAI_API_BASE:-http://10.127.10.209:9090/v1}" \
  OPENAI_API_KEY="${OPENAI_API_KEY:-EMPTY}" \
  LIVEBENCH_JUDGE_MODEL="${LIVEBENCH_JUDGE_MODEL:-qwen3_5}" \
  LIVEBENCH_JUDGE_TRUST_ENV="${LIVEBENCH_JUDGE_TRUST_ENV:-0}" \
  LIVEBENCH_JUDGE_JSON_MODE="${LIVEBENCH_JUDGE_JSON_MODE:-0}" \
  LIVEBENCH_JUDGE_NO_THINK="${LIVEBENCH_JUDGE_NO_THINK:-1}" \
  LIVEBENCH_JUDGE_TIMEOUT="${LIVEBENCH_JUDGE_TIMEOUT:-180}" \
  LIVEBENCH_JUDGE_MAX_RETRIES="${LIVEBENCH_JUDGE_MAX_RETRIES:-1}" \
  LIVEBENCH_JUDGE_WAIT_TIME="${LIVEBENCH_JUDGE_WAIT_TIME:-20}" \
  LIVEBENCH_JUDGE_MAX_IMAGE_SIDE="${LIVEBENCH_JUDGE_MAX_IMAGE_SIDE:-768}" \
  LIVEBENCH_JUDGE_IMAGE_QUALITY="${LIVEBENCH_JUDGE_IMAGE_QUALITY:-80}" \
  LIVEBENCH_JUDGE_AUDIT_PATH="${LIVEBENCH_JUDGE_AUDIT_PATH:-${OUTPUT_ROOT_BASE}/livebench/livebench_qwenjudge_audit.jsonl}" \
  bash "${SCRIPT_DIR}/07_run_new10.sh"

echo "[new10-qwen] done"
echo "[new10-qwen] offline results: ${OUTPUT_ROOT_BASE}/offline8"
echo "[new10-qwen] livebench results: ${OUTPUT_ROOT_BASE}/livebench"
echo "[new10-qwen] livebench audit: ${LIVEBENCH_JUDGE_AUDIT_PATH:-${OUTPUT_ROOT_BASE}/livebench/livebench_qwenjudge_audit.jsonl}"

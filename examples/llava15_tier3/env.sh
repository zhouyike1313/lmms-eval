#!/usr/bin/env bash
set -euo pipefail

# Shared environment for the LLaVA-1.5 Tier-3 benchmark pipeline.
# Source this file from the other scripts, or source it manually before running
# ad-hoc lmms-eval commands on the server.

export LMMS_EVAL_ROOT="${LMMS_EVAL_ROOT:-/gemini/space/zhouyike/lmms-eval}"
export CONDA_SH="${CONDA_SH:-/gemini/space/zhouyike/miniconda3/etc/profile.d/conda.sh}"
export CONDA_ENV="${CONDA_ENV:-/gemini/space/zhouyike/env/lmms_eval}"

export http_proxy="${http_proxy:-http://10.20.2.209:18118}"
export https_proxy="${https_proxy:-http://10.20.2.209:18118}"
export no_proxy="${no_proxy:-10.20.6.3,localhost,127.0.0.1,::1,10.0.0.0/8,192.168.0.0/16,*.local,172.16.0.0/12,169.254.0.0/16}"
export GIT_SSL_NO_VERIFY="${GIT_SSL_NO_VERIFY:-1}"
export PIP_INDEX_URL="${PIP_INDEX_URL:-http://10.20.6.3:8081/repository/pypi/simple}"
export PIP_TRUSTED_HOST="${PIP_TRUSTED_HOST:-10.20.6.3}"

export HF_HOME="${HF_HOME:-${LMMS_EVAL_ROOT}/.cache/huggingface}"
export HF_DATASETS_CACHE="${HF_DATASETS_CACHE:-${HF_HOME}/datasets}"
export TRANSFORMERS_CACHE="${TRANSFORMERS_CACHE:-${HF_HOME}/hub}"
export LMMS_EVAL_HOME="${LMMS_EVAL_HOME:-${LMMS_EVAL_ROOT}/.cache/lmms-eval}"
export HF_HUB_ENABLE_HF_TRANSFER="${HF_HUB_ENABLE_HF_TRANSFER:-1}"

export HF_TOKEN_FILE="${HF_TOKEN_FILE:-/gemini/space/zhouyike/.hf_token}"
if [[ -z "${HF_TOKEN:-}" && -f "${HF_TOKEN_FILE}" ]]; then
  export HF_TOKEN="$(tr -d '[:space:]' < "${HF_TOKEN_FILE}")"
fi

export MODEL_SIZE="${MODEL_SIZE:-7b}"
export MODEL_PATH="${MODEL_PATH:-${LMMS_EVAL_ROOT}/models/llava-v1.5-${MODEL_SIZE}}"
export OUTPUT_ROOT="${OUTPUT_ROOT:-${LMMS_EVAL_ROOT}/results/llava-v1.5-${MODEL_SIZE}}"
export CACHE_ROOT="${CACHE_ROOT:-${LMMS_EVAL_ROOT}/eval_cache/llava-v1.5-${MODEL_SIZE}}"

if [[ -z "${JAVA_HOME:-}" && -d "/gemini/space/zhouyike/jdk8u402-b06" ]]; then
  export JAVA_HOME="/gemini/space/zhouyike/jdk8u402-b06"
fi
if [[ -n "${JAVA_HOME:-}" ]]; then
  export PATH="${JAVA_HOME}/bin:${PATH}"
fi

mkdir -p "${HF_HOME}" "${HF_DATASETS_CACHE}" "${TRANSFORMERS_CACHE}" "${LMMS_EVAL_HOME}" "${OUTPUT_ROOT}" "${CACHE_ROOT}" "${LMMS_EVAL_ROOT}/models"

if [[ -f "${CONDA_SH}" ]]; then
  # shellcheck disable=SC1090
  source "${CONDA_SH}"
  conda activate "${CONDA_ENV}"
fi

cd "${LMMS_EVAL_ROOT}"

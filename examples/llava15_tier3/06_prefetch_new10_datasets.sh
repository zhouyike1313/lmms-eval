#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=env.sh
source "${SCRIPT_DIR}/env.sh"

export LOCAL_DATASET_ROOT="${LOCAL_DATASET_ROOT:-${LMMS_EVAL_ROOT}/datasets_hf_new10}"
LOG_DIR="${LOG_DIR:-${OUTPUT_ROOT}/dataset_prefetch_new10_logs}"
mkdir -p "${LOG_DIR}" "${LOCAL_DATASET_ROOT}"

export HF_HUB_ETAG_TIMEOUT="${HF_HUB_ETAG_TIMEOUT:-60}"
export HF_HUB_DOWNLOAD_TIMEOUT="${HF_HUB_DOWNLOAD_TIMEOUT:-60}"
DOWNLOAD_RETRIES="${DOWNLOAD_RETRIES:-5}"

if ! python - <<'PY' >/dev/null 2>&1
import six
assert hasattr(six, "string_types")
assert hasattr(six, "integer_types")
PY
then
  echo "[prefetch-new10] repairing six; datasets imports pandas/dateutil which need six.string_types"
  python -m pip install --force-reinstall "six==1.17.0"
fi

if ! python - <<'PY' >/dev/null 2>&1
from dateutil.parser._parser import DEFAULTPARSER
PY
then
  echo "[prefetch-new10] repairing python-dateutil; pandas needs dateutil.parser._parser.DEFAULTPARSER"
  python -m pip install --no-deps --force-reinstall "python-dateutil==2.9.0.post0"
fi

if ! python - <<'PY' >/dev/null 2>&1
import xxhash
assert hasattr(xxhash, "xxh64")
PY
then
  echo "[prefetch-new10] repairing xxhash; datasets needs xxhash.xxh64()"
  python -m pip install --no-deps --force-reinstall "xxhash==3.5.0"
fi

DATASETS=(
  textvqa_val
  infovqa_val
  seedbench_2
  live_bench_2409
  scienceqa_img
  mme
  mmbench_en_dev
  realworldqa
  textcaps_val
)

if [[ -n "${TASKS:-}" ]]; then
  IFS=',' read -r -a DATASETS <<< "${TASKS}"
fi

DOWNLOAD_LOCAL="${DOWNLOAD_LOCAL:-1}"
SKIP_LOAD="${SKIP_LOAD:-0}"

echo "[prefetch-new10] LOCAL_DATASET_ROOT=${LOCAL_DATASET_ROOT}"
echo "[prefetch-new10] DOWNLOAD_LOCAL=${DOWNLOAD_LOCAL} SKIP_LOAD=${SKIP_LOAD}"
echo "[prefetch-new10] HF_HUB_ETAG_TIMEOUT=${HF_HUB_ETAG_TIMEOUT} HF_HUB_DOWNLOAD_TIMEOUT=${HF_HUB_DOWNLOAD_TIMEOUT} DOWNLOAD_RETRIES=${DOWNLOAD_RETRIES}"
echo "[prefetch-new10] datasets=${DATASETS[*]}"

download_dataset() {
  local label="$1"
  local repo="$2"
  local local_dir="$3"
  local token_args=()

  echo "[download-new10] ${label}: ${repo} -> ${local_dir}"
  mkdir -p "${local_dir}"
  if [[ -n "${HF_TOKEN:-}" ]]; then
    token_args=(--token "${HF_TOKEN}")
  fi
  for ((attempt = 1; attempt <= DOWNLOAD_RETRIES; attempt++)); do
    echo "[download-new10] ${label}: attempt ${attempt}/${DOWNLOAD_RETRIES}"
    if hf download "${repo}" \
      --repo-type dataset \
      "${token_args[@]}" \
      --local-dir "${local_dir}"; then
      return 0
    fi
    if [[ "${attempt}" -lt "${DOWNLOAD_RETRIES}" ]]; then
      sleep $((attempt * 10))
    fi
  done
  return 1
}

download_one() {
  local dataset="$1"
  case "${dataset}" in
    textvqa_val)
      download_dataset "${dataset}" "lmms-lab/textvqa" "${LOCAL_DATASET_ROOT}/textvqa"
      ;;
    infovqa_val)
      download_dataset "${dataset}" "lmms-lab/DocVQA" "${LOCAL_DATASET_ROOT}/InfographicVQA"
      ;;
    seedbench_2)
      download_dataset "${dataset}" "lmms-lab/SEED-Bench-2" "${LOCAL_DATASET_ROOT}/SEED-Bench-2"
      ;;
    live_bench_2409)
      download_dataset "${dataset}" "lmms-lab/LiveBench" "${LOCAL_DATASET_ROOT}/LiveBench"
      ;;
    scienceqa_img)
      download_dataset "${dataset}" "lmms-lab/ScienceQA" "${LOCAL_DATASET_ROOT}/ScienceQA"
      ;;
    mme)
      download_dataset "${dataset}" "lmms-lab/MME" "${LOCAL_DATASET_ROOT}/MME"
      ;;
    mmbench_en_dev)
      download_dataset "${dataset}" "lmms-lab/MMBench" "${LOCAL_DATASET_ROOT}/MMBench"
      ;;
    realworldqa)
      download_dataset "${dataset}" "lmms-lab/RealWorldQA" "${LOCAL_DATASET_ROOT}/RealWorldQA"
      ;;
    textcaps_val)
      download_dataset "${dataset}" "lmms-lab/TextCaps" "${LOCAL_DATASET_ROOT}/TextCaps"
      ;;
    *)
      echo "[download-new10] unknown dataset label: ${dataset}" >&2
      return 2
      ;;
  esac
}

FAILED=()
for DATASET in "${DATASETS[@]}"; do
  LOG_FILE="${LOG_DIR}/${DATASET}.log"
  echo "[prefetch-new10] start ${DATASET}; log=${LOG_FILE}"
  if {
      if [[ "${DOWNLOAD_LOCAL}" == "1" ]]; then
        download_one "${DATASET}" || exit $?
      fi
      if [[ "${SKIP_LOAD}" != "1" ]]; then
        python -u "${SCRIPT_DIR}/prefetch_new10_datasets.py" --only "${DATASET}" || exit $?
      fi
    } 2>&1 | tee "${LOG_FILE}"; then
    echo "[prefetch-new10] ok ${DATASET}"
  else
    echo "[prefetch-new10] failed ${DATASET}; see ${LOG_FILE}" >&2
    FAILED+=("${DATASET}")
  fi
done

if [[ ${#FAILED[@]} -gt 0 ]]; then
  echo "[prefetch-new10] failed dataset(s): ${FAILED[*]}" >&2
  echo "[prefetch-new10] logs are under ${LOG_DIR}" >&2
  exit 1
fi

echo "[prefetch-new10] all new datasets are ready"

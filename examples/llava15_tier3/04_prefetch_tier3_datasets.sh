#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=env.sh
source "${SCRIPT_DIR}/env.sh"

LOG_DIR="${LOG_DIR:-${OUTPUT_ROOT}/dataset_prefetch_logs}"
mkdir -p "${LOG_DIR}"

if ! python - <<'PY' >/dev/null 2>&1
import six
assert hasattr(six, "string_types")
assert hasattr(six, "integer_types")
PY
then
  echo "[prefetch] repairing six; datasets imports pandas/dateutil which need six.string_types"
  python -m pip install --force-reinstall "six==1.17.0"
fi

if ! python - <<'PY' >/dev/null 2>&1
from dateutil.parser._parser import DEFAULTPARSER
PY
then
  echo "[prefetch] repairing python-dateutil; pandas needs dateutil.parser._parser.DEFAULTPARSER"
  python -m pip install --no-deps --force-reinstall "python-dateutil==2.9.0.post0"
fi

if ! python - <<'PY' >/dev/null 2>&1
import xxhash
assert hasattr(xxhash, "xxh64")
PY
then
  echo "[prefetch] repairing xxhash; datasets needs xxhash.xxh64()"
  python -m pip install --no-deps --force-reinstall "xxhash==3.5.0"
fi

DATASETS=(
  vqav2_val
  gqa
  docvqa_val
  chartqa
  ocrbench
  coco2014_cap_val
  ai2d
  pope
  mmstar
  nocaps_val
)

FAILED=()

for DATASET in "${DATASETS[@]}"; do
  LOG_FILE="${LOG_DIR}/${DATASET}.log"
  echo "[prefetch] start ${DATASET}; log=${LOG_FILE}"
  if python -u "${SCRIPT_DIR}/prefetch_tier3_datasets.py" --only "${DATASET}" 2>&1 | tee "${LOG_FILE}"; then
    echo "[prefetch] ok ${DATASET}"
  else
    echo "[prefetch] failed ${DATASET}; see ${LOG_FILE}" >&2
    FAILED+=("${DATASET}")
  fi
done

if [[ ${#FAILED[@]} -gt 0 ]]; then
  echo "[prefetch] failed dataset(s): ${FAILED[*]}" >&2
  echo "[prefetch] logs are under ${LOG_DIR}" >&2
  exit 1
fi

echo "[prefetch] all datasets are ready"

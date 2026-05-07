#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=env.sh
source "${SCRIPT_DIR}/env.sh"

echo "[prepare] repo: ${LMMS_EVAL_ROOT}"
echo "[prepare] python: $(command -v python)"
python -V

if ! python - <<'PY' >/dev/null 2>&1
try:
    import tomli
except ImportError:
    raise SystemExit(1)
assert hasattr(tomli, "load")
PY
then
  echo "[prepare] repairing tomli; setuptools needs tomli.load() on Python 3.10"
  python -m pip install --force-reinstall "tomli==2.0.1"
fi

if [[ "${INSTALL_TORCH:-1}" == "1" ]]; then
  if ! python -c "import torch, torchvision" >/dev/null 2>&1; then
    TORCH_WHEEL="${TORCH_WHEEL:-/gemini/space/zhouyike/torch-2.5.1+cu124-cp310-cp310-linux_x86_64.whl}"
    TORCHVISION_WHEEL="${TORCHVISION_WHEEL:-/gemini/space/zhouyike/torchvision-0.20.1+cu124-cp310-cp310-linux_x86_64.whl}"
    TORCHAUDIO_WHEEL="${TORCHAUDIO_WHEEL:-/gemini/space/zhouyike/torchaudio-2.5.1+cu124-cp310-cp310-linux_x86_64.whl}"

    if [[ -f "${TORCH_WHEEL}" && -f "${TORCHVISION_WHEEL}" ]]; then
      echo "[prepare] installing torch wheels from local files"
      TORCH_WHEELS=("${TORCH_WHEEL}" "${TORCHVISION_WHEEL}")
      if [[ -f "${TORCHAUDIO_WHEEL}" ]]; then
        TORCH_WHEELS+=("${TORCHAUDIO_WHEEL}")
      fi
      python -m pip install "${TORCH_WHEELS[@]}"
    else
      PYTORCH_INDEX_URL="${PYTORCH_INDEX_URL:-https://download.pytorch.org/whl/cu118}"
      echo "[prepare] installing torch/torchvision from ${PYTORCH_INDEX_URL}"
      python -m pip install --trusted-host download.pytorch.org --index-url "${PYTORCH_INDEX_URL}" torch torchvision
    fi
  fi
fi

if [[ "${INSTALL_LMMS_DEPS:-1}" == "1" ]]; then
  python -m pip install --no-build-isolation -e .
else
  python -m pip install --no-build-isolation --no-deps -e .
fi

if [[ "${INSTALL_JSON_REPAIR:-1}" == "1" ]]; then
  python -m pip install \
    json-repair
fi

if ! python - <<'PY' >/dev/null 2>&1
import six
assert hasattr(six, "string_types")
assert hasattr(six, "integer_types")
PY
then
  echo "[prepare] repairing six; python-dateutil/pandas need six.string_types"
  python -m pip install --force-reinstall "six==1.17.0"
fi

if ! python - <<'PY' >/dev/null 2>&1
from dateutil.parser._parser import DEFAULTPARSER
PY
then
  echo "[prepare] repairing python-dateutil; pandas needs dateutil.parser._parser.DEFAULTPARSER"
  python -m pip install --no-deps --force-reinstall "python-dateutil==2.9.0.post0"
fi

if ! python - <<'PY' >/dev/null 2>&1
import xxhash
assert hasattr(xxhash, "xxh64")
PY
then
  echo "[prepare] repairing xxhash; datasets needs xxhash.xxh64()"
  python -m pip install --no-deps --force-reinstall "xxhash==3.5.0"
fi

if ! python - <<'PY' >/dev/null 2>&1
import filelock
import filelock._api as filelock_api
assert hasattr(filelock, "BaseFileLock")
assert hasattr(filelock_api, "FileLockMeta")
PY
then
  echo "[prepare] repairing filelock; lmms-eval needs BaseFileLock and filelock._api.FileLockMeta"
  python -m pip install --no-deps --force-reinstall "filelock==3.16.1"
fi

if ! python - <<'PY' >/dev/null 2>&1
from threadpoolctl import ThreadpoolController
PY
then
  echo "[prepare] repairing threadpoolctl; scikit-learn needs ThreadpoolController"
  python -m pip install --no-deps --force-reinstall "threadpoolctl==3.6.0"
fi

if ! python - <<'PY' >/dev/null 2>&1
from multidict import istr
PY
then
  echo "[prepare] repairing multidict; aiohttp needs multidict.istr"
  python -m pip install --no-deps --force-reinstall "multidict==6.0.5"
fi

if ! python - <<'PY' >/dev/null 2>&1
import aiohttp
from yarl import URL
from multidict import istr
import async_timeout
assert hasattr(async_timeout, "Timeout")
PY
then
  echo "[prepare] repairing aiohttp runtime package set"
  python -m pip install --no-deps --force-reinstall \
    "aiohttp==3.9.5" \
    "yarl==1.9.4" \
    "multidict==6.0.5" \
    "propcache==0.2.1" \
    "aiosignal==1.3.1" \
    "frozenlist==1.4.1" \
    "attrs==23.2.0" \
    "async-timeout==4.0.3"
fi

if [[ "${PIN_LLAVA_RUNTIME:-1}" == "1" ]]; then
  echo "[prepare] pinning LLaVA/lmms runtime packages without touching torch"
  python -m pip install --no-deps --force-reinstall \
    "filelock==3.16.1" \
    "huggingface_hub==0.34.4" \
    "transformers==4.37.2" \
    "tokenizers==0.15.2" \
    "accelerate==0.29.3" \
    "fsspec==2026.2.0"
fi

if ! python - <<'PY' >/dev/null 2>&1
import typing_extensions
assert hasattr(typing_extensions, "ParamSpec")
assert hasattr(typing_extensions, "TypeGuard")
PY
then
  echo "[prepare] repairing typing_extensions; torch needs ParamSpec/TypeGuard"
  python -m pip install --force-reinstall "typing-extensions>=4.8.0"
fi

if [[ "${INSTALL_LLAVA_PACKAGE:-1}" == "1" ]]; then
  mkdir -p "${LMMS_EVAL_ROOT}/third_party"
  if [[ ! -d "${LMMS_EVAL_ROOT}/third_party/LLaVA/.git" ]]; then
    if [[ -e "${LMMS_EVAL_ROOT}/third_party/LLaVA" ]]; then
      mv "${LMMS_EVAL_ROOT}/third_party/LLaVA" "${LMMS_EVAL_ROOT}/third_party/LLaVA.broken.$(date +%Y%m%d_%H%M%S)"
    fi

    for attempt in 1 2 3; do
      echo "[prepare] cloning LLaVA, attempt ${attempt}/3"
      if git -c http.version=HTTP/1.1 clone \
        --depth 1 \
        --single-branch \
        https://github.com/haotian-liu/LLaVA.git \
        "${LMMS_EVAL_ROOT}/third_party/LLaVA"; then
        break
      fi
      if [[ -e "${LMMS_EVAL_ROOT}/third_party/LLaVA" ]]; then
        mv "${LMMS_EVAL_ROOT}/third_party/LLaVA" "${LMMS_EVAL_ROOT}/third_party/LLaVA.failed.${attempt}.$(date +%Y%m%d_%H%M%S)"
      fi
      sleep $((attempt * 5))
    done

    if [[ ! -d "${LMMS_EVAL_ROOT}/third_party/LLaVA/.git" ]]; then
      echo "Failed to clone LLaVA after 3 attempts. Check proxy/GitHub access, or set INSTALL_LLAVA_PACKAGE=0 if LLaVA is already installed." >&2
      exit 1
    fi
  fi
  if [[ "${REINSTALL_LLAVA_PACKAGE:-0}" == "1" ]] || ! python -c "import llava" >/dev/null 2>&1; then
    python -m pip install --no-build-isolation --no-deps -e "${LMMS_EVAL_ROOT}/third_party/LLaVA"
  else
    echo "[prepare] LLaVA is already importable; skip editable reinstall"
  fi
fi

if [[ "${INSTALL_REPR_REQUIREMENTS:-0}" == "1" ]]; then
  python -m pip install \
    -r "${LMMS_EVAL_ROOT}/miscs/llava_repr_requirements.txt"
fi

echo "[prepare] checking key imports"
python - <<'PY'
import importlib

mods = ["torch", "transformers", "datasets", "accelerate", "llava", "lmms_eval"]
for name in mods:
    mod = importlib.import_module(name)
    print(f"{name}: {getattr(mod, '__version__', 'ok')}")
PY

echo "[prepare] done"

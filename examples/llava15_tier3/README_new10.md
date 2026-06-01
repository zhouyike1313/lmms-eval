# LLaVA-1.5 New-10 Benchmark Pipeline

This is independent from the original 10-benchmark Tier-3 scripts. The original
default run remains:

```text
vqav2_val,gqa,docvqa_val,chartqa,ocrbench,coco2014_cap_val,ai2d,pope,mmstar,nocaps_val
```

The new scripts only target the extra benchmark set requested later.

## Benchmark Mapping

| Requested benchmark | lmms-eval task |
| --- | --- |
| TextVQA | `textvqa_val` |
| InfoVQA | `infovqa_val` |
| SEED-2 | `seedbench_2` |
| LiveVQA | `live_bench_2409` |
| SQA / ScienceQA | `scienceqa_img` |
| MME-P | `mme` |
| MMBench | `mmbench_en_dev` |
| MME-C | `mme` |
| RWQA / RealWorldQA | `realworldqa` |
| TextCaps | `textcaps_val` |

Notes:

- `MME-P` and `MME-C` are both emitted by the single lmms-eval task `mme` as
  separate perception/cognition metrics.
- This checkout does not contain a task literally named `livevqa`; the default
  uses `live_bench_2409`. Override `TASKS` if another LiveBench/LiveXiv variant
  is needed.
- `scienceqa_img` is the visual ScienceQA/SQA task.
- `mmbench_en_dev` is used because it has local dev labels and metrics.

## Download New Datasets

Download raw Hugging Face repositories into a separate local directory and build
the Arrow cache:

```bash
cd /gemini/space/zhouyike/lmms-eval
source examples/llava15_tier3/env.sh

LOCAL_DATASET_ROOT=/gemini/space/zhouyike/lmms-eval/datasets_hf_new10 \
bash examples/llava15_tier3/06_prefetch_new10_datasets.sh
```

The script downloads the raw repositories with `hf download --local-dir`, using
the same proxy/HF token environment as the original 10-benchmark pipeline.
It sets `HF_HUB_ETAG_TIMEOUT=60`, `HF_HUB_DOWNLOAD_TIMEOUT=60`, and retries each
repository download up to `DOWNLOAD_RETRIES=5` times by default.

Equivalent direct downloads are:

```bash
export http_proxy="http://10.20.2.209:18118"
export https_proxy="http://10.20.2.209:18118"
export no_proxy="10.20.6.3,localhost,127.0.0.1,::1,10.0.0.0/8,192.168.0.0/16,*.local,172.16.0.0/12,169.254.0.0/16"
export GIT_SSL_NO_VERIFY=1

hf download lmms-lab/textvqa --repo-type dataset --token "$HF_TOKEN" --local-dir ./datasets_hf_new10/textvqa
hf download lmms-lab/DocVQA --repo-type dataset --token "$HF_TOKEN" --local-dir ./datasets_hf_new10/InfographicVQA
hf download lmms-lab/SEED-Bench-2 --repo-type dataset --token "$HF_TOKEN" --local-dir ./datasets_hf_new10/SEED-Bench-2
hf download lmms-lab/LiveBench --repo-type dataset --token "$HF_TOKEN" --local-dir ./datasets_hf_new10/LiveBench
hf download lmms-lab/ScienceQA --repo-type dataset --token "$HF_TOKEN" --local-dir ./datasets_hf_new10/ScienceQA
hf download lmms-lab/MME --repo-type dataset --token "$HF_TOKEN" --local-dir ./datasets_hf_new10/MME
hf download lmms-lab/MMBench --repo-type dataset --token "$HF_TOKEN" --local-dir ./datasets_hf_new10/MMBench
hf download lmms-lab/RealWorldQA --repo-type dataset --token "$HF_TOKEN" --local-dir ./datasets_hf_new10/RealWorldQA
hf download lmms-lab/TextCaps --repo-type dataset --token "$HF_TOKEN" --local-dir ./datasets_hf_new10/TextCaps
```

There are nine raw repository downloads because `MME-P` and `MME-C` share the
same `lmms-lab/MME` dataset and are separated by metrics during evaluation.

Only download the raw Hugging Face repositories, without building Arrow cache:

```bash
LOCAL_DATASET_ROOT=/gemini/space/zhouyike/lmms-eval/datasets_hf_new10 \
DOWNLOAD_LOCAL=1 \
SKIP_LOAD=1 \
bash examples/llava15_tier3/06_prefetch_new10_datasets.sh
```

Only build Arrow cache from already downloaded local repositories:

```bash
LOCAL_DATASET_ROOT=/gemini/space/zhouyike/lmms-eval/datasets_hf_new10 \
DOWNLOAD_LOCAL=0 \
SKIP_LOAD=0 \
bash examples/llava15_tier3/06_prefetch_new10_datasets.sh
```

Download selected datasets only:

```bash
TASKS=textvqa_val,infovqa_val,mme \
DOWNLOAD_LOCAL=1 \
SKIP_LOAD=1 \
bash examples/llava15_tier3/06_prefetch_new10_datasets.sh
```

Only build Arrow cache for selected already-downloaded datasets:

```bash
TASKS=textvqa_val,infovqa_val,mme \
DOWNLOAD_LOCAL=0 \
SKIP_LOAD=0 \
bash examples/llava15_tier3/06_prefetch_new10_datasets.sh
```

The default raw dataset directory is:

```text
/gemini/space/zhouyike/lmms-eval/datasets_hf_new10
```

## Run New Benchmarks

Run the new benchmark set on 4 GPUs:

```bash
cd /gemini/space/zhouyike/lmms-eval
source examples/llava15_tier3/env.sh
source /gemini/space/zhouyike/miniconda3/etc/profile.d/conda.sh
conda activate /gemini/space/zhouyike/env/lmms_eval

CUDA_VISIBLE_DEVICES=4,5,6,7 \
MAIN_PROCESS_PORT=0 \
NUM_PROCESSES=4 \
BATCH_SIZE=1 \
USE_RESPONSE_CACHE=0 \
LOG_SAMPLES=0 \
QUIET_LOGS=1 \
bash examples/llava15_tier3/07_run_new10.sh
```

For a smoke test:

```bash
LIMIT=20 \
CUDA_VISIBLE_DEVICES=4,5,6,7 \
MAIN_PROCESS_PORT=0 \
bash examples/llava15_tier3/07_run_new10.sh
```

Default outputs are separate from the original 10-benchmark run:

```text
/gemini/space/zhouyike/lmms-eval/results/llava-v1.5-7b_new10
/gemini/space/zhouyike/lmms-eval/eval_cache/llava-v1.5-7b_new10
```

`07_run_new10.sh` defaults to offline evaluation:

```bash
LOCAL_DATASET_ROOT=/gemini/space/zhouyike/lmms-eval/datasets_hf_new10
HF_HUB_OFFLINE=1
HF_DATASETS_OFFLINE=1
TRANSFORMERS_OFFLINE=1
```

When `LOCAL_DATASET_ROOT` is set, the task loader redirects the new-10
Hugging Face dataset ids to the matching local directories under
`datasets_hf_new10`, so task initialization does not contact Hugging Face.

LiveBench uses an OpenAI-compatible judge. To use the local Qwen judge service
instead of GPT-4o, set:

```bash
OPENAI_API_BASE=http://10.127.10.209:9090/v1
OPENAI_API_KEY=EMPTY
LIVEBENCH_JUDGE_MODEL=qwen3_5
LIVEBENCH_JUDGE_TIMEOUT=180
LIVEBENCH_JUDGE_MAX_RETRIES=5
LIVEBENCH_JUDGE_JSON_MODE=0
LIVEBENCH_JUDGE_NO_THINK=1
LIVEBENCH_JUDGE_MAX_IMAGE_SIDE=1024
LIVEBENCH_JUDGE_IMAGE_QUALITY=85
```

For 13B:

```bash
MODEL_SIZE=13b \
MODEL_PATH=/gemini/space/zhouyike/lmms-eval/models/llava-v1.5-13b \
OUTPUT_ROOT=/gemini/space/zhouyike/lmms-eval/results/llava-v1.5-13b_new10 \
CACHE_ROOT=/gemini/space/zhouyike/lmms-eval/eval_cache/llava-v1.5-13b_new10 \
CUDA_VISIBLE_DEVICES=4,5,6,7 \
MAIN_PROCESS_PORT=0 \
NUM_PROCESSES=4 \
BATCH_SIZE=1 \
USE_RESPONSE_CACHE=0 \
LOG_SAMPLES=0 \
QUIET_LOGS=1 \
bash examples/llava15_tier3/07_run_new10.sh
```

Keep `BATCH_SIZE=1` for this LLaVA simple backend unless a future validation
proves larger batches are metric-equivalent.

## Run All New Benchmarks With Qwen Judge

`08_run_new10_qwenjudge.sh` runs the local-score tasks first, then runs
LiveBench separately with the Qwen judge. This avoids mixing fast local metrics
with slow judge-based postprocessing.

Smoke test:

```bash
cd /gemini/space/zhouyike/lmms-eval
source examples/llava15_tier3/env.sh

LIMIT=20 \
bash examples/llava15_tier3/08_run_new10_qwenjudge.sh
```

Full run:

```bash
cd /gemini/space/zhouyike/lmms-eval
source examples/llava15_tier3/env.sh

bash examples/llava15_tier3/08_run_new10_qwenjudge.sh
```

Outputs:

```text
/gemini/space/zhouyike/lmms-eval/results/llava-v1.5-7b_new10_qwenjudge/offline8
/gemini/space/zhouyike/lmms-eval/results/llava-v1.5-7b_new10_qwenjudge/livebench
/gemini/space/zhouyike/lmms-eval/results/llava-v1.5-7b_new10_qwenjudge/livebench/livebench_qwenjudge_audit.jsonl
```

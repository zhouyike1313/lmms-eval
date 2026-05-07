# LLaVA-1.5 Tier-3 Benchmark Pipeline

这组脚本用于在 `/gemini/space/zhouyike/lmms-eval` 复现 LLaVA-1.5 在以下 benchmark 上的 `lmms-eval` pipeline：

| Benchmark | 默认 task | 说明 |
| --- | --- | --- |
| VQAv2 | `vqav2_val` | General VQA baseline，默认跑 validation 以直接出指标 |
| GQA | `gqa` | Compositional reasoning |
| DocVQA | `docvqa_val` | Document understanding，默认跑 validation |
| ChartQA | `chartqa` | Chart reasoning |
| OCRBench | `ocrbench` | Broad OCR coverage |
| COCOcap | `coco2014_cap_val` | Captioning，默认跑 2014 val 以直接出 COCO caption 指标 |
| AI2D | `ai2d` | Diagram reasoning |
| POPE | `pope` | Hallucination |
| MMStar | `mmstar` | Fine-grained visual perception |
| NoCaps | `nocaps_val` | Out-of-domain captioning，默认跑 validation |

PDF 里的 `vqav2`、`docvqa`、`coco_cap`、`nocaps` 是 group 名，其中有些会包含 test split；test split 通常只生成 submission 文件，不一定有本地指标。为了 baseline 表格更直接，`03_run_tier3.sh` 默认使用上表这些可出指标的 task。

## 1. 准备环境

```bash
cd /gemini/space/zhouyike/lmms-eval
bash examples/llava15_tier3/00_prepare_env.sh
```

默认会：

- 激活 `/gemini/space/zhouyike/env/lmms_eval`
- 设置你给的 proxy、`GIT_SSL_NO_VERIFY=1`
- 把 Hugging Face cache 放到仓库下的 `.cache/huggingface`
- `pip install --no-deps -e .`
- 安装 `json-repair`
- clone 并 editable 安装 `third_party/LLaVA`

如果你想严格复现旧版 LLaVA-1.5 paper 依赖，可以额外执行：

```bash
INSTALL_REPR_REQUIREMENTS=1 bash examples/llava15_tier3/00_prepare_env.sh
```

caption 任务 `COCOcap`/`NoCaps` 依赖 Java tokenizer，建议检查：

```bash
java -version
```

如果没有 Java 8，需要在服务器上装 `openjdk=8`。

## 2. 下载模型

```bash
bash examples/llava15_tier3/01_download_llava15.sh 7b
```

13B：

```bash
bash examples/llava15_tier3/01_download_llava15.sh 13b
```

模型默认落到：

```text
/gemini/space/zhouyike/lmms-eval/models/llava-v1.5-7b
/gemini/space/zhouyike/lmms-eval/models/llava-v1.5-13b
```

## 3. 预热数据集下载

```bash
source examples/llava15_tier3/env.sh
python examples/llava15_tier3/prefetch_tier3_datasets.py
```

这一步会通过 `datasets.load_dataset(...)` 把十个默认 task 需要的数据集拉进 `HF_DATASETS_CACHE`。如果某个数据集需要 Hugging Face token，先执行 `hf auth login` 或设置 `HF_TOKEN`。

如果希望一个数据集一个数据集下载，并把每个 traceback 单独保存到日志：

```bash
bash examples/llava15_tier3/04_prefetch_tier3_datasets.sh
```

日志位置：

```text
/gemini/space/zhouyike/lmms-eval/results/llava-v1.5-7b/dataset_prefetch_logs/
```

## 4. 小样本 smoke test

默认先跑 `ai2d_lite` 的 5 条样本：

```bash
bash examples/llava15_tier3/02_smoke_test.sh
```

要按 PDF 跑 full AI2D 的 5 条：

```bash
SMOKE_TASK=ai2d SMOKE_LIMIT=5 bash examples/llava15_tier3/02_smoke_test.sh
```

## 5. 全量跑十个 benchmark

```bash
bash examples/llava15_tier3/03_run_tier3.sh
```

结果会按 task 分目录保存到：

```text
/gemini/space/zhouyike/lmms-eval/results/llava-v1.5-7b/<task>/
```

先做 dry run 可以加 `LIMIT`：

```bash
LIMIT=20 bash examples/llava15_tier3/03_run_tier3.sh
```

多卡数据并行：

```bash
NUM_PROCESSES=4 bash examples/llava15_tier3/03_run_tier3.sh
```

13B：

```bash
MODEL_SIZE=13b MODEL_PATH=/gemini/space/zhouyike/lmms-eval/models/llava-v1.5-13b bash examples/llava15_tier3/03_run_tier3.sh
```

如果你想完全按 PDF 的 group/task 串跑：

```bash
TASKS=vqav2,gqa,docvqa_val,chartqa,ocrbench,coco_cap,nocaps,ai2d,pope,mmstar \
  bash examples/llava15_tier3/03_run_tier3.sh
```

## 常见卡点

- 不要给当前仓库版本的 `--model_args` 传 `use_flash_attention_2=False`；当前 `llava` adapter 会拒绝未知 kwargs。
- LLaVA-1.5 默认 `conv_template=vicuna_v1`。
- `--batch_size 1` 最稳，尤其是 13B 和 caption/OCR 类任务。
- `COCOcap`/`NoCaps` 若在 METEOR/tokenizer 阶段报错，优先检查 Java 8。
- 如果某个 task 下载或评测失败，可以先单独跑：

```bash
TASKS=chartqa LIMIT=10 bash examples/llava15_tier3/03_run_tier3.sh
```

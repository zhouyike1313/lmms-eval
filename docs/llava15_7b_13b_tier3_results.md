# LLaVA-1.5 7B vs 13B Tier-3 Results

This file records the user's lmms-eval benchmark results for LLaVA-1.5-7B and
LLaVA-1.5-13B on the Tier-3 task set.

Evaluation setup:

- Framework: `lmms-eval`
- Model family: LLaVA-1.5
- Few-shot: 0-shot
- Batch size: 1
- GPUs: `CUDA_VISIBLE_DEVICES=4,5,6,7`
- Main task set: `vqav2_val,gqa,docvqa_val,chartqa,ocrbench,coco2014_cap_val,ai2d,pope,mmstar,nocaps_val`

Note: The 13B result pasted in chat was split into two table fragments. The
first fragment contained AI2D, ChartQA, and COCO Bleu metrics; the later fragment
starting from `coco_CIDEr` through `vqav2_val` is treated as the continuation of
the 13B table.

## 13B Results

| Tasks | Filter | n-shot | Metric | Direction | Value | Stderr | Stderr_CLT |
|---|---|---:|---|:---:|---:|:---:|:---:|
| ai2d | flexible-extract | 0 | exact_match | ↑ | 0.5929 | 0.0088 | 0.0088 |
| chartqa | none | 0 | relaxed_augmented_split | ↑ | 0.1392 | 0.0098 | 0.0098 |
| chartqa | none | 0 | relaxed_human_split | ↑ | 0.2256 | 0.0118 | 0.0118 |
| chartqa | none | 0 | relaxed_overall | ↑ | 0.1824 | 0.0077 | 0.0077 |
| coco2014_cap_val | none | 0 | coco_Bleu_1 | ↑ | 0.7476 | N/A | N/A |
| coco2014_cap_val | none | 0 | coco_Bleu_2 | ↑ | 0.5834 | N/A | N/A |
| coco2014_cap_val | none | 0 | coco_Bleu_3 | ↑ | 0.4349 | N/A | N/A |
| coco2014_cap_val | none | 0 | coco_Bleu_4 | ↑ | 0.3163 | N/A | N/A |
| coco2014_cap_val | none | 0 | coco_CIDEr | ↑ | 1.1386 | N/A | N/A |
| coco2014_cap_val | none | 0 | coco_METEOR | ↑ | 0.2962 | N/A | N/A |
| coco2014_cap_val | none | 0 | coco_ROUGE_L | ↑ | 0.5667 | N/A | N/A |
| docvqa_val | none | 0 | anls | ↑ | 0.2354 | 0.0051 | 0.0051 |
| gqa | none | 0 | exact_match | ↑ | 0.6329 | 0.0043 | 0.0043 |
| mmstar | none | 0 | average | ↑ | 0.3598 | N/A | 0.0122 |
| mmstar | none | 0 | coarse perception | ↑ | 0.6560 | N/A | 0.0313 |
| mmstar | none | 0 | fine-grained perception | ↑ | 0.2943 | N/A | 0.0283 |
| mmstar | none | 0 | instance reasoning | ↑ | 0.4166 | N/A | 0.0314 |
| mmstar | none | 0 | logical reasoning | ↑ | 0.2928 | N/A | 0.0278 |
| mmstar | none | 0 | math | ↑ | 0.2766 | N/A | 0.0281 |
| mmstar | none | 0 | science & technology | ↑ | 0.2223 | N/A | 0.0257 |
| nocaps_val | none | 0 | nocaps_Bleu_1 | ↑ | 0.8431 | N/A | N/A |
| nocaps_val | none | 0 | nocaps_Bleu_2 | ↑ | 0.7005 | N/A | N/A |
| nocaps_val | none | 0 | nocaps_Bleu_3 | ↑ | 0.5546 | N/A | N/A |
| nocaps_val | none | 0 | nocaps_Bleu_4 | ↑ | 0.4249 | N/A | N/A |
| nocaps_val | none | 0 | nocaps_CIDEr | ↑ | 1.0933 | N/A | N/A |
| nocaps_val | none | 0 | nocaps_METEOR | ↑ | 0.3066 | N/A | N/A |
| nocaps_val | none | 0 | nocaps_ROUGE_L | ↑ | 0.6036 | N/A | N/A |
| ocrbench | none | 0 | ocrbench_accuracy | ↑ | 0.3360 | N/A | 0.0149 |
| pope | none | 0 | pope_accuracy | ↑ | 0.8712 | N/A | 0.0035 |
| pope | none | 0 | pope_f1_score | ↑ | 0.8595 | N/A | 0.0035 |
| pope | none | 0 | pope_precision | ↑ | 0.9453 | N/A | 0.0035 |
| pope | none | 0 | pope_recall | ↑ | 0.7880 | N/A | 0.0035 |
| pope | none | 0 | pope_yes_ratio | ↑ | 0.5000 | N/A | 0.0035 |
| vqav2_val | none | 0 | exact_match | ↑ | 0.7834 | 0.0008 | 0.0008 |

## 7B Results

| Tasks | Filter | n-shot | Metric | Direction | Value | Stderr | Stderr_CLT |
|---|---|---:|---|:---:|---:|:---:|:---:|
| ai2d | flexible-extract | 0 | exact_match | ↑ | 0.5508 | 0.0090 | 0.0090 |
| chartqa | none | 0 | relaxed_augmented_split | ↑ | 0.1424 | 0.0099 | 0.0099 |
| chartqa | none | 0 | relaxed_human_split | ↑ | 0.2224 | 0.0118 | 0.0118 |
| chartqa | none | 0 | relaxed_overall | ↑ | 0.1824 | 0.0077 | 0.0077 |
| coco2014_cap_val | none | 0 | coco_Bleu_1 | ↑ | 0.7323 | N/A | N/A |
| coco2014_cap_val | none | 0 | coco_Bleu_2 | ↑ | 0.5659 | N/A | N/A |
| coco2014_cap_val | none | 0 | coco_Bleu_3 | ↑ | 0.4167 | N/A | N/A |
| coco2014_cap_val | none | 0 | coco_Bleu_4 | ↑ | 0.2991 | N/A | N/A |
| coco2014_cap_val | none | 0 | coco_CIDEr | ↑ | 1.0875 | N/A | N/A |
| coco2014_cap_val | none | 0 | coco_METEOR | ↑ | 0.2933 | N/A | N/A |
| coco2014_cap_val | none | 0 | coco_ROUGE_L | ↑ | 0.5586 | N/A | N/A |
| docvqa_val | none | 0 | anls | ↑ | 0.2150 | 0.0049 | 0.0049 |
| gqa | none | 0 | exact_match | ↑ | 0.6192 | 0.0043 | 0.0043 |
| mmstar | none | 0 | average | ↑ | 0.3377 | N/A | 0.0121 |
| mmstar | none | 0 | coarse perception | ↑ | 0.6340 | N/A | 0.0312 |
| mmstar | none | 0 | fine-grained perception | ↑ | 0.2563 | N/A | 0.0278 |
| mmstar | none | 0 | instance reasoning | ↑ | 0.3889 | N/A | 0.0310 |
| mmstar | none | 0 | logical reasoning | ↑ | 0.2892 | N/A | 0.0281 |
| mmstar | none | 0 | math | ↑ | 0.2730 | N/A | 0.0278 |
| mmstar | none | 0 | science & technology | ↑ | 0.1848 | N/A | 0.0235 |
| nocaps_val | none | 0 | nocaps_Bleu_1 | ↑ | 0.8269 | N/A | N/A |
| nocaps_val | none | 0 | nocaps_Bleu_2 | ↑ | 0.6798 | N/A | N/A |
| nocaps_val | none | 0 | nocaps_Bleu_3 | ↑ | 0.5311 | N/A | N/A |
| nocaps_val | none | 0 | nocaps_Bleu_4 | ↑ | 0.4030 | N/A | N/A |
| nocaps_val | none | 0 | nocaps_CIDEr | ↑ | 1.0555 | N/A | N/A |
| nocaps_val | none | 0 | nocaps_METEOR | ↑ | 0.3037 | N/A | N/A |
| nocaps_val | none | 0 | nocaps_ROUGE_L | ↑ | 0.5946 | N/A | N/A |
| ocrbench | none | 0 | ocrbench_accuracy | ↑ | 0.3140 | N/A | 0.0147 |
| pope | none | 0 | pope_accuracy | ↑ | 0.8696 | N/A | 0.0036 |
| pope | none | 0 | pope_f1_score | ↑ | 0.8585 | N/A | 0.0036 |
| pope | none | 0 | pope_precision | ↑ | 0.9381 | N/A | 0.0036 |
| pope | none | 0 | pope_recall | ↑ | 0.7913 | N/A | 0.0036 |
| pope | none | 0 | pope_yes_ratio | ↑ | 0.5000 | N/A | 0.0036 |
| vqav2_val | none | 0 | exact_match | ↑ | 0.7670 | 0.0008 | 0.0008 |

## 13B - 7B Delta

Positive values mean 13B is higher.

| Tasks | Metric | 7B | 13B | Delta |
|---|---|---:|---:|---:|
| ai2d | exact_match | 0.5508 | 0.5929 | +0.0421 |
| chartqa | relaxed_augmented_split | 0.1424 | 0.1392 | -0.0032 |
| chartqa | relaxed_human_split | 0.2224 | 0.2256 | +0.0032 |
| chartqa | relaxed_overall | 0.1824 | 0.1824 | +0.0000 |
| coco2014_cap_val | coco_Bleu_1 | 0.7323 | 0.7476 | +0.0153 |
| coco2014_cap_val | coco_Bleu_2 | 0.5659 | 0.5834 | +0.0175 |
| coco2014_cap_val | coco_Bleu_3 | 0.4167 | 0.4349 | +0.0182 |
| coco2014_cap_val | coco_Bleu_4 | 0.2991 | 0.3163 | +0.0172 |
| coco2014_cap_val | coco_CIDEr | 1.0875 | 1.1386 | +0.0511 |
| coco2014_cap_val | coco_METEOR | 0.2933 | 0.2962 | +0.0029 |
| coco2014_cap_val | coco_ROUGE_L | 0.5586 | 0.5667 | +0.0081 |
| docvqa_val | anls | 0.2150 | 0.2354 | +0.0204 |
| gqa | exact_match | 0.6192 | 0.6329 | +0.0137 |
| mmstar | average | 0.3377 | 0.3598 | +0.0221 |
| mmstar | coarse perception | 0.6340 | 0.6560 | +0.0220 |
| mmstar | fine-grained perception | 0.2563 | 0.2943 | +0.0380 |
| mmstar | instance reasoning | 0.3889 | 0.4166 | +0.0277 |
| mmstar | logical reasoning | 0.2892 | 0.2928 | +0.0036 |
| mmstar | math | 0.2730 | 0.2766 | +0.0036 |
| mmstar | science & technology | 0.1848 | 0.2223 | +0.0375 |
| nocaps_val | nocaps_Bleu_1 | 0.8269 | 0.8431 | +0.0162 |
| nocaps_val | nocaps_Bleu_2 | 0.6798 | 0.7005 | +0.0207 |
| nocaps_val | nocaps_Bleu_3 | 0.5311 | 0.5546 | +0.0235 |
| nocaps_val | nocaps_Bleu_4 | 0.4030 | 0.4249 | +0.0219 |
| nocaps_val | nocaps_CIDEr | 1.0555 | 1.0933 | +0.0378 |
| nocaps_val | nocaps_METEOR | 0.3037 | 0.3066 | +0.0029 |
| nocaps_val | nocaps_ROUGE_L | 0.5946 | 0.6036 | +0.0090 |
| ocrbench | ocrbench_accuracy | 0.3140 | 0.3360 | +0.0220 |
| pope | pope_accuracy | 0.8696 | 0.8712 | +0.0016 |
| pope | pope_f1_score | 0.8585 | 0.8595 | +0.0010 |
| pope | pope_precision | 0.9381 | 0.9453 | +0.0072 |
| pope | pope_recall | 0.7913 | 0.7880 | -0.0033 |
| pope | pope_yes_ratio | 0.5000 | 0.5000 | +0.0000 |
| vqav2_val | exact_match | 0.7670 | 0.7834 | +0.0164 |

## Brief Summary

The 13B model improves over 7B on most reported metrics. Larger gains appear on
AI2D, MMStar fine-grained/science categories, OCRBench, DocVQA, VQAv2, and
caption metrics. ChartQA overall is unchanged, ChartQA augmented split is
slightly lower for 13B, and POPE recall is slightly lower while POPE precision
is higher.

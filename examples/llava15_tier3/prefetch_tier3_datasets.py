#!/usr/bin/env python
import argparse
import os
import traceback
from dataclasses import dataclass
from typing import Optional

from datasets import load_dataset


@dataclass(frozen=True)
class DatasetSpec:
    label: str
    path: str
    split: str
    name: Optional[str] = None
    local_dir: Optional[str] = None


DATASETS = [
    DatasetSpec("vqav2_val", "lmms-lab/VQAv2", "validation", local_dir="VQAv2"),
    DatasetSpec("gqa", "lmms-lab/GQA", "testdev", "testdev_balanced_instructions", "GQA"),
    DatasetSpec("docvqa_val", "lmms-lab/DocVQA", "validation", "DocVQA", "DocVQA"),
    DatasetSpec("chartqa", "lmms-lab/ChartQA", "test", local_dir="ChartQA"),
    DatasetSpec("ocrbench", "echo840/OCRBench", "test", local_dir="OCRBench"),
    DatasetSpec("coco2014_cap_val", "lmms-lab/COCO-Caption", "val", local_dir="COCO-Caption"),
    DatasetSpec("ai2d", "lmms-lab/ai2d", "test", local_dir="ai2d"),
    DatasetSpec("pope", "lmms-lab/POPE", "test", local_dir="POPE"),
    DatasetSpec("mmstar", "Lin-Chen/MMStar", "val", local_dir="MMStar"),
    DatasetSpec("nocaps_val", "lmms-lab/NoCaps", "validation", local_dir="NoCaps"),
]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--only",
        nargs="*",
        default=None,
        help="Optional dataset labels to prefetch, for example: --only ai2d mmstar",
    )
    parser.add_argument("--fail-fast", action="store_true")
    args = parser.parse_args()

    selected = DATASETS
    if args.only:
        wanted = set(args.only)
        selected = [spec for spec in DATASETS if spec.label in wanted]
        missing = wanted - {spec.label for spec in selected}
        if missing:
            raise SystemExit(f"Unknown dataset label(s): {', '.join(sorted(missing))}")

    cache_dir = os.environ.get("HF_DATASETS_CACHE")
    local_root = os.environ.get("LOCAL_DATASET_ROOT")
    if local_root is None:
        repo_root = os.environ.get("LMMS_EVAL_ROOT", os.getcwd())
        local_root = os.path.join(repo_root, "datasets_hf")
    token = os.environ.get("HF_TOKEN") or os.environ.get("HUGGING_FACE_HUB_TOKEN") or None
    print(f"HF_DATASETS_CACHE={cache_dir}")
    print(f"LOCAL_DATASET_ROOT={local_root}")
    failures = []
    for spec in selected:
        dataset_path = spec.path
        local_path = os.path.join(local_root, spec.local_dir or spec.label)
        if os.path.isdir(local_path):
            dataset_path = local_path
        print(f"\n[prefetch] {spec.label}: {dataset_path} name={spec.name} split={spec.split}")
        try:
            dataset = load_dataset(
                dataset_path,
                spec.name,
                split=spec.split,
                cache_dir=cache_dir,
                token=token,
            )
            print(f"[prefetch] loaded {len(dataset)} rows")
        except Exception:
            failures.append(spec.label)
            traceback.print_exc()
            if args.fail_fast:
                raise

    if failures:
        raise SystemExit(f"Failed dataset(s): {', '.join(failures)}")


if __name__ == "__main__":
    main()

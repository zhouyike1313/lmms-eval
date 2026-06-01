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


# New benchmark set requested after the original 10-task Tier-3 run.
#
# MME-P and MME-C are both produced by the same lmms-eval task `mme`, so there
# are 10 benchmark names but 9 lmms-eval task labels here.
DATASETS = [
    DatasetSpec("textvqa_val", "lmms-lab/textvqa", "validation", local_dir="textvqa"),
    DatasetSpec("infovqa_val", "lmms-lab/DocVQA", "validation", "InfographicVQA", "InfographicVQA"),
    DatasetSpec("seedbench_2", "lmms-lab/SEED-Bench-2", "test", local_dir="SEED-Bench-2"),
    # There is no exact `livevqa` task in this checkout. `live_bench_2409` is
    # the default Live-series VQA-style benchmark used for this reproduction.
    DatasetSpec("live_bench_2409", "lmms-lab/LiveBench", "test", "2024-09", "LiveBench"),
    DatasetSpec("scienceqa_img", "lmms-lab/ScienceQA", "test", "ScienceQA-IMG", "ScienceQA"),
    DatasetSpec("mme", "lmms-lab/MME", "test", local_dir="MME"),
    DatasetSpec("mmbench_en_dev", "lmms-lab/MMBench", "dev", "en", "MMBench"),
    DatasetSpec("realworldqa", "lmms-lab/RealWorldQA", "test", local_dir="RealWorldQA"),
    DatasetSpec("textcaps_val", "lmms-lab/TextCaps", "val", local_dir="TextCaps"),
]


def local_dataset_root() -> str:
    local_root = os.environ.get("LOCAL_DATASET_ROOT")
    if local_root:
        return local_root
    repo_root = os.environ.get("LMMS_EVAL_ROOT", os.getcwd())
    return os.path.join(repo_root, "datasets_hf_new10")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--only", nargs="*", default=None)
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
    local_root = local_dataset_root()
    token = os.environ.get("HF_TOKEN") or os.environ.get("HUGGING_FACE_HUB_TOKEN") or None

    print(f"HF_DATASETS_CACHE={cache_dir}")
    print(f"LOCAL_DATASET_ROOT={local_root}")
    print(f"HF_TOKEN_SET={1 if token else 0}")

    failures = []
    for spec in selected:
        local_path = os.path.join(local_root, spec.local_dir or spec.label)
        dataset_path = local_path if os.path.isdir(local_path) else spec.path
        try:
            if os.path.isdir(local_path):
                dataset_path = local_path

            print(f"\n[prefetch] {spec.label}: {dataset_path} name={spec.name} split={spec.split}")
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

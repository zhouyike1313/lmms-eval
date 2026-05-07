#!/usr/bin/env python
import argparse

from llava.mm_utils import get_model_name_from_path
from llava.model.builder import load_pretrained_model


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--model-path", required=True)
    parser.add_argument("--device-map", default="auto")
    args = parser.parse_args()

    model_name = get_model_name_from_path(args.model_path)
    tokenizer, model, image_processor, context_len = load_pretrained_model(
        model_path=args.model_path,
        model_base=None,
        model_name=model_name,
        device_map=args.device_map,
    )
    print("Model loaded successfully.")
    print(f"Model name: {model_name}")
    print(f"Context length: {context_len}")
    print(f"Tokenizer: {type(tokenizer).__name__}")
    print(f"Image processor: {type(image_processor).__name__}")
    print(f"Model dtype: {next(model.parameters()).dtype}")


if __name__ == "__main__":
    main()

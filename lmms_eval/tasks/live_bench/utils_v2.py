import base64
import json
import logging
import os
import re
import time
from io import BytesIO
from pathlib import Path

import httpx
import numpy as np
import openai
import pandas as pd
import requests
import yaml

eval_logger = logging.getLogger("lmms-eval")


with open(Path(__file__).parent / "live_bench.yaml", "r") as f:
    raw_data = f.readlines()
    safe_data = []
    for i, line in enumerate(raw_data):
        # remove function definition since yaml load cannot handle it
        if "!function" not in line:
            safe_data.append(line)

    config = yaml.safe_load("".join(safe_data))

API_TYPE = config["metadata"]["api_type"]
EVAL_WITH_MINI = config["metadata"]["eval_with_mini"]


def get_openai_client(api_version="2024-02-15-preview") -> openai.OpenAI:
    api_base = os.getenv("OPENAI_API_BASE") or os.getenv("OPENAI_BASE_URL") or os.getenv("LIVEBENCH_JUDGE_API_BASE")
    if api_base:
        api_key = os.getenv("OPENAI_API_KEY") or os.getenv("LIVEBENCH_JUDGE_API_KEY") or "EMPTY"
        trust_env = os.getenv("LIVEBENCH_JUDGE_TRUST_ENV", "0") == "1"
        timeout = float(os.getenv("LIVEBENCH_JUDGE_TIMEOUT", "180"))
        http_client = httpx.Client(trust_env=trust_env, timeout=timeout)
        eval_logger.info(f"Using OpenAI-compatible judge at {api_base} model={os.getenv('LIVEBENCH_JUDGE_MODEL') or os.getenv('OPENAI_MODEL') or 'gpt-4o'} trust_env={trust_env} timeout={timeout}")
        return openai.OpenAI(api_key=api_key, base_url=api_base, http_client=http_client)

    endpoint = os.getenv("AZURE_OPENAI_ENDPOINT")
    if endpoint:
        key = os.getenv("AZURE_OPENAI_API_KEY")
        if not key:
            raise ValueError("OPENAI_API_KEY environment variable not set.")
        return openai.AzureOpenAI(azure_endpoint=endpoint, api_key=key, api_version=api_version)
    else:
        api_key = os.getenv("OPENAI_API_KEY")
        if not api_key:
            raise ValueError("OPENAI_API_KEY environment variable not set.")
        return openai.OpenAI(api_key=api_key)


client = get_openai_client()

_PROMPT_WITH_IMAGE = """\
[Question]

{prompt}

[Assistant Response]

{generation}

[Ground Truth Response]

{reference}

[System]

Rate whether the assistant response correctly matches the ground truth, in regards to the image above.

The rating should be 0-10, where 0 is incorrect and 10 is correct.

Below is the specific criteria for rating:

{criteria}

Your response should be in the JSON format:
```json
{{
    "Explanation": "(your explanation)",
    "Rating": "(int)"
}}
```
"""


def format_prompt(question, ground_truth_answer, answer, criteria):
    prompt = _PROMPT_WITH_IMAGE.format(prompt=question, generation=answer, reference=ground_truth_answer, criteria=criteria)
    if os.getenv("LIVEBENCH_JUDGE_NO_THINK", "0") == "1":
        prompt += "\nDo not include chain-of-thought, analysis, markdown, or extra text. Return only one JSON object."
    return prompt


def _parse_judge_response(response_text):
    response_text = response_text.strip()
    response_text = re.sub(r"<think>.*?</think>", "", response_text, flags=re.DOTALL | re.IGNORECASE).strip()
    try:
        return json.loads(response_text)
    except json.JSONDecodeError:
        pass

    match = re.search(r"\{.*\}", response_text, flags=re.DOTALL)
    if match:
        return json.loads(match.group(0))
    raise json.JSONDecodeError("No JSON object found in judge response", response_text, 0)


def get_chat_response(gpt_model_name, base64_images, question, ground_truth_answer, answer, criteria, max_retries=None, wait_time=None):
    # client = openai.OpenAI(api_key=API_KEY)
    max_retries = int(os.getenv("LIVEBENCH_JUDGE_MAX_RETRIES", max_retries or 5))
    wait_time = int(os.getenv("LIVEBENCH_JUDGE_WAIT_TIME", wait_time or 10))
    timeout = float(os.getenv("LIVEBENCH_JUDGE_TIMEOUT", "180"))

    content = []
    for base64_image in base64_images:
        content.append({"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{base64_image}"}})
    prompt = format_prompt(question, ground_truth_answer, answer, criteria)
    content.append(
        {
            "type": "text",
            "text": prompt,
        }
    )

    messages = [
        {
            "role": "user",
            "content": content,
        }
    ]

    # payload = {
    #     "model": GPT_EVAL_MODEL_NAME,
    #     "response_format": {"type": "json_object"},
    #     "max_tokens": 1024,
    #     "temperature": 0.0,
    # }

    for attempt in range(max_retries):
        try:
            request_kwargs = {
                "model": gpt_model_name,
                "messages": messages,
                "max_tokens": int(os.getenv("LIVEBENCH_JUDGE_MAX_TOKENS", "1024")),
                "temperature": 0.0,
                "timeout": timeout,
            }
            if os.getenv("LIVEBENCH_JUDGE_JSON_MODE", "1") == "1":
                request_kwargs["response_format"] = {"type": "json_object"}
            if os.getenv("LIVEBENCH_JUDGE_NO_THINK", "0") == "1":
                request_kwargs["extra_body"] = {"chat_template_kwargs": {"enable_thinking": False}}
            start = time.time()
            eval_logger.info(f"LiveBench judge request start model={gpt_model_name} attempt={attempt + 1}/{max_retries} images={len(base64_images)} timeout={timeout}")
            response = client.chat.completions.create(**request_kwargs)
            eval_logger.info(f"LiveBench judge request finished in {time.time() - start:.2f}s")
            response_data = response.choices[0].message.content
            # print(response_data)
            response_data = _parse_judge_response(response_data)
            rating = response_data["Rating"]
            explanation = response_data["Explanation"]
            return rating, explanation, gpt_model_name
        except requests.exceptions.RequestException as e:
            eval_logger.warning(f"Request failed on attempt {attempt + 1}: {e}")
            time.sleep(wait_time)
            if attempt == max_retries - 1:
                eval_logger.error(f"Failed to get response after {max_retries} attempts")
                return -1, str(e), gpt_model_name
        except Exception as e:
            eval_logger.error(f"Error on attempt {attempt + 1}: {e}")
            return -1, str(e), gpt_model_name


def image_to_base64(pil_image):
    image = pil_image.convert("RGB")
    max_side = int(os.getenv("LIVEBENCH_JUDGE_MAX_IMAGE_SIDE", "1024"))
    if max_side > 0:
        width, height = image.size
        scale = min(max_side / max(width, height), 1.0)
        if scale < 1.0:
            image = image.resize((int(width * scale), int(height * scale)))

    buffered = BytesIO()
    image.save(buffered, format="JPEG", quality=int(os.getenv("LIVEBENCH_JUDGE_IMAGE_QUALITY", "85")))
    return base64.b64encode(buffered.getvalue()).decode("utf-8")


_images = {}

dataset = None


def livebench_doc_to_visual(doc):
    img_list = [image.convert("RGB") for image in doc["images"]]
    return img_list


def livebench_doc_to_text(doc, lmms_eval_specific_kwargs=None):
    if lmms_eval_specific_kwargs is None:
        lmms_eval_specific_kwargs = {}
    pre_prompt = lmms_eval_specific_kwargs.get("pre_prompt", "")
    post_prompt = lmms_eval_specific_kwargs.get("post_prompt", "")
    return f"{pre_prompt}{doc['question']}{post_prompt}"


SUBTASKS = ["Concrete Recognition", "Analytical Questions", "Divergent Thinking", "Real-world Assistance"]


def livebench_process_results_for_name(doc, results, model, eval_name):
    base64_images = [image_to_base64(image) for image in livebench_doc_to_visual(doc)]
    subtask = doc["subtask"]
    criteria = doc["criteria"]
    answer = results[0] if results else ""
    if not results or results[0] == "":
        explanation = "No response"
        _write_livebench_judge_audit(doc, subtask, 0, explanation, "N/A", answer, criteria)
        return {eval_name: {"rating": 0, "explanation": explanation, "model_name": "N/A", "subtask": subtask}}
    rating, explanation, model_name = get_chat_response(gpt_model_name=model, base64_images=base64_images, question=doc["question"], ground_truth_answer=doc["answer"], answer=answer, criteria=criteria)
    _write_livebench_judge_audit(doc, subtask, rating, explanation, model_name, answer, criteria)
    if rating >= 0:
        return {eval_name: {"rating": rating, "explanation": explanation, "model_name": model_name, "subtask": subtask, "id": doc["id"]}}
    else:
        return {eval_name: {"rating": -1, "explanation": explanation, "model_name": "N/A", "subtask": subtask, "id": doc["id"]}}


def _write_livebench_judge_audit(doc, subtask, rating, explanation, model_name, prediction, criteria):
    audit_path = os.getenv("LIVEBENCH_JUDGE_AUDIT_PATH")
    if not audit_path:
        return

    os.makedirs(os.path.dirname(audit_path), exist_ok=True)
    record = {
        "id": doc.get("id"),
        "subtask": subtask,
        "rating": rating,
        "explanation": explanation,
        "judge_model": model_name,
        "question": doc.get("question"),
        "ground_truth": doc.get("answer"),
        "prediction": prediction,
        "criteria": criteria,
    }
    with open(audit_path, "a", encoding="utf-8") as f:
        f.write(json.dumps(record, ensure_ascii=False) + "\n")


def livebench_process_results_4o(doc, results):
    model = os.getenv("LIVEBENCH_JUDGE_MODEL") or os.getenv("OPENAI_MODEL") or "gpt-4o"
    return livebench_process_results_for_name(doc, results, model, "gpt4_eval_score")


def livebench_process_results_4o_mini(doc, results):
    model = os.getenv("LIVEBENCH_JUDGE_MODEL_MINI") or "gpt-4o-mini"
    return livebench_process_results_for_name(doc, results, model, "gpt4_eval_score_mini")


def livebench_process_results(doc, results):
    res = livebench_process_results_4o(doc, results)
    if EVAL_WITH_MINI:
        res.update(livebench_process_results_4o_mini(doc, results))
    return res


def livebench_aggregate_results(results):
    sum_score, count = 0, 0
    score = {}
    for subtask in SUBTASKS:
        score[subtask] = []
    for result in results:
        if result["rating"] == -1:
            continue
        sum_score += result["rating"] / 10
        count += 1
        subtask = result["subtask"]
        if subtask not in SUBTASKS:
            subtask = "OTHER_SUBTASK"
        score[result["subtask"]].append(result["rating"] / 10)
    res = [(subtask, len(score[subtask]), np.mean(score[subtask]) * 100 if score[subtask] else None) for subtask in SUBTASKS]
    total_score = sum_score / count * 100 if count > 0 else None
    res.append(("Total", count, total_score))
    # print("count:", count)
    res = pd.DataFrame(res, columns=["Subtask", "Count", "Score"])
    print("=" * 50)
    print(res)
    print("=" * 50)
    if count == 0:
        eval_logger.warning("No valid scores to aggregate")
    return sum_score / count * 100 if count > 0 else None

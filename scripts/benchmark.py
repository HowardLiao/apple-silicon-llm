#!/usr/bin/env python3
"""
Apple Silicon Local LLM Benchmark Suite
Author: Howard Liao Ph.D.
Measures cold/warm latency, token generation speed, and resident memory.
"""

import json
import subprocess
import sys
import time
import urllib.request

BENCHMARK_PROMPTS = [
    {
        "name": "Algorithm (Quicksort + Generics)",
        "prompt": "Implement quicksort algorithm in Python with TypeVar, List annotations, docstring, and a brief explanation.",
    },
    {
        "name": "Refactoring & Regex",
        "prompt": "Write a robust email and IPv4 validator in Python using regex with comprehensive edge cases.",
    },
]


def test_model(model_name: str, endpoint: str = "http://127.0.0.1:11434"):
    print(f"\n==========================================================")
    print(f"Benchmarking Model: {model_name} on {endpoint}")
    print(f"==========================================================")

    for case in BENCHMARK_PROMPTS:
        print(f"\n[Test Case] {case['name']}")
        payload = json.dumps({
            "model": model_name,
            "prompt": case["prompt"],
            "stream": False,
        }).encode("utf-8")

        req = urllib.request.Request(
            f"{endpoint}/api/generate",
            data=payload,
            headers={"Content-Type": "application/json"},
        )

        start_wall = time.time()
        try:
            with urllib.request.urlopen(req, timeout=120) as resp:
                data = json.loads(resp.read().decode("utf-8"))
        except Exception as e:
            print(f"Error executing benchmark: {e}")
            continue

        wall_duration = time.time() - start_wall

        eval_count = data.get("eval_count", 0)
        eval_duration = data.get("eval_duration", 1) / 1e9  # nanoseconds to seconds
        prompt_eval_count = data.get("prompt_eval_count", 0)
        prompt_eval_duration = data.get("prompt_eval_duration", 1) / 1e9
        load_duration = data.get("load_duration", 0) / 1e9

        speed = eval_count / eval_duration if eval_duration > 0 else 0
        prefill_speed = (
            prompt_eval_count / prompt_eval_duration
            if prompt_eval_duration > 0
            else 0
        )

        print(f"  * Wall Clock Time       : {wall_duration:.2f} s")
        print(f"  * Model Load Duration   : {load_duration:.3f} s")
        print(
            f"  * Prompt Prefill Speed  : {prefill_speed:.1f} tok/s ({prompt_eval_count} tokens in {prompt_eval_duration:.2f} s)"
        )
        print(
            f"  * Output Eval Speed     : {speed:.2f} tok/s ({eval_count} tokens in {eval_duration:.2f} s)"
        )

    # Check RAM RSS of llama-server
    try:
        ps_out = subprocess.check_output(
            ["ps", "-eo", "rss,comm", "-r"], text=True
        )
        for line in ps_out.splitlines():
            if "llama-server" in line:
                rss_kb = int(line.strip().split()[0])
                rss_gb = rss_kb / 1024 / 1024
                print(f"\n[Memory Check] Active llama-server RSS: {rss_gb:.2f} GB")
                break
    except Exception:
        pass


if __name__ == "__main__":
    target = sys.argv[1] if len(sys.argv) > 1 else "qwen2.5-coder:14b"
    test_model(target)

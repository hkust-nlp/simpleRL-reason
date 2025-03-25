from datasets import load_dataset
import pandas as pd
from math_verify import verify, parse

data_path = "https://raw.githubusercontent.com/hkust-nlp/simpleRL-reason/refs/heads/v0/train/data/math_level3to5_data_processed_with_qwen_prompt.json"

df = pd.read_json(data_path)

for i, example in df.iterrows():
    print(f"\nExample {i+1}:")
    print(f"Question: {example['question']}")
    print(f"Answer: {example['answer']}")
    print("-" * 80)
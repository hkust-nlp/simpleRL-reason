from datasets import load_dataset
import pandas as pd
from math_verify import verify, parse

data_path = "https://raw.githubusercontent.com/hkust-nlp/simpleRL-reason/refs/heads/v0/train/data/math_level3to5_data_processed_with_qwen_prompt.json"

df_simple_rl = pd.read_json(data_path)

output = []

print("Using train dataset")
for i, example in df_simple_rl.iterrows():
    output.append({
        "data_source": "simplelr",
        "prompt": [
            {
                "role": "user",
                "content": example['question'] + "\n" + "Please reason step by step, and put your final answer within \\boxed{}."
            }
        ],
        "ability": "math",
        "reward_model": {
            "style": "rule",
            "ground_truth": example['answer']
        },
        "extra_info": {
            "answer": example['answer']
        }
    })

df_output = pd.DataFrame(output)

# Save as parquet file
output_path = "train.parquet"
df_output.to_parquet(output_path)
print(f"Dataset saved to {output_path}")
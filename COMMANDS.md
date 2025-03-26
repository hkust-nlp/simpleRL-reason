
```bash
# One time setup
cp sample.envrc .envrc
# Go to https://wandb.ai/authorize and fill in the WANDB_API_KEY
direnv allow

source ~/miniconda3/bin/activate && conda create -y --prefix ./env python=3.10
source ~/miniconda3/bin/activate && conda activate ./env
pip install uv
uv pip install "torch==2.4.0" --index-url https://download.pytorch.org/whl/cu124
uv pip install flash-attn --no-build-isolation
uv pip install -e .
# For some reason installing these packages individually is necessary
uv pip install accelerate
uv pip install codetiming
uv pip install "datasets>=2.16.0"
uv pip install dill
uv pip install numpy
uv pip install pybind11
uv pip install "ray[default]==2.10.0"
uv pip install tensordict
uv pip install "transformers<4.48"
uv pip install "vllm<=0.6.3"
uv pip install peft
uv pip install liger-kernel
uv pip install word2number
uv pip install "omegaconf==2.4.0.dev3"
uv pip install "hydra-core==1.4.0.dev1"
uv pip install "math-verify[antlr4_11_0]==0.6.0"

tmux

# launch the master node of ray 
source ~/miniconda3/bin/activate && conda activate ./env
ray start --head --node-ip-address 0.0.0.0 --num-gpus 7

# Worker nodes
source ~/miniconda3/bin/activate && conda activate ./env
ray start --address fgfq8m6zdljvr2.runpod.internal:6379  --num-gpus 6

# From master node
bash train_grpo_math_tune_ray.sh \
    --model_name Qwen/Qwen2.5-Math-7B \
    --max_response_length 8192  \
    --train_batch_size 1024 \
    --rollout_n 8 \
    --kl_loss_coef 0.0001 \
    --entropy_coeffient 0.001 \
    --rollout_gpu_memory_util 0.75 \
    --rollout_tp 2 \
    --save_freq 5
```
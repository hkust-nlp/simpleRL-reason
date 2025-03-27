
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

tmux

# launch the master node of ray
source ~/miniconda3/bin/activate && conda activate ./env
ray start --head --node-ip-address 10.1.31.5 --num-gpus 6 --dashboard-host 0.0.0.0

# Worker nodes
source ~/miniconda3/bin/activate && conda activate ./env
export MASTER_NODE_IP=10.1.31.5
ray start --address $MASTER_NODE_IP:6379  --num-gpus 6

# From master node
bash train_grpo_math_tune_ray.sh \
    --model_name Qwen/Qwen2.5-Math-7B \
    --max_response_length 8192  \
    --train_batch_size 768 \
    --rollout_n 8 \
    --kl_loss_coef 0.0001 \
    --entropy_coeffient 0.001 \
    --rollout_gpu_memory_util 0.75 \
    --rollout_tp 2 \
    --save_freq 5


# To view ray logs
tail -f /tmp/ray/session_*/logs/*

```
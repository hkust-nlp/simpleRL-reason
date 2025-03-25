
```bash
# One time setup
cp sample.envrc .envrc
# Go to https://wandb.ai/authorize and fill in the WANDB_API_KEY
direnv allow

source ~/miniconda3/bin/activate && conda create --prefix ./env python=3.9
source ~/miniconda3/bin/activate && conda activate ./env
pip install torch==2.4.0 --index-url https://download.pytorch.org/whl/cu124
pip install flash-attn --no-build-isolation
pip install -e . 
pip install ray[default]==2.10.0

tmux

# launch the master node of ray 
source ~/miniconda3/bin/activate && conda activate ./env
ray start --head --node-ip-address 0.0.0.0 --num-gpus 8

# Worker nodes
source ~/miniconda3/bin/activate && conda activate ./env
ray start --address {MASTER-NODE-ADDRESS}:6379  --num-gpus 8

# From master node
bash train_grpo_math_tune_ray.sh \
    --model_name Qwen-2.5-Math-7B \
    --max_response_length 8192  \
    --train_batch_size 1024 \
    --rollout_n 8 \
    --kl_loss_coef 0.0001 \
    --entropy_coeffient 0.001 \
    --rollout_gpu_memory_util 0.75 \
    --rollout_tp 2 \
    --save_freq 5
```
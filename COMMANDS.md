
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
# uv pip install "torch==2.4.0+cu118" --upgrade --index-url https://download.pytorch.org/whl/cu118
# uv pip install --upgrade "nvidia-nccl-cu12==2.19.3"
# uv pip install --upgrade "nvidia-nccl-cu12==2.26.2"
# uv pip install --upgrade "nvidia-nccl-cu12==2.18.3"
uv pip install --upgrade --force-reinstall "ray[default]==2.10.0"

python3 -c "import torch; print(torch.version.cuda)"

tmux

# launch the master node of ray
source ~/miniconda3/bin/activate && conda activate ./env
ray start --head \
--node-ip-address $MASTER_NODE_IP \
--num-gpus 8 \
--dashboard-host 0.0.0.0 \
--include-dashboard true

# Worker nodes
source ~/miniconda3/bin/activate && conda activate ./env
ray start --address $MASTER_NODE_IP:6379  --num-gpus 8

# From master node
bash train_grpo_math_tune_ray.sh \
    --model_name Qwen/Qwen2.5-Math-7B \
    --train_batch_size 1024 \
    --rollout_n 8 \
    --kl_loss_coef 0.0001 \
    --entropy_coeffient 0.001 \
    --rollout_gpu_memory_util 0.75 \
    --rollout_tp 2 \
    --save_freq 5


# To view ray logs
tail -f /tmp/ray/session_*/logs/*


# Testing bandwidth
apt-get install -y iperf3
# Server
iperf3 -s
# Client
iperf3 -c $MASTER_NODE_IP -t 10

apt install iputils-ping
ping -c 10 $MASTER_NODE_IP

apt install iftop
iftop -i podnet1
```

### 1 A100 node and 1 H100 node in US-KS-2
- 1 A100 SXM node and 1 H100 NVL node in US-KS-2
- 95 Mbits/sec = 11.875 MB/sec
- Ping: average latency is 1.07ms
![inter DC setup bandwidth](2.png)
- ___ steps took ____ before transitioning to same DC same GPU setup
- Took 1h 6m until crash due to vllm version
- Took 1h 4m until crash due to context length
- Took 1h 25m until crash due to GLOO_SOCKET_IFNAME
- Took ___ until run was created in wandb

### 2 A100 nodes in different DCs
- One node in US-KS-2 and the other in CA-MTL-3
- Had to keep a 8x A100 PCIE allocated for 9 hours before the second node was available
- 95 Mbits/sec = 11.875 MB/sec
  - Ping: average latency is 26.8ms
![intra DC setup bandwidth](1.png)
- Jobs took a while to start, so I moved onto same DC setup




Qwen/Qwen2.5-Math-7B: Max context length: 4096
- Max prompt length: 1024
- Max response length: 

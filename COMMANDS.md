
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

tmux

source ~/miniconda3/bin/activate && conda activate ./env
# launch the master node of ray 
ray start --head --node-ip-address 0.0.0.0 --num-gpus 8

# if you want to launch ray on more nodes, use
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


```bash
# Ec2 setup
sudo mkdir /workspace

# Only if EBS volume is new
sudo mkfs -t xfs /dev/nvme1n1

sudo mount /dev/nvme1n1 /workspace

echo '/dev/nvme1n1  /workspace  xfs  defaults,nofail  0  2' | sudo tee -a /etc/fstab

sudo chown ubuntu:ubuntu /workspace

cd /workspace && git clone https://github.com/aidando73/simpleRL-reason && realpath simpleRL-reason

git checkout aidand-v2
```
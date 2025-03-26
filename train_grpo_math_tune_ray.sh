#! /bin/bash

USER_ENV=`whoami`
set -x
export NCCL_DEBUG=DEBUG
export RAY_BACKEND_LOG_LEVEL=debug
export RAY_DEDUP_LOGS=1


export PROJECT_NAME=simplerl-math-grpo
# export WANDB_API_KEY=TO_BE_FILLED
export WANDB_OFFICIAL=1
export VLLM_ATTENTION_BACKEND=XFORMERS
export HDFS_DATA_PATH=/workspace/simpleRL-reason
export HDFS_MODEL_PATH=TO_BE_FILLED
export HDFS_CHECKPOINT_PATH=/workspace/simpleRL-reason/checkpoints
export HDFS_LOG_PATH=/workspace/simpleRL-reason/logs
mkdir -p $HDFS_LOG_PATH
mkdir -p $HDFS_CHECKPOINT_PATH
export RUN_NAME=v1
# export RAY_RUNTIME_ENV_TEMPORARY_REFERENCE_EXPIRATION_S=1800  # Add this line


# Default values
TRAIN_BATCH_SIZE=256
VAL_BATCH_SIZE=500
MAX_PROMPT_LENGTH=1024
MAX_RESPONSE_LENGTH=3072
LEARNING_RATE=5e-7
PPO_MINI_BATCH_SIZE=256
# per GPU
PPO_MICRO_BATCH_SIZE=2
CLIP_RATIO=0.2
KL_LOSS_COEF=0.001
ENTROPY_COEFFIENT=0.001
KL_LOSS_TYPE="low_var_kl"
TEMPERATURE=1.0
LOG_PROB_MICRO_BATCH_SIZE=160
ROLLOUT_N=8
KL_COEF=0.001
TOTAL_EPOCHS=20
DATASET_NAME=simplelr_math_35
ROLLOUT_GPU_MEMORY_UTIL=0.6
MODEL_NAME=Qwen2.5-Math-7B
SAVE_FREQ=20
TEST_FREQ=5
REMOVE_CLIP=False
ROLLOUT_TENSOR_MODEL_PARALLEL_SIZE=2
MICRO_ROLLOUT_BATCH_SIZE=1024
REMOVE_PREVIOUS_CKPT=False

generate_suffix() {
  local suffix=""
  local dataset_provided=false
  local model_provided=false
  local suffix_provided=false

  while [[ "$#" -gt 0 ]]; do
    case $1 in
      --train_batch_size) suffix+="_batch$2"; shift 2 ;;
      --val_batch_size) suffix+="_valbatch$2"; shift 2 ;;
      --max_prompt_length) suffix+="_max_prompt$2"; shift 2 ;;
      --max_response_length) suffix+="_max_response$2"; shift 2 ;;
      --learning_rate) suffix+="_lr$2"; shift 2 ;;
      --ppo_mini_batch_size) suffix+="_ppomini$2"; shift 2 ;;
      --ppo_micro_batch_size) shift 2 ;;
      --kl_loss_coef) suffix+="_klcoef$2"; shift 2 ;;
      --entropy_coeffient) suffix+="_entcoef$2"; shift 2 ;;
      --clip_ratio) suffix+="_clipratio$2"; shift 2 ;;
      --kl_loss_type) suffix+="_kltype$2"; shift 2 ;;
      --temperature) suffix+="_temp$2"; shift 2 ;;
      --log_prob_micro_batch_size) suffix+="_logprobbatch$2"; shift 2 ;;
      --rollout_n) suffix+="_rollout$2"; shift 2 ;;
      --kl_coef) suffix+="_klcontrol$2"; shift 2 ;;
      --total_epochs) suffix+="_epochs$2"; shift 2 ;;
      --rollout_gpu_memory_util) shift 2 ;;
      --dataset_name) suffix+="_$2"; dataset_provided=true; shift 2 ;;
      --model_name) model_name_sanitized=$(echo "$2" | tr '/' '_'); suffix+="_$model_name_sanitized"; model_provided=true; shift 2 ;;
      --remove_clip) suffix+="_remove_clip$2"; shift 2 ;;
      --suffix) input_suffix="$2"; suffix_provided=true; shift 2 ;;
      *) shift ;;
    esac
  done

  if [ "$dataset_provided" = false ]; then
    suffix+="_$DATASET_NAME"
  fi

  if [ "$model_provided" = false ]; then
    model_name_sanitized=$(echo "$MODEL_NAME" | tr '/' '_')
    suffix+="_$model_name_sanitized"
  fi

  if [ "$suffix_provided" = true ]; then
    suffix+="_$input_suffix"
  fi
  
  echo "$suffix"
}

echo "Arguments received: $@"

# Generate a unique suffix based on the input arguments
SUFFIX=$(generate_suffix "$@")
RUN_NAME="$RUN_NAME$SUFFIX"
LOG_FILE_PATH="$HDFS_LOG_PATH/$RUN_NAME.log"

# Parse named arguments
while [[ "$#" -gt 0 ]]; do
  echo "Processing: $1"
  case "$1" in
    --train_batch_size) TRAIN_BATCH_SIZE="$2"; shift 2 ;;
    --val_batch_size) VAL_BATCH_SIZE="$2"; shift 2 ;;
    --max_prompt_length) MAX_PROMPT_LENGTH="$2"; shift 2 ;;
    --max_response_length) MAX_RESPONSE_LENGTH="$2"; shift 2 ;;
    --learning_rate) LEARNING_RATE="$2"; shift 2 ;;
    --ppo_mini_batch_size) PPO_MINI_BATCH_SIZE="$2"; shift 2 ;;
    --ppo_micro_batch_size) PPO_MICRO_BATCH_SIZE="$2"; shift 2 ;;
    --kl_loss_coef) KL_LOSS_COEF="$2"; shift 2 ;;
    --entropy_coeffient) ENTROPY_COEFFIENT="$2"; shift 2 ;;
    --clip_ratio) CLIP_RATIO="$2"; shift 2 ;;
    --kl_loss_type) KL_LOSS_TYPE="$2"; shift 2 ;;
    --temperature) TEMPERATURE="$2"; shift 2 ;;
    --log_prob_micro_batch_size) LOG_PROB_MICRO_BATCH_SIZE="$2"; shift 2 ;;
    --rollout_n) ROLLOUT_N="$2"; shift 2 ;;
    --rollout_gpu_memory_util) ROLLOUT_GPU_MEMORY_UTIL="$2"; shift 2 ;;
    --rollout_tp) ROLLOUT_TENSOR_MODEL_PARALLEL_SIZE="$2"; shift 2 ;;
    --micro_rollout_batch_size) MICRO_ROLLOUT_BATCH_SIZE="$2"; shift 2 ;;
    --kl_coef) KL_COEF="$2"; shift 2 ;;
    --total_epochs) TOTAL_EPOCHS="$2"; shift 2 ;;
    --dataset_name) DATASET_NAME="$2"; shift 2 ;;
    --model_name) MODEL_NAME="$2"; shift 2 ;;
    --save_freq) SAVE_FREQ="$2"; shift 2 ;;
    --test_freq) TEST_FREQ="$2"; shift 2 ;;
    --remove_clip) REMOVE_CLIP="$2"; shift 2 ;;
    --remove_previous_ckpt) REMOVE_PREVIOUS_CKPT="$2"; shift 2 ;;
    --suffix) SUFFIX="$2"; shift 2 ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo "Training with the following parameters:"
echo "Train Batch Size: $TRAIN_BATCH_SIZE"
echo "Val Batch Size: $VAL_BATCH_SIZE" 
echo "Max Prompt Length: $MAX_PROMPT_LENGTH" 
echo "Max Response Length: $MAX_RESPONSE_LENGTH" 
echo "Learning Rate: $LEARNING_RATE" 
echo "PPO Mini Batch Size: $PPO_MINI_BATCH_SIZE" 
echo "PPO Micro Batch Size: $PPO_MICRO_BATCH_SIZE" 
echo "Micro Rollout Batch Size: $MICRO_ROLLOUT_BATCH_SIZE"
echo "KL Loss Coefficient: $KL_LOSS_COEF" 
echo "KL Loss Type: $KL_LOSS_TYPE" 
echo "Temperature: $TEMPERATURE" 
echo "Rollout N: $ROLLOUT_N" 
echo "KL Coefficient: $KL_COEF" 
echo "Total Epochs: $TOTAL_EPOCHS"
echo "Dataset Name: $DATASET_NAME"
echo "Model Name: $MODEL_NAME"
echo "Remove Clip: $REMOVE_CLIP"
echo "Remove Previous Ckpt: $REMOVE_PREVIOUS_CKPT"
echo "LOG FILE PATH: $LOG_FILE_PATH"

max_num_batched_tokens=$(expr $MAX_PROMPT_LENGTH + $MAX_RESPONSE_LENGTH + 1000)
echo -e "Training with the following parameters:\nTrain Batch Size: $TRAIN_BATCH_SIZE\nVal Batch Size: $VAL_BATCH_SIZE\nMax Prompt Length: $MAX_PROMPT_LENGTH\nMax Response Length: $MAX_RESPONSE_LENGTH\nLearning Rate: $LEARNING_RATE\nPPO Mini Batch Size: $PPO_MINI_BATCH_SIZE\nPPO Micro Batch Size: $PPO_MICRO_BATCH_SIZE\nKL Loss Coefficient: $KL_LOSS_COEF\nKL Loss Type: $KL_LOSS_TYPE\nTemperature: $TEMPERATURE\nRollout N: $ROLLOUT_N\nKL Coefficient: $KL_COEF\nTotal Epochs: $TOTAL_EPOCHS\nDataset Name: $DATASET_NAME\nModel Name: $MODEL_NAME"

mkdir -p $HDFS_CHECKPOINT_PATH/$RUN_NAME

ray job submit --address=127.0.0.1:6379 \
  --entrypoint-num-cpus=1 \
  --runtime-env-json='{
        "working_dir": "'${WORKING_DIR}'",
        "excludes": ["logs/*", "checkpoints/*", "env/*", "docker/*", "examples/*", "patches/*", "scripts/*", "tests/*", ".git/*"],
        "env_vars": {
          "http_proxy": "",
          "https_proxy": ""
        }
    }' \
  -- python -m verl.trainer.main_ppo \
  algorithm.adv_estimator=grpo \
  data.train_files=$HDFS_DATA_PATH/train.parquet \
  data.val_files=$HDFS_DATA_PATH/test.parquet \
  data.train_batch_size=$TRAIN_BATCH_SIZE \
  data.val_batch_size=$VAL_BATCH_SIZE \
  data.max_prompt_length=$MAX_PROMPT_LENGTH \
  data.max_response_length=$MAX_RESPONSE_LENGTH \
  actor_rollout_ref.model.path=$MODEL_NAME \
  actor_rollout_ref.actor.optim.lr=$LEARNING_RATE \
  actor_rollout_ref.model.use_remove_padding=True \
  actor_rollout_ref.actor.ppo_mini_batch_size=$PPO_MINI_BATCH_SIZE \
  actor_rollout_ref.actor.ppo_micro_batch_size_per_gpu=$PPO_MICRO_BATCH_SIZE \
  actor_rollout_ref.actor.use_kl_loss=True \
  actor_rollout_ref.actor.kl_loss_coef=$KL_LOSS_COEF \
  actor_rollout_ref.actor.entropy_coeff=$ENTROPY_COEFFIENT \
  actor_rollout_ref.actor.clip_ratio=$CLIP_RATIO \
  actor_rollout_ref.actor.kl_loss_type=$KL_LOSS_TYPE \
  actor_rollout_ref.model.enable_gradient_checkpointing=True \
  actor_rollout_ref.actor.fsdp_config.param_offload=False \
  actor_rollout_ref.actor.fsdp_config.grad_offload=False \
  actor_rollout_ref.actor.fsdp_config.optimizer_offload=False \
  actor_rollout_ref.rollout.temperature=$TEMPERATURE \
  actor_rollout_ref.rollout.log_prob_micro_batch_size=$LOG_PROB_MICRO_BATCH_SIZE \
  actor_rollout_ref.rollout.tensor_model_parallel_size=$ROLLOUT_TENSOR_MODEL_PARALLEL_SIZE \
  actor_rollout_ref.rollout.name=vllm \
  actor_rollout_ref.rollout.gpu_memory_utilization=$ROLLOUT_GPU_MEMORY_UTIL \
  actor_rollout_ref.rollout.n=$ROLLOUT_N \
  actor_rollout_ref.rollout.enable_chunked_prefill=False \
  actor_rollout_ref.rollout.max_num_batched_tokens=$max_num_batched_tokens \
  actor_rollout_ref.rollout.micro_rollout_batch_size=$MICRO_ROLLOUT_BATCH_SIZE \
  actor_rollout_ref.ref.log_prob_micro_batch_size=$LOG_PROB_MICRO_BATCH_SIZE \
  actor_rollout_ref.ref.fsdp_config.param_offload=True \
  algorithm.kl_ctrl.kl_coef=$KL_COEF \
  critic.ppo_micro_batch_size_per_gpu=4 \
  trainer.critic_warmup=0 \
  trainer.logger=['console','wandb'] \
  trainer.project_name=$PROJECT_NAME \
  trainer.remove_previous_ckpt=$REMOVE_PREVIOUS_CKPT \
  trainer.experiment_name=$RUN_NAME \
  trainer.n_gpus_per_node=6 \
  trainer.nnodes=2 \
  trainer.remove_clip=$REMOVE_CLIP \
  trainer.save_freq=$SAVE_FREQ \
  trainer.test_freq=$TEST_FREQ \
  trainer.default_local_dir=$HDFS_CHECKPOINT_PATH/$RUN_NAME \
  trainer.total_epochs=$TOTAL_EPOCHS 2>&1 | tee -a $LOG_FILE_PATH

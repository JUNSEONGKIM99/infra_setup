docker run -d \
  --name vllm-qwen32b-24k \
  --network data-network \
  --ipc=host \
  --shm-size=64g \
  --gpus all \
  -p 127.0.0.1:8091:8000 \
  -v /data/volumes/vllm-data/hf-cache:/root/.cache/huggingface \
  -v /data/volumes/vllm-data/lmcache:/root/.cache/lmcache \
  -e HF_HOME=/root/.cache/huggingface \
  -e LMCACHE_DIR=/root/.cache/lmcache \
  -e MODEL="Qwen/Qwen2.5-32B-Instruct-AWQ" \
  -e SERVED_MODEL_NAME="qwen-32b-24k" \
  -e QUANTIZATION="awq" \
  -e DTYPE="half" \
  -e KV_OFFLOADING_BACKEND="lmcache" \
  -e KV_OFFLOADING_SIZE="16" \
  -e DISABLE_HYBRID_KV_CACHE_MANAGER="1" \
  -e MAX_NUM_SEQS="64" \
  -e GPU_MEMORY_UTILIZATION="0.40" \
  -e MAX_MODEL_LEN="24000" \
  -e SWAP_SPACE="64" \
  -e ENFORCE_EAGER="1" \
  my-vllm:0.9.9



docker run -d \
  --name vllm-gemma27-vl \
  --network data-network \
  --ipc=host \
  --shm-size=64g \
  --gpus all \
  -p 127.0.0.1:8092:8000 \
  -v /data/volumes/vllm-data/hf-cache:/root/.cache/huggingface \
  -v /data/volumes/vllm-data/lmcache:/root/.cache/lmcache \
  -e HF_HOME=/root/.cache/huggingface \
  -e LMCACHE_DIR=/root/.cache/lmcache \
  -e MODEL="pytorch/gemma-3-27b-it-AWQ-INT4" \
  -e SERVED_MODEL_NAME="gemma-27b-vl" \
  -e DTYPE="bfloat16" \
  -e MAX_NUM_SEQS="32" \
  -e GPU_MEMORY_UTILIZATION="0.26" \
  -e MAX_MODEL_LEN="8192" \
  -e SWAP_SPACE="64" \
  -e KV_OFFLOADING_BACKEND="lmcache" \
  -e KV_OFFLOADING_SIZE="16" \
  -e DISABLE_HYBRID_KV_CACHE_MANAGER="1" \
  my-vllm:0.9.9

docker run -d \
  --name vllm-qwen-8b-emb \
  --network data-network \
  --ipc=host \
  --shm-size=64g \
  --gpus all \
  -p 127.0.0.1:8093:8000 \
  -v /data/volumes/vllm-data/hf-cache:/root/.cache/huggingface \
  -e HF_HOME=/root/.cache/huggingface \
  -e MODEL="Qwen/Qwen3-Embedding-8B" \
  -e SERVED_MODEL_NAME="qwen-8b-emb" \
  -e HOST="0.0.0.0" \
  -e PORT="8000" \
  -e DTYPE="bfloat16" \
  -e TRUST_REMOTE_CODE="0" \
  -e ENFORCE_EAGER="1" \
  -e GPU_MEMORY_UTILIZATION="0.18" \
  -e MAX_NUM_SEQS="32" \
  -e MAX_MODEL_LEN="8192" \
  my-vllm:0.8

#!/usr/bin/env bash
#!/usr/bin/env bash
set -euo pipefail

# Default values (override via docker run -e ...)
: "${MODEL:=Qwen/Qwen2.5-32B-Instruct-AWQ}"
: "${SERVED_MODEL_NAME:=local-model}"
: "${HOST:=0.0.0.0}"
: "${PORT:=8000}"

: "${GPU_MEMORY_UTILIZATION:=0.90}"
: "${MAX_MODEL_LEN:=8192}"

# New: quantization / dtype
# Examples:
#   QUANTIZATION=awq
#   DTYPE=half
: "${QUANTIZATION:=awq}"          # empty means "don't set --quantization"
: "${DTYPE:=half}"             # half is a safe default on modern GPUs

# New: CPU swap / eager
: "${SWAP_SPACE:=0}"           # in GiB; 0 disables --swap-space
: "${ENFORCE_EAGER:=0}"        # 1 to enable --enforce-eager

## max batch token - importent for kv cache size
: "${MAX_NUM_BATCHED_TOKENS:=0}"   # 0 means "don’t set"

## CPU offload gpu
: "${CPU_OFFLOAD_GB:=0}"

args=(
  --model "${MODEL}"
  --served-model-name "${SERVED_MODEL_NAME}"
  --host "${HOST}"
  --port "${PORT}"
  --gpu-memory-utilization "${GPU_MEMORY_UTILIZATION}"
  --max-model-len "${MAX_MODEL_LEN}"
  --dtype "${DTYPE}"
)

# Conditionally add optional flags
if [[ -n "${QUANTIZATION}" ]]; then
  args+=( --quantization "${QUANTIZATION}" )
fi

if [[ "${SWAP_SPACE}" != "0" ]]; then
  args+=( --swap-space "${SWAP_SPACE}" )
fi

if [[ "${ENFORCE_EAGER}" == "1" ]]; then
  args+=( --enforce-eager )
fi

if [[ "${MAX_NUM_BATCHED_TOKENS}" != "0" ]]; then
  args+=( --max-num-batched-tokens "${MAX_NUM_BATCHED_TOKENS}" )
fi

if [[ "${CPU_OFFLOAD_GB}" != "0" ]]; then
  args+=( --cpu-offload-gb "${CPU_OFFLOAD_GB}" )
fi

# Pass through any extra docker CMD args
exec python3 -m vllm.entrypoints.openai.api_server "${args[@]}" "$@"


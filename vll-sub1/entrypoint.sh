#!/usr/bin/env bash
set -euo pipefail

# Default values (override via docker run -e ...)
: "${MODEL:=Qwen/Qwen2.5-32B-Instruct-AWQ}"
: "${SERVED_MODEL_NAME:=local-model}"
: "${HOST:=0.0.0.0}"
: "${PORT:=8000}"

: "${GPU_MEMORY_UTILIZATION:=0.90}"
: "${MAX_MODEL_LEN:=8192}"

# Quantization / dtype
: "${QUANTIZATION:=}"      # empty means "don't set --quantization"
: "${DTYPE:=}"           # half is a safe default on modern GPUs

# CPU swap / eager
: "${SWAP_SPACE:=0}"         # in GiB; 0 disables --swap-space
: "${ENFORCE_EAGER:=0}"      # 1 to enable --enforce-eager

# max batch token - important for kv cache size
: "${MAX_NUM_BATCHED_TOKENS:=0}"   # 0 means "don’t set"

# CPU offload weights to RAM (slow). 0 disables.
: "${CPU_OFFLOAD_GB:=0}"

# Set KV_OFFLOADING_BACKEND=lmcache to enable
: "${KV_OFFLOADING_BACKEND:=}"     # "", "lmcache", (or "native" if you ever want)
: "${KV_OFFLOADING_SIZE:=0}"       # GiB, 0 means "don’t set"
: "${DISABLE_HYBRID_KV_CACHE_MANAGER:=1}"  # 1 adds --disable-hybrid-kv-cache-manager

## MAX concurrency (requests)
: "${MAX_NUM_SEQS:=0}"   # 0 = don’t set (unlimited)

## For VLM
: "${TRUST_REMOTE_CODE:=0}"   # 1 to enable --trust-remote-code

## Task type for Embedding
: "${TASK:=}"




args=(
  --model "${MODEL}"
  --served-model-name "${SERVED_MODEL_NAME}"
  --host "${HOST}"
  --port "${PORT}"
  --gpu-memory-utilization "${GPU_MEMORY_UTILIZATION}"
  --max-model-len "${MAX_MODEL_LEN}"
)

# Conditionally add optional flags
if [[ -n "${QUANTIZATION}" ]]; then
  args+=( --quantization "${QUANTIZATION}" )
fi

if [[ -n "${DTYPE}" ]]; then
  args+=( --dtype "${DTYPE}" )
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


if [[ -n "${TASK}" ]]; then
  args+=( --task "${TASK}" )
fi

# KV offloading flags
if [[ -n "${KV_OFFLOADING_BACKEND}" ]]; then
  args+=( --kv-offloading-backend "${KV_OFFLOADING_BACKEND}" )

  # strongly recommended to set a size when enabling kv offload
  if [[ "${KV_OFFLOADING_SIZE}" != "0" ]]; then
    args+=( --kv-offloading-size "${KV_OFFLOADING_SIZE}" )
  fi

  # LMCache commonly requires disabling hybrid manager
  if [[ "${DISABLE_HYBRID_KV_CACHE_MANAGER}" == "1" ]]; then
    args+=( --disable-hybrid-kv-cache-manager )
  fi
fi

## MAX
if [[ "${MAX_NUM_SEQS}" != "0" ]]; then
  args+=( --max-num-seqs "${MAX_NUM_SEQS}" )
fi

if [[ "${TRUST_REMOTE_CODE}" == "1" ]]; then
  args+=( --trust-remote-code )
fi


# Pass through any extra docker CMD args
exec python3 -m vllm.entrypoints.openai.api_server "${args[@]}" "$@"


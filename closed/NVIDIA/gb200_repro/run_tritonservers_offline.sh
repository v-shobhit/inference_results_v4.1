#!/bin/bash

#SBATCH --nodes=1
#SBATCH --account=gtc_inference
#SBATCH --time=04:00:00
#SBATCH --job-name="gtc_inference-mlperf_inference.llama2-triton_servers"
#SBATCH --comment "MLPerf Inference benchmark for TRTLLM"

set -x

repo_root=$(git rev-parse --show-toplevel)
username=$(whoami)

if [ -z "$CONTAINER_IMAGE" ]; then
    echo "Error: CONTAINER_IMAGE is not provided. Usage: sbatch --export=CONTAINER_IMAGE=value run_tritonserver_and_harness.sh"
    exit 1
fi

export CONTAINER_WORKDIR="/work"
export ACTUAL_WORKDIR="${repo_root}/closed/NVIDIA"

export CONTAINER_NAME="mlperf_inference_run_tritonserver"
export CONTAINER_MOUNT="$ACTUAL_WORKDIR:$CONTAINER_WORKDIR,/lustre/fsw/gtc_inference/${username}/mlperf_inference_storage_clone:/home/mlperf_inference_storage,/lustre/fsw/gtc_inference/${username}/artefacts:/home/artefacts"

export SRUN_HEADER="srun --container-image=$CONTAINER_IMAGE --container-mounts=$CONTAINER_MOUNT --container-workdir=$CONTAINER_WORKDIR"

### Get node names
node_list=$(scontrol show hostnames $SLURM_NODELIST)

### Launch tritonserver on each node
for node in $node_list; do
    $SRUN_HEADER --container-name=$CONTAINER_NAME --nodes=1 --ntasks-per-node=1 -w $node --output=slurm-$SLURM_JOB_ID-$node-tritonserver-log.out --mpi=pmix /opt/tritonserver/bin/tritonserver --model-repository=triton_repos/llama2_offline_nvl4/ --pinned-memory-pool-byte-size=0 --enable-peer-access=false --cuda-memory-pool-byte-size=0:0 --cuda-memory-pool-byte-size=1:0 --cuda-memory-pool-byte-size=2:0 --cuda-memory-pool-byte-size=3:0 --grpc-port=8001 --http-port=8000 --metrics-port=8002 --disable-auto-complete-config --backend-config=python,shm-region-prefix-name=prefix0_ &
done

### SIGINT the tritonservers manually to exit the job:
### srun --jobid=<JOB_ID> --overlap --container-name=mlperf_inference_run_tritonserver pkill -2 tritonserver

wait

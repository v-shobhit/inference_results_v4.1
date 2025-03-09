# Run v4.1 Llama2 workload on GB200 NVL

## Environment
Please use the latest TRTLLM + Triton release container at nvcr.io/nvidia/tritonserver:24.12-trtllm-python-py3, check the [release page](https://catalog.ngc.nvidia.com/orgs/nvidia/containers/tritonserver/tags)

Additional dependancies can be installed from running `install_deps.sh` under `closed/NVIDIA`

If you have pyxis+enroot, it's recommended to save a sqsh file onto disk for faster reruns:
```
srun --container-image=nvcr.io/nvidia/tritonserver:24.12-trtllm-python-py3 --container-save=/path/to/high_perf/storage/image_name.sqsh install_deps.sh
```
Now, you can use `image_name.sqsh` for all subsequent runs

## Engine build
In order to build an engine, use the following command:

```
python3 -m tensorrt_llm.commands.build \
    --workers=1 \
    --max_batch_size=2048 \
    --max_beam_width=1 \
    --kv_cache_type=paged \
    --remove_input_padding=enable \
    --multiple_profiles=enable \
    --use_fused_mlp=enable \
    --context_fmha=enable \
    --use_fp8_context_fmha=enable \
    --use_paged_context_fmha=enable \
    --max_num_tokens=3584 \
    --max_input_len=1024 \
    --max_seq_len=2048 \
    --tokens_per_block=32 \
    --gemm_plugin=nvfp4 \
    --checkpoint_dir=<path_to_quantized_ckpnt> \
    --output_dir=<path_to_engine_build_dir>
```

## Running tritonservers to serve Llama2
Use the repos in `closed/NVIDIA/triton_repos` to launch tritonserver. 
- In offline scenario, we launch a single tritonserver instance that launches 4 models, one on each GPU
- In server scenario, we launch 4 tritonserver instances, one that spawns a model on a single GPU. For this, run the script `slurm/run_server_nvl4.sh`

You can use the slurm scripts under `closed/NVIDIA/slurm/run_tritonservers_offline.sh` or `closed/NVIDIA/slurm/run_tritonservers_server.sh` to launch the tritonservers perpetually in a slurm job. 

## Running the benchmark
Once the tritonservers are launched, we can start a bash terminal in an overlapping job step via:
```
srun --jobid=<JOB_ID> --overlap --container-name=mlperf_inference_run_tritonserver --pty bash
```

Once inside the container, run the benchmark as follows.
### Offline
```
cd /work && ./slurm/run_harness_offline.sh
```
### Server
```
cd /work && ./slurm/run_harness_server.sh
```

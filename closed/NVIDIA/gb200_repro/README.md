# Run v4.1 Llama2 workload on GB200 NVL

## Environment
Please use the latest TRTLLM + Triton release container at nvcr.io/nvidia/tritonserver:24.12-trtllm-python-py3, check the [release page](https://catalog.ngc.nvidia.com/orgs/nvidia/containers/tritonserver/tags)

Additional dependancies can be installed from running `install_deps.sh` under `closed/NVIDIA`

If you have pyxis+enroot, it's recommended to save a sqsh file onto disk for faster reruns:
```
srun --container-image=nvcr.io/nvidia/tritonserver:24.12-trtllm-python-py3 --container-save=/path/to/high_perf/storage/image_name.sqsh install_deps.sh
```
Now, you can use `image_name.sqsh` for all subsequent runs

## Quantization
First it's required to quantize the model to nvfp4. Use the [tensorrt_llm/examples/quantization/quantize.py script](https://github.com/NVIDIA/TensorRT-LLM/blob/main/examples/quantization/quantize.py)
```
python3 tensorrt_llm/examples/quantization/quantize.py \
    --dtype float16 \
    --qformat nvfp4 \
    --kv_cache_dtype fp8 \
    --calib_size 1024  \
    --tp_size 1 \
    --pp_size 1 \
    --calib_dataset build/preprocessed_data/open_orca/mlperf_llama2_openorca_calibration_1k/ \
    --output_dir <path_to_quantized_ckpnt> \
    --model_dir <HF_model_ckpnt_path> 
```

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

You can use the slurm scripts under `closed/NVIDIA/gb200_repro/run_tritonservers_offline.sh` or `closed/NVIDIA/gb200_repro/run_tritonservers_server.sh` to launch the tritonservers perpetually in a slurm job. 

## Running the benchmark
Once the tritonservers are launched, we can start a bash terminal in an overlapping job step via:
```
srun --jobid=<JOB_ID> --overlap --container-name=mlperf_inference_run_tritonserver --pty bash
```

Once inside the container, run the benchmark as follows.
### Offline
```
cd /work && ./gb200_repro/run_harness_offline.sh
```
### Server
```
cd /work && ./gb200_repro/run_harness_server.sh
```

## Extending to multi-node (NVL36 or NVL72)
For multiple nodes, we need to first write a JSON file that defines the mapping of the `grpc_url` per model.

Each GPU has 1 instance of llama2-70B model. Say we run on 4 compute nodes. Here, we have total 16 llama2-70b instances. In this case, write a JSON file as below:

```
{
    "hostname_0": [8001, 8001, 8001, 8001],
    "hostname_1": [8001, 8001, 8001, 8001],
    "hostname_2": [8001, 8001, 8001, 8001],
    "hostname_3": [8001, 8001, 8001, 8001]
}
```

Then, in `gb200_repro/run_harness_offline.sh`, add a flag to the harness run command: `--grpc_ports_file PATH_TO_ABOVE_JSON`

For Server scenario, each host will have different ports since we spawn multiple tritonserver instances on a single host, 1 per GPU. 
For Offline scenario, a single tritonserver host may be used to launch models on all 4 GPUs, and the ports will be shared (as above) or it may be different

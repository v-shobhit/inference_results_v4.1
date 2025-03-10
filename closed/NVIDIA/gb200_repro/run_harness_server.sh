#!/bin/bash

python3 -m code.harness.harness_triton_llm.main \
    --logfile_outdir=/work/build/logs/GB200_NVL4_TRT_Triton/llama2-70b-99/Offline \
    --logfile_prefix=mlperf_log_ \
    --tensor_path=build/preprocessed_data/open_orca/input_ids_padded.npy,build/preprocessed_data/open_orca/input_lens.npy \
    --llm_gen_config_path=code/llama2-70b/tensorrt/generation_config.json \
    --use_token_latencies=true \
    --mlperf_conf_path=gb200_conf_files/Server/mlperf.conf \
    --user_conf_path=gb200_conf_files/Server/user.conf \
    --scenario Server \
    --model llama2-70b \
    --num_gpus 4 \
    --skip_server_spawn \
    --num_clients_per_gpu 4 \
    --num_frontends_per_gpu 12

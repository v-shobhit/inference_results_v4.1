#!/bin/sh

cd /work/build/
rm -rf mitten && git clone https://github.com/NVIDIA/mitten.git
cd mitten
git submodule update --init
sed -i 's/numpy >=1.22.0, <1.24.0/numpy >=1.26.4/' ./setup.cfg
pip install .

#!/bin/sh

# install typeguard
pip install typeguard

# install tritonclient
pip install tritonclient[all]

# install mitten
cd /work/build/
rm -rf mitten && git clone https://github.com/NVIDIA/mitten.git
cd mitten
git submodule update --init
sed -i 's/numpy >=1.22.0, <1.24.0/numpy >=1.26.4/' ./setup.cfg
pip install .

# install cmake
apt update
apt install -y software-properties-common lsb-release
wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null
apt-add-repository "deb https://apt.kitware.com/ubuntu/ $(lsb_release -cs) main"
apt install -y cmake

# install loadgen
cd /work
make build_loadgen

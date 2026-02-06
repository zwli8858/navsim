# 使用 NVIDIA CUDA 基础镜像 (支持 PyTorch 2.0.1)
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PATH=/opt/conda/bin:$PATH

# 安装系统依赖
RUN apt-get update && apt-get install -y 
    git 
    wget 
    curl 
    libgl1-mesa-glx 
    libglib2.0-0 
    build-essential 
    && rm -rf /var/lib/apt/lists/*

# 安装 Miniconda
RUN curl -L https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o miniconda.sh 
    && bash miniconda.sh -b -p /opt/conda 
    && rm miniconda.sh

# 设置工作目录
WORKDIR /workspace/navsim

# 复制环境配置文件
COPY environment.yml requirements.txt setup.py ./

# 创建 Conda 环境并安装依赖
RUN conda env create -f environment.yml 
    && conda clean -afy

# 默认激活 navsim 环境
RUN echo "conda activate navsim" >> ~/.bashrc

# 设置项目相关的环境变量 (容器内部路径)
ENV NUPLAN_MAP_VERSION="nuplan-maps-v1.0"
ENV NUPLAN_MAPS_ROOT="/workspace/dataset/maps"
ENV NAVSIM_EXP_ROOT="/workspace/exp"
ENV NAVSIM_DEVKIT_ROOT="/workspace/navsim"
ENV OPENSCENE_DATA_ROOT="/workspace/dataset"

# 默认进入 bash
CMD ["/bin/bash", "--login"]

# NAVSIM Docker 环境执行指南

本文档提供了在 Docker 环境中配置、数据准备以及运行 NAVSIM Benchmark 的详细步骤。

## 1. 启动 Docker 环境

在宿主机（Windows）的 `navsim` 项目根目录下运行：

```powershell
# 构建镜像 (已包含 unzip, libgl 等必要依赖)
docker-compose build

# 启动容器
docker-compose up -d
```

## 2. 进入容器并初始化 Python 环境

所有的核心指令都需要在容器内部执行。

```powershell
# 进入容器终端
docker exec -it navsim_env /bin/bash

# 在容器内激活 Conda 环境
source /opt/conda/bin/activate navsim

# 以可编辑模式安装 navsim (只需执行一次)
pip install -e .
```

## 3. 数据准备 (以 mini split 为例)

由于脚本可能存在 Windows 换换行符（CRLF）兼容性问题，建议在容器内手动执行下载和解压。

### 3.1 下载并安装地图 (nuPlan Maps)
```bash
mkdir -p /workspace/dataset
cd /workspace/dataset
wget https://motional-nuplan.s3-ap-northeast-1.amazonaws.com/public/nuplan-v1.1/nuplan-maps-v1.1.zip
unzip nuplan-maps-v1.1.zip
mv nuplan-maps-v1.0 maps
rm nuplan-maps-v1.1.zip
```

### 3.2 下载 Logs 和 Metadata
```bash
cd /workspace/dataset
wget https://huggingface.co/datasets/OpenDriveLab/OpenScene/resolve/main/openscene-v1.1/openscene_metadata_mini.tgz
tar -xzf openscene_metadata_mini.tgz
mkdir -p navsim_logs/mini
mv openscene-v1.1/meta_datas/* navsim_logs/mini/
rm -rf openscene-v1.1 openscene_metadata_mini.tgz
```

### 3.3 下载传感器数据 (Camera Blobs)
注意：传感器数据较大，解压可能需要几分钟。
```bash
cd /workspace/dataset
wget https://huggingface.co/datasets/OpenDriveLab/OpenScene/resolve/main/openscene-v1.1/openscene_sensor_mini_camera/openscene_sensor_mini_camera_0.tgz
tar -xzf openscene_sensor_mini_camera_0.tgz
mkdir -p sensor_blobs/mini
cp -r openscene-v1.1/sensor_blobs/mini/* sensor_blobs/mini/
rm -rf openscene-v1.1 openscene_sensor_mini_camera_0.tgz
```

## 4. 运行评估 (Benchmark)

评估分为两个阶段：计算指标缓存（Metric Caching）和运行 Planner 评分。

### 4.1 计算指标缓存
这是运行评估的前置步骤，针对 `mini` 数据集大约需要 10-15 分钟（取决于 CPU 核心数）。
```bash
cd /workspace/navsim
python navsim/planning/script/run_metric_caching.py 
    train_test_split=mini 
    metric_cache_path=/workspace/exp/metric_cache 
    worker=ray_distributed_no_torch
```

### 4.2 运行评估脚本 (以 CV Agent 为例)
我们使用 `one_stage` 脚本对 `mini` 数据集进行快速验证。
```bash
python navsim/planning/script/run_pdm_score_one_stage.py 
    train_test_split=mini 
    experiment_name=cv_agent 
    metric_cache_path=/workspace/exp/metric_cache 
    worker=ray_distributed_no_torch
```

**预期结果：**
执行完成后，你会看到类似如下的输出：
- `Final average score of valid results: 0.825...`
- 结果文件保存在 `/workspace/exp/cv_agent/日期/文件名.csv`

## 5. 常见问题说明

1.  **脚本换行符错误**：如果在容器内运行 `.sh` 脚本报错 `: command not found`，请执行 `tr -d '' < script.sh > script_fixed.sh` 进行修复。
2.  **内存不足 (OOM)**：Ray 引擎在并行处理时会占用大量内存。如果发生崩溃，请尝试降低并行数或增加 Docker 的资源配额。
3.  **路径环境变量**：容器内已预设以下环境变量，无需手动修改：
    - `NUPLAN_MAPS_ROOT`: `/workspace/dataset/maps`
    - `OPENSCENE_DATA_ROOT`: `/workspace/dataset`
    - `NAVSIM_DEVKIT_ROOT`: `/workspace/navsim`
    - `NAVSIM_EXP_ROOT`: `/workspace/exp`

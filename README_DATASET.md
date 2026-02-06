# NAVSIM 数据集使用说明

NAVSIM 的运行依赖于三类核心数据：**地图 (Maps)**、**日志 (Logs/Metadata)** 和 **传感器数据 (Sensor Blobs)**。

## 1. 数据类型详解

| 数据类型 | 作用描述 | 必备性 |
| :--- | :--- | :--- |
| **nuPlan Maps** | 包含车道线、可行驶区域、交通灯位置等地理信息。用于碰撞检测和规则合规性检查。 | **必备** |
| **OpenScene Logs** | 包含场景的元数据、自车历史状态、周围障碍物的轨迹真值（GT）。 | **必备** |
| **Sensor Blobs** | 包含摄像头图像 (.jpg) 和 LiDAR 点云 (.pcd)。 | **深度学习模型必备** (简单 Planner 可选) |

## 2. 数据分片 (Splits) 介绍

根据你的使用场景，可以选择下载不同的数据分片：

### 2.1 基础分片 (OpenScene Standard)
这些是原始数据，场景连续且未经过滤。
- **`mini`**: 演示版（约 1GB Logs）。包含 64 个日志文件，适合本地代码调试和快速验证流程。
- **`trainval`**: 完整训练集（约 14GB Logs）。规模巨大，用于训练生产级别的模型。
- **`test`**: 测试集（约 1GB Logs）。用于评估模型在常规场景下的性能。

### 2.2 过滤后的分片 (NAVSIM Filtered)
这些分片从原始数据中挑选了“非平庸”的具有挑战性的场景，是学术论文对比的标准。
- **`navtrain`**: 从 `trainval` 中过滤出的训练集。提供了专门的 `download_navtrain` 脚本，仅下载训练所需的传感器帧（约 445GB，远小于原始的 2000GB+）。
- **`navtest`**: NAVSIM v1 的标准测试集。
- **`navhard_two_stage`**: **NAVSIM v2 的标准评估集**。包含真实场景和用于“伪闭环仿真”的合成场景。

### 2.3 比赛分片 (Challenge)
- **`warmup_two_stage`**: 用于在 Hugging Face Leaderboard 上测试提交流程的小型分片。
- **`private_test_hard_two_stage`**: 官方挑战赛的最终测试数据。

## 3. 推荐目录结构

为了确保代码中的环境变量能正确找到数据，请按照以下结构组织（对应容器内的 `/workspace/dataset`）：

```text
/workspace/dataset
├── maps/                       # nuPlan 格式地图
├── navsim_logs/                # Logs (.pkl)
│   ├── mini/
│   ├── trainval/
│   └── navhard_two_stage/
└── sensor_blobs/               # 传感器数据 (.jpg, .pcd)
    ├── mini/
    ├── navtrain/
    └── navhard_two_stage/
```

## 4. 存储空间预警

- **`mini`**: 约 5-10GB (含传感器)。
- **`navtrain`**: 约 445GB。
- **`trainval` 完整版**: 超过 2000GB (2TB+)。
- **`navhard_two_stage`**: 约 31GB。

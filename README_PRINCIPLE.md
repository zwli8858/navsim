# NAVSIM 原理与代码结构详解

NAVSIM (Data-Driven **N**on-Reactive **A**utonomous **V**ehicle **SIM**ulation) 是一个用于自动驾驶端到端模型评估的框架。其核心思想是结合 **开环评估的高效性** 和 **闭环评估的鲁棒性**。

## 1. 核心原理：伪仿真 (Pseudo-Simulation)

传统的开环评估（Open-loop）只看预测轨迹与专家真值的位移误差（L2 Distance），这无法反映碰撞或冲出路面等严重后果。NAVSIM v2 引入了 **两阶段伪闭环评估**：

### 第一阶段：初始评分 (Stage 1 Scoring)
*   **输入**：当前时刻的传感器观测。
*   **操作**：Planner 输出一段 4 秒的轨迹。
*   **仿真**：使用 LQR 控制器控制自车沿预测轨迹行驶，周围环境（车、人）按历史记录运动（非交互式）。
*   **评分**：计算 EPDMS（扩展 PDM 分数）。

### 第二阶段：分布偏移补偿 (Stage 2 Aggregation)
为了模拟闭环中可能出现的“误差累积”：
*   **合成场景**：系统预先生成了多个起始状态稍有偏移（如偏离中心线 1 米或速度快 2m/s）的“后继场景”。
*   **匹配权重**：根据自车在第一阶段结束时的位置，找到最接近的“后继场景”。
*   **加权平均**：使用高斯核函数给不同的后继场景评分分配权重。如果模型在有偏差的初始状态下依然能恢复正常行驶，则得分高。

---

## 2. 评分标准：EPDMS 指标

分数由 **乘法罚分** 和 **加权得分** 组成：

1.  **乘法罚分 (Multipliers)**: 只要一项不合格，总分大幅下降甚至清零。
    *   **NC**: 无责任碰撞。
    *   **DAC**: 可行驶区域合规性（不冲出路面）。
    *   **DDC**: 行驶方向合规性（不逆行）。
    *   **TLC**: 红绿灯合规性。
2.  **加权得分 (Weighted Scores)**: 衡量驾驶质量。
    *   **EP (Ego Progress)**: 效率，跑得够不够快。
    *   **TTC**: 碰撞时间风险。
    *   **LK (Lane Keeping)**: 车道保持。
    *   **Comfort**: 驾驶舒适度（加速度、加速度变化率）。

---

## 3. 代码结构指南

仓库的核心逻辑位于 `navsim/` 目录下：

### `navsim/agents/` (模型定义)
*   `abstract_agent.py`: 所有 Agent 的基类。定义了 `compute_trajectory` 接口。
*   `constant_velocity_agent.py`: 恒定速度基准模型（我们刚才测试的模型）。
*   `transfuser/`: 基于 Transformer 的深度学习模型示例。

### `navsim/evaluate/` (核心评价逻辑)
*   `pdm_score.py`: 实现 EPDMS 指标的数学计算。

### `navsim/planning/` (仿真引擎)
*   `simulation/`: 包含 LQR 控制器、碰撞检测逻辑和简单的交通代理模型。
*   `script/`: 运行入口。
    *   `run_metric_caching.py`: 预计算地图和场景信息（加速评估）。
    *   `run_pdm_score.py`: 完整的两阶段评估脚本。
    *   `run_pdm_score_one_stage.py`: 简化的单阶段评估脚本（适合 mini 数据集调试）。

### `navsim/common/` (基础组件)
*   `dataloader.py`: 处理 OpenScene 日志的加载。
*   `dataclasses.py`: 定义了场景（Scene）、帧（Frame）和传感器配置的数据结构。

---

## 4. 关键接口示例：如何实现自己的 Agent

你只需要继承 `AbstractAgent` 并实现 `compute_trajectory` 方法：

```python
class MyCustomAgent(AbstractAgent):
    def compute_trajectory(self, agent_input):
        # 1. 获取观测数据 (图像、状态等)
        # 2. 运行你的模型推理
        # 3. 返回一个 [num_poses, 3] 的 Numpy 数组 (x, y, heading)
        return trajectory
```

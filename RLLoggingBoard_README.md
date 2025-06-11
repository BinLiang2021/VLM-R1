# RLLoggingBoard 集成说明

本文档说明如何在VLM-R1训练中使用RLLoggingBoard进行可视化分析。

## 概述

我已经将[RLLoggingBoard](https://github.com/HarderThenHarder/RLLoggingBoard)集成到你的GRPO训练流程中。RLLoggingBoard是一个用于RLHF训练过程可视化的工具，可以帮助你：

1. **监控训练过程**：查看每个step的rewards变化、KL散度等指标
2. **分析sample质量**：逐token查看logprobs、rewards分布
3. **调试训练问题**：识别过高KL、异常samples等问题

## 修改的文件

### 1. `VLM-R1/src/open-r1-multimodal/src/open_r1/trainer/grpo_trainer.py`

**添加的功能：**
- 数据收集逻辑：在训练过程中收集prompt、response、logprobs等数据
- 自动保存：将数据保存为RLLoggingBoard需要的.jsonl格式
- 环境变量控制：通过`SAVE_ROLLOUT_DATA`环境变量控制是否收集数据

**收集的数据包括：**
- `prompt`: 输入提示
- `response`: 模型生成的回答
- `response_tokens`: response的token列表
- `logprobs`: 当前policy model的log概率
- `ref_logprobs`: reference model的log概率
- `values`: critic值（GRPO中填充为0）
- `token_rewards`: token级别的rewards（GRPO中填充为0）
- `reward`: 整体reward分数
- `step`: 训练步数

### 2. `VLM-R1/run_scripts/run_grpo_gui.sh`

**添加的配置：**
```bash
export SAVE_ROLLOUT_DATA="true"  # 启用数据收集
```

### 3. `VLM-R1/run_scripts/start_rl_logging_board.sh`

**新增脚本**：自动下载、配置和启动RLLoggingBoard的完整脚本

## 使用方法

### 步骤1：启动训练（收集数据）

```bash
cd VLM-R1/run_scripts
bash run_grpo_gui.sh
```

训练开始后，数据会自动保存到：
```
VLM-R1/checkpoints/rl/GUI-multi-image/rollout_samples/GUI-multi-image/
```

### 步骤2：启动RLLoggingBoard可视化

在另一个终端窗口中：

```bash
cd VLM-R1/run_scripts
bash start_rl_logging_board.sh
```

或者指定自定义实验名称和端口：
```bash
bash start_rl_logging_board.sh GUI-multi-image 8901
```

### 步骤3：访问Web界面

打开浏览器访问：http://localhost:8901

## 配置选项

### 环境变量

- `SAVE_ROLLOUT_DATA`: 设置为"true"启用数据收集，"false"禁用（默认false）
- `EXP_NAME`: 实验名称，用于数据存储路径

### 自定义配置

如果你想修改数据收集的行为，可以编辑 `grpo_trainer.py` 中的相关方法：

1. `_generate_and_score_completions`: 修改数据收集逻辑
2. `compute_loss`: 修改数据保存时机和内容

## 数据格式

保存的数据符合RLLoggingBoard的要求，每行是一个JSON对象：

```json
{
    "prompt": "请编写...",
    "response": "威仪如鹤梦...",
    "response_tokens": ["威", "仪", "如", "鹤", "梦", ...],
    "logprobs": [-4.84, -1.05, -3.17, ...],
    "ref_logprobs": [-4.84, -1.05, -3.17, ...],
    "values": [0.0, 0.0, 0.0, ...],
    "token_rewards": [0.0, 0.0, 0.0, ...],
    "reward": 0.5,
    "step": 100
}
```

## 故障排除

### 1. "数据目录不存在"错误

**原因**：训练还没有开始或者EXP_NAME不匹配
**解决**：确保训练已经运行并生成了数据文件

### 2. "Processor没有convert_ids_to_tokens属性"错误

**解决**：这个问题已经修复，代码会自动使用tokenizer.convert_ids_to_tokens

### 3. 数据没有收集

**检查**：
1. 确认`SAVE_ROLLOUT_DATA="true"`已设置
2. 检查训练日志中是否有"RLLoggingBoard: Saving rollout data to ..."信息
3. 检查数据目录是否有.jsonl文件生成

### 4. Web界面无法访问

**检查**：
1. 确认端口没有被占用
2. 检查防火墙设置
3. 尝试使用其他端口：`bash start_rl_logging_board.sh GUI-multi-image 8902`

## 性能影响

- 数据收集会轻微增加内存使用和I/O开销
- 如果不需要可视化，可以设置`SAVE_ROLLOUT_DATA="false"`来禁用
- 数据会按进程分别保存，RLLoggingBoard会自动合并显示

## 下一步

1. 运行训练收集数据
2. 启动RLLoggingBoard查看可视化结果
3. 根据可视化结果调整训练参数，如：
   - KL系数（beta）
   - 奖励函数权重
   - 学习率等

有任何问题请参考[RLLoggingBoard官方文档](https://github.com/HarderThenHarder/RLLoggingBoard)或检查训练日志中的错误信息。 
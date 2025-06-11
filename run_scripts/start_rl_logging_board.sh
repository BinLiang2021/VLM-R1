#!/bin/bash

# RLLoggingBoard启动脚本
# 使用方法: ./start_rl_logging_board.sh [实验名称] [端口号]

PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
REPO_HOME="${PROJECT_ROOT}"

# 默认参数
EXP_NAME=${1:-"GUI-multi-image"}
PORT=${2:-8901}

# RLLoggingBoard存储位置
CHECKPOINTS_DIR="${REPO_HOME}/checkpoints/rl/${EXP_NAME}"
ROLLOUT_DATA_DIR="${CHECKPOINTS_DIR}/rollout_samples/${EXP_NAME}"

echo "启动RLLoggingBoard可视化工具..."
echo "实验名称: ${EXP_NAME}"
echo "数据目录: ${ROLLOUT_DATA_DIR}"
echo "端口: ${PORT}"

# 检查数据目录是否存在
if [ ! -d "${ROLLOUT_DATA_DIR}" ]; then
    echo "警告: 数据目录不存在: ${ROLLOUT_DATA_DIR}"
    echo "请确保已运行训练并生成了rollout数据"
    echo "或者检查EXP_NAME是否正确"
    exit 1
fi

# 检查是否有数据文件
if [ -z "$(ls -A ${ROLLOUT_DATA_DIR}/*.jsonl 2>/dev/null)" ]; then
    echo "警告: 在 ${ROLLOUT_DATA_DIR} 中没有找到.jsonl文件"
    echo "请确保训练已经开始并生成了数据"
    exit 1
fi

# 下载并设置RLLoggingBoard
RLLOGGING_DIR="${REPO_HOME}/RLLoggingBoard"

if [ ! -d "${RLLOGGING_DIR}" ]; then
    echo "下载RLLoggingBoard..."
    cd "${REPO_HOME}"
    git clone https://github.com/HarderThenHarder/RLLoggingBoard.git
    cd RLLoggingBoard
    
    # 安装依赖
    echo "安装RLLoggingBoard依赖..."
    pip install -r requirments.txt
else
    cd "${RLLOGGING_DIR}"
fi

# 创建软链接，将rollout数据链接到RLLoggingBoard的期望位置
mkdir -p rollout_samples
if [ ! -L "rollout_samples/${EXP_NAME}" ]; then
    ln -sf "${ROLLOUT_DATA_DIR}" "rollout_samples/${EXP_NAME}"
    echo "已创建数据链接: rollout_samples/${EXP_NAME} -> ${ROLLOUT_DATA_DIR}"
fi

# 启动RLLoggingBoard
echo "启动RLLoggingBoard web界面在端口 ${PORT}..."
echo "访问地址: http://localhost:${PORT}"
echo "按Ctrl+C停止服务"

streamlit run rl_logging_board.py --server.port ${PORT} 
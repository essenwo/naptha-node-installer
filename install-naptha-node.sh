#!/bin/bash

# Naptha 安装目录
NAPTHA_DIR="$HOME/naptha-node"

# 安装必要的系统包
setup_system_requirements() {
    echo "正在安装必要的系统包..."
    sudo apt update
    sudo apt install -y curl git python3-venv
}

# 安装 Docker 和 Docker Compose
setup_docker() {
    echo "正在检查并安装 Docker 和 Docker Compose..."
    if ! command -v docker &> /dev/null; then
        echo "安装 Docker..."
        curl -fsSL https://get.docker.com | sudo bash
        sudo systemctl enable docker
        sudo systemctl start docker
    fi
    if ! command -v docker-compose &> /dev/null; then
        echo "安装 Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    fi
    echo "Docker 和 Docker Compose 已准备好。"
}

# 设置 Python 虚拟环境
configure_python_env() {
    echo "正在配置 Python 虚拟环境..."
    if [ ! -d "$NAPTHA_DIR/.venv" ]; then
        python3 -m venv "$NAPTHA_DIR/.venv"
    fi
    source "$NAPTHA_DIR/.venv/bin/activate"
    pip install --upgrade pip
    pip install docker requests
    echo "Python 虚拟环境配置完成。"
}

# 克隆 Naptha 仓库
download_naptha() {
    echo "正在下载 Naptha 节点代码..."
    if [ ! -d "$NAPTHA_DIR" ]; then
        git clone https://github.com/NapthaAI/naptha-node.git "$NAPTHA_DIR"
    fi
    cd "$NAPTHA_DIR" || { echo "无法切换到 Naptha 目录，退出！"; exit 1; }
}

# 配置环境变量
setup_naptha_config() {
    echo "正在配置 Naptha 环境变量..."
    if [ -f ".env.example" ]; then
        cp .env.example .env
    else
        echo "未找到 .env.example 文件，创建默认配置文件..."
        cat > .env <<EOF
LAUNCH_DOCKER=true
LLM_BACKEND=ollama
youruser=root
EOF
    fi
    # 确保必要变量存在
    sed -i 's/^LAUNCH_DOCKER=.*/LAUNCH_DOCKER=true/' .env 2>/dev/null || echo "LAUNCH_DOCKER=true" >> .env
    sed -i 's/^LLM_BACKEND=.*/LLM_BACKEND=ollama/' .env 2>/dev/null || echo "LLM_BACKEND=ollama" >> .env
    sed -i 's/^youruser=.*/youruser=root/' .env 2>/dev/null || echo "youruser=root" >> .env
    echo "Naptha 环境变量配置完成。"
}

# 启动 Naptha 节点
start_naptha() {
    echo "正在启动 Naptha 节点..."
    if [ -f "launch.sh" ]; then
        bash launch.sh
        echo "Naptha 节点已启动！访问地址：http://$(hostname -I | awk '{print $1}'):7001"
    else
        echo "未找到 launch.sh 脚本，启动失败！"
        exit 1
    fi
}

# 查看 Naptha 日志
view_naptha_logs() {
    echo "正在查看 Naptha 节点日志（最后 200 行）..."
    docker-compose logs --tail=200
}

# 主部署流程
deploy_naptha_node() {
    echo "开始部署 Naptha 节点..."
    setup_system_requirements
    setup_docker
    download_naptha
    configure_python_env
    setup_naptha_config
    start_naptha
    view_naptha_logs
}

# 执行部署
deploy_naptha_node

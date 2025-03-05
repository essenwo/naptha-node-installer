#!/bin/bash

# Naptha 节点一键部署脚本
# Naptha 安装目录
INSTALL_PATH="$HOME/naptha-node"

# 安装系统依赖
install_system_dependencies() {
    echo "安装系统依赖..."
    sudo apt update
    sudo apt install -y curl git python3-venv
}

# 检查并安装 Python 依赖
prepare_python_env() {
    echo "检查并安装 Python 依赖..."
    if [ ! -d "$INSTALL_PATH/.venv" ]; then
        python3 -m venv "$INSTALL_PATH/.venv"
    fi
    source "$INSTALL_PATH/.venv/bin/activate"
    pip install --upgrade pip
    pip install docker requests
    echo "Python 依赖安装完成。"
}

# 检查 Docker 是否可用
verify_docker() {
    echo "检查 Docker 是否已安装..."
    if ! command -v docker &> /dev/null; then
        echo "未找到 Docker，正在安装..."
        curl -fsSL https://get.docker.com | bash
        sudo systemctl start docker
        sudo systemctl enable docker
    fi
    echo "Docker 已安装，版本：$(docker --version)"
}

# 检查并安装 Docker Compose
verify_compose() {
    echo "检查 Docker Compose 是否可用..."
    if ! docker compose version &> /dev/null; then
        echo "未找到 Docker Compose，正在安装 Docker Compose 插件..."
        sudo apt update
        sudo apt install -y docker-compose-plugin
        if ! docker compose version &> /dev/null; then
            echo "Docker Compose 插件安装失败，尝试安装独立版本..."
            sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
        fi
    fi
    echo "Docker Compose 已准备好，版本：$(docker compose version || docker-compose --version)"
}

# 下载 Naptha 仓库
fetch_naptha_code() {
    echo "下载 Naptha 节点代码..."
    if [ ! -d "$INSTALL_PATH" ]; then
        git clone https://github.com/NapthaAI/naptha-node.git "$INSTALL_PATH"
    else
        echo "Naptha 代码已存在，跳过下载。"
    fi
    cd "$INSTALL_PATH" || { echo "无法进入 Naptha 目录，退出！"; exit 1; }
}

# 设置环境变量
configure_env() {
    echo "设置环境变量..."
    if [ -f ".env.example" ]; then
        cp .env.example .env
        sed -i 's/^LAUNCH_DOCKER=.*/LAUNCH_DOCKER=true/' .env
        sed -i 's/^LLM_BACKEND=.*/LLM_BACKEND=ollama/' .env
        # 设置默认用户
        if ! grep -q "^youruser=" .env; then
            echo "youruser=root" >> .env
        fi
        echo "环境变量设置完成。"
    else
        echo "未找到 .env.example 文件，请检查 Naptha 仓库！"
        exit 1
    fi
}

# 启动 Naptha 服务
launch_naptha() {
    echo "启动 Naptha 节点..."
    if [ -f "launch.sh" ]; then
        bash launch.sh
        echo "Naptha 节点启动完成！"
        echo "请访问以下地址查看状态：http://$(hostname -I | awk '{print $1}'):7001"
    else
        echo "未找到 launch.sh 脚本，请检查 Naptha 仓库！"
        exit 1
    fi
}

# 显示日志
display_logs() {
    echo "显示 Naptha 节点日志（最后 200 行）..."
    if command -v docker-compose &> /dev/null; then
        docker-compose logs --tail=200
    else
        docker compose logs --tail=200
    fi
}

# 主函数
deploy_naptha() {
    echo "欢迎使用 Naptha 节点一键部署脚本！"
    echo "作者：Grok 3 (xAI)"

    # 安装系统依赖
    install_system_dependencies

    # 检查 Docker 和 Compose
    verify_docker
    verify_compose

    # 下载 Naptha 代码
    fetch_naptha_code

    # 安装 Python 依赖
    prepare_python_env

    # 设置环境变量
    configure_env

    # 启动 Naptha 服务
    launch_naptha

    # 显示日志
    display_logs
}

# 执行部署
deploy_naptha

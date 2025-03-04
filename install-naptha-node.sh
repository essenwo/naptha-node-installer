#!/bin/bash

# Naptha 节点一键部署脚本
# 功能：安装 Docker，克隆 Naptha 仓库，配置环境并启动节点
# 作者：Grok 3 (xAI)
# 日期：2025-03-05

# Naptha 安装目录
INSTALL_PATH="$HOME/naptha-node"

# 检查 Docker 是否可用
verify_docker() {
    echo "检查 Docker 是否已安装..."
    if ! command -v docker &> /dev/null; then
        echo "未找到 Docker，正在安装..."
        if [[ -f /etc/os-release ]]; then
            . /etc/os-release
            if [[ "$ID" == "Ubuntu" || "$ID" == "debian" ]]; then
                sudo apt update
                sudo apt install -y curl
                curl -fsSL https://get.docker.com | bash
                sudo systemctl start docker
                sudo systemctl enable docker
            else
                echo "不支持的操作系统，请手动安装 Docker！"
                exit 1
            fi
        else
            echo "无法检测操作系统，请手动安装 Docker！"
            exit 1
        fi
    fi
    echo "Docker 已安装，版本：$(docker --version)"
}

# 检查 Docker Compose 是否可用
verify_compose() {
    echo "检查 Docker Compose 是否可用..."
    if ! docker compose version &> /dev/null; then
        echo "未找到 Docker Compose，请确保 Docker 版本支持 compose 插件！"
        exit 1
    fi
    echo "Docker Compose 已准备好，版本：$(docker compose version)"
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
        sed -i 's/^LOCAL_DB_URL=.*/LOCAL_DB_URL=postgresql:\/\/postgres:postgres@postgres:5432\/naptha_db/' .env
        # 如果 LOCAL_DB_URL 不存在，则追加
        if ! grep -q "^LOCAL_DB_URL=" .env; then
            echo "LOCAL_DB_URL=postgresql://postgres:postgres@postgres:5432/naptha_db" >> .env
        fi
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

# 确保 docker-compose.yml 包含 PostgreSQL 服务
setup_docker_compose() {
    echo "检查并设置 docker-compose.yml..."
    if [ -f "docker-compose.yml" ]; then
        # 检查是否包含 postgres 服务
        if ! grep -q "postgres:" docker-compose.yml; then
            echo "docker-compose.yml 中缺少 postgres 服务，添加中..."
            cat > docker-compose.yml <<EOF
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: naptha_db
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped
  nodeapp:
    image: naptha/node:latest
    env_file:
      - .env
    ports:
      - "7001:7001"
    depends_on:
      - postgres
    restart: unless-stopped
volumes:
  postgres_data:
EOF
        fi
    else
        echo "未找到 docker-compose.yml，创建默认配置..."
        cat > docker-compose.yml <<EOF
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: naptha_db
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped
  nodeapp:
    image: naptha/node:latest
    env_file:
      - .env
    ports:
      - "7001:7001"
    depends_on:
      - postgres
    restart: unless-stopped
volumes:
  postgres_data:
EOF
    fi
    echo "docker-compose.yml 已准备好。"
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
    docker compose logs --tail=200
}

# 主函数
deploy_naptha() {
    echo "欢迎使用 Naptha 节点一键部署脚本！"
    echo "作者：Grok 3 (xAI)"

    # 检查 Docker 和 Compose
    verify_docker
    verify_compose

    # 下载 Naptha 代码
    fetch_naptha_code

    # 设置环境变量
    configure_env

    # 设置 docker-compose.yml
    setup_docker_compose

    # 启动 Naptha 服务
    launch_naptha

    # 显示日志
    display_logs
}

# 执行部署
deploy_naptha

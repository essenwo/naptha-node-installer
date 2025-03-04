#!/bin/bash

# 一键安装 Naptha 节点的脚本
# 功能：自动安装 Docker（如果未安装），生成私钥，创建配置文件，启动 Naptha 节点和 PostgreSQL 服务
# 作者：Grok 3 (xAI)
# 日期：2025-03-05

# 设置工作目录
WORK_DIR="$HOME/naptha-node"
echo "正在创建工作目录: $WORK_DIR"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR" || { echo "无法进入工作目录，退出！"; exit 1; }

# 检查端口是否被占用
check_port() {
    PORT=8080
    if netstat -tuln | grep ":$PORT " > /dev/null; then
        echo "错误：端口 $PORT 已被占用！"
        echo "请释放端口，或者编辑 $WORK_DIR/docker-compose.yml 文件更改端口（默认为 8080）。"
        exit 1
    else
        echo "端口 $PORT 可用"
    fi
}

# 检查 Docker 是否已安装
check_docker() {
    echo "正在检查 Docker..."
    if ! command -v docker &> /dev/null; then
        echo "未找到 Docker，尝试安装..."
        # 检测操作系统并安装 Docker
        if [[ -f /etc/os-release ]]; then
            . /etc/os-release
            OS=$ID
            if [[ "$OS" == "Ubuntu" || "$OS" == "debian" ]]; then
                sudo apt update
                sudo apt install -y docker.io
                sudo systemctl start docker
                sudo systemctl enable docker
            else
                echo "不支持的操作系统，请手动安装 Docker。"
                echo "Ubuntu/Debian: sudo apt install docker.io"
                echo "macOS: 下载 Docker Desktop (https://docs.docker.com/desktop/install/mac-install/)"
                echo "Windows: 下载 Docker Desktop (https://docs.docker.com/desktop/install/windows-install/)"
                exit 1
            fi
        else
            echo "无法检测操作系统，请手动安装 Docker：https://docs.docker.com/get-docker/"
            exit 1
        fi
    else
        echo "Docker 已安装，版本：$(docker --version)"
    fi
}

# 检查 docker-compose 是否可用（现代 Docker 已内置）
check_docker_compose() {
    echo "正在检查 docker compose..."
    if ! docker compose version &> /dev/null; then
        echo "docker compose 未找到，请确保 Docker 版本支持 compose 插件（Docker 19.03+）"
        exit 1
    else
        echo "docker compose 已准备好，版本：$(docker compose version)"
    fi
}

# 生成新的私钥
generate_private_key() {
    echo "正在生成新的私钥..."
    if ! command -v openssl &> /dev/null; then
        echo "未找到 openssl，尝试安装..."
        if [[ -f /etc/os-release ]]; then
            . /etc/os-release
            OS=$ID
            if [[ "$OS" == "Ubuntu" || "$OS" == "debian" ]]; then
                sudo apt install -y openssl
            else
                echo "不支持的操作系统，请手动安装 openssl"
                exit 1
            fi
        else
            echo "无法检测操作系统，请手动安装 openssl"
            exit 1
        fi
    fi
    PRIVATE_KEY=$(openssl rand -hex 32)
    echo "生成的新私钥：$PRIVATE_KEY"
}

# 提示用户输入用户名和密码
prompt_user_credentials() {
    echo "正在设置用户凭据..."
    read -p "请输入用户名（例如：myusername）： " USERNAME
    if [[ -z "$USERNAME" ]]; then
        echo "用户名不能为空！"
        exit 1
    fi

    read -p "请输入密码（例如：mypassword123）： " PASSWORD
    if [[ -z "$PASSWORD" ]]; then
        echo "密码不能为空！"
        exit 1
    fi
}

# 创建 .env 文件
create_env_file() {
    echo "正在创建 .env 文件..."
    cat > .env <<EOF
# Naptha 节点配置文件
PRIVATE_KEY=$PRIVATE_KEY
USERNAME=$USERNAME
PASSWORD=$PASSWORD
LAUNCH_DOCKER=True
GPU=False
USE_GRPC=True
MODEL=NousResearch/Hermes-3-LLaMA3-8B
LOCAL_DB_URL=postgresql://postgres:postgres@postgres:5432/naptha_db
EOF
    echo ".env 文件已创建"
}

# 创建 docker-compose.yml 文件
create_docker_compose_file() {
    echo "正在创建 docker-compose.yml 文件..."
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
  naptha-node:
    image: naptha/node:latest
    env_file:
      - .env
    volumes:
      - ./data:/app/data
    ports:
      - "8080:8080"
    depends_on:
      - postgres
    restart: unless-stopped
volumes:
  postgres_data:
EOF
    echo "docker-compose.yml 文件已创建"
}

# 主函数：执行安装流程
main() {
    echo "=== 欢迎使用 Naptha 节点一键安装脚本 ==="
    echo "脚本将自动完成以下操作："
    echo "1. 检查并安装 Docker（如果未安装）"
    echo "2. 生成一个新的私钥"
    echo "3. 提示输入用户名和密码"
    echo "4. 创建配置文件并启动 Naptha 节点及 PostgreSQL 服务"
    echo ""

    # 步骤 1：检查端口
    check_port

    # 步骤 2：检查 Docker
    check_docker
    check_docker_compose

    # 步骤 3：生成私钥
    generate_private_key

    # 步骤 4：提示用户输入用户名和密码
    prompt_user_credentials

    # 步骤 5：创建配置文件
    create_env_file
    create_docker_compose_file

    # 步骤 6：启动节点
    echo "正在启动 Naptha 节点和 PostgreSQL 服务..."
    docker compose up -d
    if [[ $? -eq 0 ]]; then
        echo "Naptha 节点已启动！"
        echo "你可以通过以下命令查看日志："
        echo "  cd $WORK_DIR && docker compose logs"
        echo "访问 http://localhost:8080 查看节点状态"
        echo "如果无法访问，请检查日志，或者确保 8080 端口已开放（例如：ufw allow 8080）"
    else
        echo "启动失败，请检查错误信息！"
        echo "可能的原因："
        echo "- 网络连接问题（无法拉取 Docker 镜像或克隆 Git 仓库）"
        echo "- Docker 服务未启动（尝试运行 'sudo systemctl start docker'）"
        echo "- 配置文件错误（检查 $WORK_DIR/.env 和 $WORK_DIR/docker-compose.yml）"
        echo "- PostgreSQL 服务未正常启动（检查日志：docker compose logs postgres）"
        exit 1
    fi
}

# 执行主函数
main

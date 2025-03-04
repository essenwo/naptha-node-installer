# Naptha 节点一键安装脚本

这是一个用于在 Docker 中快速部署 Naptha 节点的一键安装脚本。运行脚本后，它会自动：

1. 检查并安装 Docker（如果未安装）。
2. 生成一个新的私钥。
3. 提示你输入用户名和密码。
4. 创建必要的配置文件。
5. 在 Docker 中启动 Naptha 节点。

## 前提条件

- 操作系统：推荐使用 Ubuntu/Debian（脚本支持自动安装 Docker）。对于 macOS/Windows，请先手动安装 Docker。
- 必须有 `openssl` 工具（脚本会尝试自动安装）。
- 需要联网以拉取 Docker 镜像。

## 使用方法

### 方式 1：直接下载并运行
1. 下载脚本：
   wget https://raw.githubusercontent.com/essenwo/naptha-node-installer/main/install-naptha-node.sh
   chmod +x install-naptha-node.sh
   ./install-naptha-node.sh

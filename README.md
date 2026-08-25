# mmw-agent Docker 镜像

本仓库基于官方 mmw-agent 容器运行环境，自动打包
[`mmwx-group/mmwx-agent`](https://github.com/mmwx-group/mmwx-agent) 发布的已签名版本。

GitHub Actions 每小时检查一次上游版本。发现新版本后会依次：

1. 下载 Linux amd64、arm64 的 Agent 二进制文件和签名清单。
2. 校验所有 SHA-256 摘要，以及签名清单与二进制文件的绑定关系。
3. 构建两个架构的镜像，并在原生 amd64 Runner 上执行 Guard 启动测试。
4. 所有检查通过后，才将多架构镜像发布到 GHCR。

## 镜像地址

```text
ghcr.io/menzhu/mmw-agent-docker:latest
```

每个版本还会同时发布带 `v` 和不带 `v` 的标签，例如 `v0.6.8` 和 `0.6.8`。

## 使用方法

### 升级已有部署

本镜像可以直接替换官方容器镜像。已有部署中的环境变量、挂载目录、网络模式和其他服务配置都应保持不变，只修改镜像地址：

```yaml
services:
  mmw-agent:
    image: ghcr.io/menzhu/mmw-agent-docker:latest
```

然后只拉取并重建 Agent 服务：

```bash
docker compose pull mmw-agent
docker compose up -d --no-deps mmw-agent
```

不要用上面的简短片段覆盖已有的完整 Compose 服务配置。尤其需要保留主控下发的 Token、公钥、网络模式覆盖参数，以及服务器已有的挂载目录。

### 全新部署

先创建 `.env` 文件，填写 miaomiaowux 主控生成的参数：

```dotenv
MMWX_MASTER_URL=https://master.example.com
MMWX_MASTER_TOKEN=replace-with-the-server-token
MMWX_MASTER_PUBLIC_KEY=replace-with-the-master-public-key
MMWX_LISTEN_PORT=23889
```

`.env` 包含敏感信息，不要提交到 Git 仓库。完整的 Compose 配置如下：

```yaml
services:
  mmw-agent:
    image: ghcr.io/menzhu/mmw-agent-docker:latest
    container_name: mmw-agent
    restart: unless-stopped
    network_mode: host

    environment:
      MMWX_LISTEN_PORT: "${MMWX_LISTEN_PORT:-23889}"
      MMWX_MASTER_URL: "${MMWX_MASTER_URL:?请在 .env 中设置 MMWX_MASTER_URL}"
      MMWX_MASTER_TOKEN: "${MMWX_MASTER_TOKEN:?请在 .env 中设置 MMWX_MASTER_TOKEN}"
      MMWX_TOKEN: "${MMWX_MASTER_TOKEN:?请在 .env 中设置 MMWX_MASTER_TOKEN}"
      MMWX_MASTER_PUBLIC_KEY: "${MMWX_MASTER_PUBLIC_KEY:?请在 .env 中设置 MMWX_MASTER_PUBLIC_KEY}"
      MMWX_XRAY_MODE: embedded
      DOCKER: "1"

    volumes:
      - ./config:/etc/mmw-agent
      - ./xray-config:/usr/local/etc/xray
      - ./nginx-cert:/etc/nginx/cert
      - ./nginx-servers:/etc/nginx/servers
      - mmwx-guard:/var/lib/mmwx-guard

volumes:
  mmwx-guard:
```

全新的 Docker 部署必须使用 host 网络，因为 Xray 入站端口会由主控动态创建。如果已有部署有意使用 bridge 网络，并设置了 `MMWX_REQUIRE_HOST_NETWORK=0`，升级镜像时应保留原有网络配置。

需要控制升级节奏时，建议使用 `v0.6.8` 之类的固定版本标签，而不是 `latest`。发布新的 `latest` 镜像不会自动重启已有容器，仍需手动拉取镜像并更新 Compose 服务。

## 可信机制

基础镜像使用固定 digest。Agent 二进制文件和签名清单均来自上游 GitHub Release，Guard 则继承自固定版本的官方基础镜像。构建前会校验两个架构的清单；如果 amd64 版本无法通过原生 Guard 启动测试，也不会发布镜像。

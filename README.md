# 📷 EXIF Photo Blog (NAS 专用优化版)

这是一个专为 NAS (群晖、威联通、UNRAID 等) 环境优化的 EXIF 照片博客。基于 [sambecker/exif-photo-blog](https://github.com/sambecker/exif-photo-blog) 深度定制，解决了自建环境下最棘手的存储、网络及构建配置问题。

---

## ✨ 核心特性

- **EXIF 自动提取**：上传照片自动读取相机型号、镜头、焦段、光圈、ISO、胶片模拟等信息。
- **MinIO 深度集成**：完全脱离 Vercel，支持本地/私有云存储。
- **NAS 性能优化**：针对低功耗 CPU 优化，停用昂贵的实时图片压缩，改用更高效的加载模式。
- **全中文支持**：默认支持中文界面及本地化日期显示。
- **Docker 一键部署**：预设所有依赖，无需配置 Node.js 环境。

---

## 🚀 快速开始

### 1. 准备环境

确保你的 NAS 已安装 **Docker** 和 **Docker Compose**。

### 2. 获取代码与配置变量

1. 克隆或下载本仓库到你 NAS 的某个目录。
2. 复制环境变量文件示例：
   ```bash
   cp .env.example .env.local
   # 关键步骤：Docker Compose 需要读取 .env 文件进行变量替换
   cp .env.local .env
   ```
3. 编辑 `.env.local` 文件，重点修改以下内容：
   - `AUTH_SECRET`: 使用 `openssl rand -base64 32` 生成一个随机字符串。
   - `NEXT_PUBLIC_DOMAIN`: 你的 NAS 访问地址（例如 `192.168.1.100:3000`）。
   - `NEXT_PUBLIC_STORAGE_PREFERENCE`: 设置为 `minio`。
   - **MinIO 账号密码**：务必修改 `MINIO_ACCESS_KEY` 和 `MINIO_SECRET_ACCESS_KEY`。

### 3. 一键启动

在代码根目录下运行：

```bash
docker compose up -d --build
```

启动完成后，访问 `http://NAS-IP:3000` 即可看到你的博客。进入 `http://NAS-IP:3000/admin` 进行登录。

---

## 🛠️ 存储桶权限配置 (关键步!)

为了让浏览器能正常查看图片，必须将 MinIO 的 `photos` 桶设置为**公开读取**。

在终端执行以下命令（假设你的 MinIO 管理账号是 `admin`，密码是 `password123`）：

```bash
# 1. 配置内部别名
docker exec -it photo-blog-minio mc alias set myminio http://localhost:9000 admin password123

# 2. 设置权限为可下载
docker exec -it photo-blog-minio mc policy set download myminio/photos
```

---

## ⚠️ 常见问题与解决方案 (NAS 避坑指南)

### 1. 报错 "Vercel Blob: No token found"

**问题现象**：虽然配置了 MinIO，但上传时程序依然尝试访问 Vercel 存储。
**原因**：Next.js 为了性能，会在「构建时」把以 `NEXT_PUBLIC_` 开头的变量烧录进前端。普通的 Docker 运行时注入对它无效。
**解决方案**：

- 本版本修改了 `Dockerfile` 和 `docker-compose.yml`。
- 在构建时通过 `args` 强行将你的环境变量注入进编译过程。因此，修改配置后请务必执行 `docker compose build --no-cache`。

### 2. 图片显示报错 "upstream image ... resolved to private ip"

**问题现象**：图片上传成功，但大图和缩略图显示为破损，日志显示禁止访问内网 IP。
**原因**：Next.js 的图片优化组件出于安全考虑，默认拒绝从内网私有 IP（如 192.168.x.x）抓取图片。
**解决方案**：

- 修改了 `next.config.ts`，开启了 `unoptimized: true`。
- 这不仅解决了内网 IP 被屏蔽的问题，还大幅降低了 NAS 在生成缩略图时的 CPU 消耗。

### 3. MinIO 账号密码无效

**问题现象**：Docker Compose 启动后，MinIO 始终使用默认的 `admin/password123`，而不是你的自定义配置。
**原因**：Docker Compose 的 `${VAR}` 语法默认只读取 `.env` 文件，而不识别系统的 `.env.local`。
**解决方案**：在本仓库中，必须确保存在镜像自 `.env.local` 的 `.env` 文件。

### 4. 无法获取 Access Key / Secret Key

**问题现象**：启动时报错 `Missing credentials`。
**原因**：Next.js 的 MinIO 客户端需要这些变量存在于服务端环境。
**解决方案**：通过 Docker Compose 的 `env_file` 指令，我们将整个 `.env.local` 注入到了容器内部，确保后端 API 可以随时读取。

---

## 📝 备注与鸣谢

本项目是基于优秀的开源项目 **[exif-photo-blog](https://github.com/sambecker/exif-photo-blog)** 改造而来的。

**主要改动点：**

- 移除了对 Vercel 平台的强依赖。
- 增加了 Docker 构建时的参数透传逻辑。
- 适配了 NAS 自建环境下的图片加载安全策略。
- 优化了本地自建环境下的文件系统兼容性。

如果你觉得这个 NAS 专用版对你有帮助，欢迎给原作者和本分支点个 Star！

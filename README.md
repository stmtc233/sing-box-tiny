# sing-box tiny 自动化编译发布

[![Build and Release sing-box tiny](https://github.com/stmtc233/sing-box-tiny/actions/workflows/build.yml/badge.svg)](https://github.com/stmtc233/sing-box-tiny/actions/workflows/build.yml)
[![GitHub release](https://img.shields.io/github/v/release/stmtc233/sing-box-tiny?include_prereleases&color=blue)](https://github.com/stmtc233/sing-box-tiny/releases)
[![License](https://img.shields.io/badge/License-GPL--3.0-green.svg)](https://github.com/SagerNet/sing-box/blob/main/LICENSE)

自动追踪上游 [SagerNet/sing-box](https://github.com/SagerNet/sing-box) 最新稳定版本发布，针对 OpenWrt / ImmortalWrt 路由器环境自动化编译并打包 **Tiny (精简变体)** 安装包。

同时提供 **`.ipk`** (传统 opkg) 和 **`.apk`** (现代 apk-tools) 两种格式，全覆盖 OpenWrt 23.05 及 24.10 / 25.12+ 架构。

---

## 💡 为什么需要 Tiny 版本？

官方直接发布的通用 Linux 预编译二进制包含全部特性（包括 ACME 证书生成、嵌入式 Tor、Tailscale 协议栈、各种远程 API），解压体积通常超过 **35MB ~ 45MB**，在绝大多数闪存受限的路由器（如 16MB/32MB/128MB SPI NOR/NAND Flash）上极易导致空间占满甚至固件崩溃。

**`sing-box-tiny` 的优势：**
* **精准裁剪**：剔除极小众且体积庞大的非核心组件（ACME、Embedded Tor、Tailscale、CCM、OCM 等）。
* **核心全保**：保留完整的现代代理协议与网络特性：
  - 核心传输：`with_quic`（Hysteria、Hysteria2、TUIC）
  - 伪装握手：`with_utls`（uTLS 客户端指纹）
  - 虚拟网卡：`with_gvisor`（TUN 模式与网络透明代理栈）
  - 常用接口：`with_clash_api`（兼容各种 LuCI 界面及 Clash 控制器）
  - 协议支持：`with_wireguard`、Shadowsocks、ShadowTLS、Trojan、VLess (含 Reality 客户端)、VMess、SOCKS、HTTP
* **开箱即用**：内置标准 OpenWrt 系统服务守护脚本 (`/etc/init.d/sing-box`) 及 UCI 配置文件 (`/etc/config/sing-box`)。
* **体积减半**：安装包压缩体积仅约 **14MB**，大幅减轻 `/overlay` 存储压力。

---

## 📱 支持的 CPU 架构

| 架构标识 (`<arch>`) | 常见芯片与代表机型 | Go 架构目标 |
| :--- | :--- | :--- |
| `x86_64` | 软路由 / 虚拟机 / PVE / ESXi / Intel & AMD 平台 | `linux/amd64` |
| `aarch64_cortex-a53` | MT7981 / MT7986 (红米 AX6000 / 360T7 / CLX S20P 等) | `linux/arm64` |
| `aarch64_generic` | 通用 ARM64 (RK3399 / RK3568 / 树莓派 3/4/5 等) | `linux/arm64` |
| `arm_cortex-a7_neon-vfpv4` | 32 位 ARM (IPQ4019 / IPQ806x / BCM2709 等) | `linux/armv7` |
| `mipsel_24kc` | 联发科 MT7621 (斐讯 K2P / 红米 AC2100 / Newifi D2 等) | `linux/mipsle` (softfloat) |
| `mips_24kc` | 高通 Atheros / QCA9563 / AR9344 等 MIPS 平台 | `linux/mips` (softfloat) |

---

## 🚀 安装方法

前往本仓库的 [Releases](https://github.com/stmtc233/sing-box-tiny/releases) 页面，下载对应架构的安装包并上传至路由器的 `/tmp/` 目录：

### 1. OpenWrt 24.10 / 25.12+ (APK 格式)

```bash
# 进入临时目录
cd /tmp

# 安装（允许未自签名证书的包）
apk add --allow-untrusted ./sing-box-tiny_*.apk

# 验证安装
sing-box version
```

### 2. OpenWrt 23.05 及更旧版本 (IPK 格式)

```bash
# 进入临时目录
cd /tmp

# 安装
opkg update
opkg install ./sing-box-tiny_*.ipk

# 验证安装
sing-box version
```

---

## ⚙️ 服务管理

安装完成后已自动集成 Procd 守护进程：

```bash
# 启动服务
/etc/init.d/sing-box start

# 设置开机自启
/etc/init.d/sing-box enable

# 检查运行状态
/etc/init.d/sing-box status
```

---

## 🔄 自动化更新机制

* 仓库通过 **GitHub Actions** 每天定时（UTC 03:00 / 北京时间 11:00）请求 GitHub API 检查 `SagerNet/sing-box` 的最新 Release。
* 一旦发现官方上游有新的正式版本发布，且当前仓库未发布对应 Release，将全自动触发云端交叉编译、打包所有架构的 `.ipk` 与 `.apk`，并在数分钟内自动发布到 Release 页面。

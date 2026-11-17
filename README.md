# GFWList2AGH

[![License](https://img.shields.io/badge/License-Apache%202.0--Commons%20Clause-blue)](LICENSE)
[![Python](https://img.shields.io/badge/Python-3776AB?logo=python&logoColor=white)](https://www.python.org/)

GFWList2AGH 从 GFWList、Loyalsoldier、felixonmars 等多个来源收集域名列表，转换为 AdGuard Home、Bind9、DNSMasq、SmartDNS、Unbound 等 DNS 服务器配置；Python 3.9+ 标准库实现，GitHub Actions 每日更新。开发规范见 [AGENTS.md](AGENTS.md)。

## 特性

- **每日自动更新**：通过 GitHub Actions 每天自动构建和发布
- **多数据源支持**：整合来自 GFWList、Loyalsoldier、felixonmars 等多个权威来源
- **多格式输出**：支持 AdGuard Home、Bind9、DNSMasq、SmartDNS、Unbound 等主流 DNS 服务器
- **自定义规则**：支持通过配置文件自定义域名规则
- **智能分流**：分离国内域名和国外域名，实现智能 DNS 分流
- **开箱即用**：生成的配置文件可直接导入使用

## 快速开始

### 直接下载

| 格式 | 黑名单 full | 黑名单 lite | 白名单 full | 白名单 lite |
| ---- | ----------- | ----------- | ----------- | ----------- |
| [AdGuard Home](dist/adguardhome/) | [txt](dist/adguardhome/blacklist_full.txt) | [txt](dist/adguardhome/blacklist_lite.txt) | [txt](dist/adguardhome/whitelist_full.txt) | [txt](dist/adguardhome/whitelist_lite.txt) |
| [Bind9](dist/bind9/) | [conf](dist/bind9/blacklist_full.conf) | [conf](dist/bind9/blacklist_lite.conf) | [conf](dist/bind9/whitelist_full.conf) | [conf](dist/bind9/whitelist_lite.conf) |
| [DNSMasq](dist/dnsmasq/) | [conf](dist/dnsmasq/blacklist_full.conf) | [conf](dist/dnsmasq/blacklist_lite.conf) | [conf](dist/dnsmasq/whitelist_full.conf) | [conf](dist/dnsmasq/whitelist_lite.conf) |
| [SmartDNS](dist/smartdns/) | [conf](dist/smartdns/blacklist_full.conf) | [conf](dist/smartdns/blacklist_lite.conf) | [conf](dist/smartdns/whitelist_full.conf) | [conf](dist/smartdns/whitelist_lite.conf) |
| [Unbound](dist/unbound/) | [conf](dist/unbound/blacklist_full.conf) | [conf](dist/unbound/blacklist_lite.conf) | [conf](dist/unbound/whitelist_full.conf) | [conf](dist/unbound/whitelist_lite.conf) |
| [纯域名](dist/domain/) | [txt](dist/domain/blacklist_full.txt) | [txt](dist/domain/blacklist_lite.txt) | [txt](dist/domain/whitelist_full.txt) | [txt](dist/domain/whitelist_lite.txt) |

AdGuard Home 另提供单行合并格式：[黑名单 full](dist/adguardhome/blacklist_full_combine.txt)、[黑名单 lite](dist/adguardhome/blacklist_lite_combine.txt)、[白名单 full](dist/adguardhome/whitelist_full_combine.txt)、[白名单 lite](dist/adguardhome/whitelist_lite_combine.txt)。

### 本地构建

```bash
# 克隆仓库
git clone https://github.com/hezhijie0327/GFWList2AGH.git
cd GFWList2AGH

# 运行构建脚本（Python 3.9+，仅标准库）
python3 build.py

# 生成的文件将保存在 dist/<格式>/ 目录中
```

## 用法

### 文件类型

| 文件名 | 说明 |
| ------ | ---- |
| `blacklist_full.{txt/conf}` | 黑名单完整版（包含所有子域名，约 3.4 万个域名） |
| `blacklist_lite.{txt/conf}` | 黑名单精简版（仅顶级域名） |
| `whitelist_full.{txt/conf}` | 白名单完整版（包含所有子域名，约 11.7 万个域名） |
| `whitelist_lite.{txt/conf}` | 白名单精简版（仅顶级域名） |
| `blacklist_*_combine.txt` | 单行合并格式（仅 AdGuard Home） |
| `whitelist_*_combine.txt` | 单行合并格式（仅 AdGuard Home） |

### 列表说明

- **黑名单（Blacklist）**：GFW 列表，包含被屏蔽或需要代理访问的域名
- **白名单（Whitelist）**：中国域名列表，包含国内可直连的域名
- **完整版（Full）**：包含所有子域名，匹配精确但体积较大
- **精简版（Lite）**：仅包含顶级域名，覆盖范围广但可能误伤

### AdGuard Home 配置

1. 进入 AdGuard Home 管理界面
2. 导航至 **设置** → **DNS 设置** → **上游 DNS 服务器**
3. 添加自定义 DNS 配置：

```ini
# 国外域名使用国外 DNS（黑名单）
[/google.com/youtube.com/facebook.com/]https://dns.opendns.com/dns-query

# 国内域名使用国内 DNS（白名单）
[/baidu.com/qq.com/taobao.com/]https://doh.pub/dns-query
```

4. 或直接导入生成的配置文件

### DNSMasq 配置

将下载的配置文件添加到 DNSMasq 配置目录：

```bash
# 复制配置文件
sudo cp blacklist_full.conf /etc/dnsmasq.d/gfwlist.conf
sudo cp whitelist_full.conf /etc/dnsmasq.d/chinalist.conf

# 重启 DNSMasq
sudo systemctl restart dnsmasq
```

### SmartDNS 配置

```bash
# 编辑 SmartDNS 配置
sudo nano /etc/smartdns/smartdns.conf

# 添加配置文件路径
conf-file /path/to/blacklist_full.conf
conf-file /path/to/whitelist_full.conf

# 重启 SmartDNS
sudo systemctl restart smartdns
```

### 自定义规则

您可以通过编辑 `custom/rules.txt` 文件来自定义域名规则。

#### 规则语法

| 标记 | 说明 | 示例 |
| ---- | ---- | ---- |
| `(@@@)` | 向 C（中国）及 G（GFW）列表添加域名 | `(@@@)example.org` |
| `(!!!)` | 从 C 及 G 列表移除域名 | `(!!!)example.org` |
| `(***)` | 从 C 及 G 列表排除域名（含子域名） | `(***)example.org` |
| `(!**)` | 从 C 及 G 列表排除关键词 | `(!**)example` |
| `(@%@)` | 仅向 C 列表添加域名 | `(@%@)example.org` |
| `(!%!)` | 仅从 C 列表移除域名 | `(!%!)example.org` |
| `(*%*)` | 仅从 C 列表排除域名 | `(*%*)example.org` |
| `(!%*)` | 仅从 C 列表排除关键词 | `(!%*)example` |
| `(@&@)` | 仅向 G 列表添加域名 | `(@&@)example.org` |
| `(!&!)` | 仅从 G 列表移除域名 | `(!&!)example.org` |
| `(*&*)` | 仅从 G 列表排除域名 | `(*&*)example.org` |
| `(!&*)` | 仅从 G 列表排除关键词 | `(!&*)example` |
| `(@%!)` | 向 C 列表添加并从 G 列表移除 | `(@%!)example.org` |
| `(!%@)` | 从 C 列表移除并向 G 列表添加 | `(!%@)example.org` |
| `(@&!)` | 向 G 列表添加并从 C 列表移除 | `(@&!)example.org` |
| `(!&@)` | 从 G 列表移除并向 C 列表添加 | `(!&@)example.org` |

#### 规则优先级

```text
移除(!) > 添加(@) > 排除(*)
```

#### 示例

```bash
# 将 Apple 域名添加到中国列表（直连）
(@%!)apple.com
(@%!)icloud.com

# 将 GitHub 添加到 GFW 列表（代理）
(@&!)github.com
(@&!)githubusercontent.com

# 排除 .com.cn 域名
(*&*)com.cn
```

## 文档

- [AGENTS.md](AGENTS.md) — 开发规范与实现细节（英文）

## License

[Apache License 2.0 with Commons Clause v1.0](LICENSE)

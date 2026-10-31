# Proxy-Conf | Clash (Mihomo) & Quantumult X 双端同步分流配置

本项目维护一套 **Clash (Mihomo / Clash Verge / OpenClash)** 与 **Quantumult X** 双端 **`1:1` 严格同步**的高精度代理分流配置与规则集。

核心针对 **全球 AI 全链路防封锁**、**美区 Apple 生态与国内满速直连兼顾**、**国际数字银行强风控保护** 以及 **流媒体/社媒「控制面与数据面分离」** 四大场景进行了深度定制与优化。

---

## 📁 仓库文件说明

### 1. Clash / Mihomo 配置文件与规则集
| 文件名 | 类型 | 对应策略组 | 说明 |
| :--- | :--- | :--- | :--- |
| [`clash.yaml`](./clash.yaml) | 主配置 | 全局 | Mihomo (Clash Meta) 完整主配置文件。顶部含脱敏占位节点（用于通过客户端订阅校验），支持通过本地 `Merge` 或 OpenClash 覆写注入真实节点；内置 Fake-IP、精细化 `nameserver-policy` DoH 分流、QUIC 降级保护及 `.mrs` 高性能规则集。 |
| [`AI.yaml`](./AI.yaml) | `classical` | `AI` | 全球人工智能与核心验证分流规则集（与 `QX_AI.list` 保持 1:1 同步）。涵盖 Apple Intelligence、iCloud 专用代理、主流大模型、AI 编程 Agent 及人机验证/OAuth/特性开关域名。 |
| [`Finance.yaml`](./Finance.yaml) | `classical` | `Banking` | 国际数字银行、欧洲电子钱包、外汇券商、加密货币交易所及银行级 KYC/反欺诈组件规则集（与 `Finance.list` 保持 1:1 同步）。 |
| [`Private_DIRECT.yaml`](./Private_DIRECT.yaml) | `classical` | `DIRECT` | 个人定制高优先级直连白名单。包含香港金融机构（BOCHK/HSBC HK/ZA Bank/AlipayHK 等）、常用云服务，以及 Windows/Office/Xbox/Switch 满速下载更新 CDN。 |

### 2. Quantumult X 规则集与脚本资源
| 文件名 | 类型 | 对应策略组 | 说明 |
| :--- | :--- | :--- | :--- |
| [`QX_AI.list`](./QX_AI.list) | `filter` | `AI` | Quantumult X 全球人工智能与核心服务分流规则集（与 `AI.yaml` 1:1 同步），最高优先级置顶防截胡与防去广告误杀。 |
| [`Private.list`](./Private.list) | `filter` | 多策略组 | Quantumult X 个人核心定制总表（高优先级 `inserted-resource`）。集成海外加密 DNS、Wi-Fi Calling、防欺诈指纹保护、Apple 双策略组精细分流、全球主流服务「控制面 + 数据面」分离规则及直连白名单（与 `clash.yaml` 内联规则 + `Private_DIRECT.yaml` 1:1 对齐）。 |
| [`Finance.list`](./Finance.list) | `filter` | `Banking` | Quantumult X 国际数字银行、欧洲电子钱包与加密货币分流规则集（与 `Finance.yaml` 1:1 同步）。 |
| [`AllInOne.conf`](./AllInOne.conf) | `rewrite` | - | Quantumult X 综合重写（Rewrite）、重定向与去广告规则合集。 |
| [`resource-parser.js`](./resource-parser.js) | `script` | - | 资源解析器脚本（©Shawn），支持多格式节点订阅解析、筛选重命名及跨平台分流/重写规则转换。 |
| [`tidal.js`](./tidal.js) | `script` | - | TIDAL 音质解锁重写脚本。 |

---

## 🏗️ 核心分流架构设计

### 1. 控制面与数据面分离（锁定位 + 省流量 + 跑满速）
针对 YouTube、Netflix、Telegram、GitHub、Google、X (Twitter)、Instagram、Facebook、Reddit、Discord、TikTok、Amazon、Adobe 等全球高频服务，采用**控制面与数据面剥离**设计：
- **控制面（主站 / 登录鉴权 / API / 地区解锁与趋势定位）** ➔ 走 `🚀 手选主流` 或专属策略组（如 `Google`），固定纯净节点，确保账号安全与美区内容定位稳定。
- **数据面（视频流 / 音频流 / 大图 CDN / 软件安装包与更新包）** ➔ 前置剥离至 `GMedia` 大流量媒体组（如 `googlevideo.com`、`nflxvideo.net`、`twimg.com`、`cdninstagram.com`、`fbcdn.net`、`githubusercontent.com`、`dl.google.com` 等），可使用大带宽/低倍率高速节点，避免挤占高价值或自建节点带宽。

### 2. 苹果生态双轨架构（美区 Apple ID + 全家桶满速直连）
在不影响国内 iCloud 同步与 App 下载满速体验的前提下，完整解锁美区专属服务：
- **`AI` 策略组（智能与隐私隧道）**：承接 Apple Intelligence、Siri AI（`guzzoni.apple.com` / `smoot.apple.com`）、iCloud Private Relay 专用代理（`mask.icloud.com` / `apple-relay.*`，并在全局拦截 UDP 443 前特例放行 MASQUE/QUIC 握手）以及地区准入判定（`gspe1-ssl.ls.apple.com`）。
- **`AppleProxy` 策略组（美区专属服务与商店控制面）**：精准剥离 Apple News、Apple TV+ 控制面、Apple Podcasts、Stocks 以及 App Store 搜索与探索页面接口（`amp-api-edge.apps.apple.com` / `search.itunes.apple.com` 等），默认走美国节点（Apple TV+ 纯视频流 `hls-svod.itunes.apple.com` 剥离至 `GMedia`）。
- **`Apple` 策略组（高速直连保障全链路）**：涵盖 iOS/macOS 系统与固件更新、App Store 应用安装与增量升级包（`mzstatic.com` / `iosapps.itunes.apple.com`）、Apple Music 无损音频流、iCloud 全家桶（相册/云盘/备忘录/APNs 推送）及 Apple Maps 导航定位，配合国内 DNS 解析实现满速直连（默认 `DIRECT`）。

### 3. AI 全链路覆盖与防误杀保护
`AI.yaml` 与 `QX_AI.list` 均置于**广告拦截（`REJECT`）与通用规则之前**，解决 AI 服务常见的“登录死循环”、“人机验证失败”与“地区不支持”问题：
- **底层鉴权与风控白名单**：完整收录 Cloudflare Turnstile / Arkose Labs / hCaptcha / reCAPTCHA 人机验证，Auth0 / Okta / Clerk / WorkOS / Supabase 等 OAuth 统一身份认证组件，以及 Statsig / LaunchDarkly / Datadog / Sentry 等特性开关（Feature Flags）与核心遥测域名，防止被去广告规则误杀导致前端默认判定“所在地区未开放”。
- **全品类 AI 覆盖**：涵盖 OpenAI (ChatGPT/Sora/LiveKit)、Google AI (Gemini/NotebookLM/AI Studio/DeepMind)、Anthropic (Claude)、xAI (Grok)、AI 编程与软件工程 Agent（Cursor / Windsurf / Copilot / Antigravity / Trae / Devin / Lovable / Bolt / v0 等）、AI 搜索与学术（Perplexity / Genspark / Felo / Consensus）、多模态生成（Midjourney / Runway / Luma / Suno / ElevenLabs）、推理算力平台（OpenRouter / Groq / Hugging Face）及全球 `.ai` 顶级域名兜底。

### 4. 国际数字银行与防欺诈风控同源保护
- **欧洲数字银行与加密金融（`Banking` 策略组）**：收敛 Dukascopy、Swissquote、Yuh、N26、iFast Global Bank、Wise、Revolut、Paysera、Skrill / Neteller (Paysafe) 等强风控金融机构，以及 Binance、OKX、Bybit、Coinbase、Kraken、TradingView 等加密与交易平台（建议固定瑞士或欧洲纯净 IP）。
- **KYC 与反欺诈组件同 IP 绑定**：同步纳入 Sumsub、Jumio、Onfido、Castle、Group-IB、Intercom 等银行内嵌 KYC 认证与安全风控组件；同时将 ThreatMetrix (`online-metrix.net`)、Sift、Forter、Riskified、MaxMind、FingerprintJS 等跨国电商/支付设备指纹 SDK 锁定至 `🚀 手选主流`，防止主站与风控探针出口 IP 割裂触发异常审核。
- **香港金融服务直连（`DIRECT`）**：中银香港（BOCHK）、香港汇丰（HSBC HK）、众安银行（ZA Bank）、蚂蚁银行（Ant Bank）、天星银行（Airstar）、中信银行国际及 AlipayHK 保持国内直连。

### 5. DNS 防污染与精细化分流
- **国内纯净 DoH 优先**：默认及 `geosite:cn`、Apple 全家桶直连域名、微软 Windows Update / Xbox / 任天堂 Switch 游戏下载 CDN 强制使用阿里（`223.5.5.5`）与腾讯（`119.29.29.29`）DoH，确保解析出国内最优 CDN 节点。
- **海外加密 DoH 隔离**：`AgAI` 规则集、iCloud Private Relay、`geosite:category-ai-!cn`、`.ai` 域名及海外非中国大陆域名通过代理通道使用 Cloudflare（`1.1.1.1`）与 Google（`8.8.8.8`）DoH，杜绝 DNS 污染与金丝雀域名阻断。

---

## 🎯 策略组架构一览

| 策略组名称 | 类型 | 核心用途说明 |
| :--- | :--- | :--- |
| `🚀 手选主流` | `select` | **核心主策略组**。聚合各地区自动测速组与自建节点组，供主流海外控制面与定位服务调用（建议默认选美国）。 |
| `🏎️ 速度优选` | `url-test` | 跨地区全节点自动测速优选，筛选最低延迟可用节点。 |
| `🚑 故障转移` | `fallback` | 按预设地区优先级顺序进行可用性健康检查与自动容灾切换。 |
| `🎯 手选节点` | `select` | 手动选择冷门地区或特定单节点（如英国 Wi-Fi Calling 等特定需求）。 |
| `AI` | `select` | **人工智能与 Apple Intelligence 专属组**。建议固定纯净美国自建节点或原生 IP 节点。 |
| `GMedia` | `select` | **大流量流媒体与 CDN 数据面组**。承接视频流、音频流、社媒大图与软件安装包下载。 |
| `Banking` | `select` | **国际数字银行与加密货币专属组**。建议固定瑞士（`🇨🇭 CH+`）或欧洲专属节点，严禁频繁切换 IP。 |
| `PayPal` | `select` | PayPal 与 Braintree 支付网关专属策略组。 |
| `AppleProxy` | `select` | Apple 美区专属服务（News / TV+ 控制面 / 美区商店搜索）策略组。 |
| `Apple` | `select` | Apple 国内高速保障服务（系统更新 / App 下载 / iCloud / Music）策略组，默认建议选 `DIRECT`。 |
| `Google` | `select` | Google 搜索、YouTube 主站控制面与 API 服务策略组。 |
| `Microsoft` | `select` | 微软国际服务与账户策略组（系统更新与 Office CDN 已前置直连）。 |
| `OneDrive` | `select` | OneDrive 云盘同步专属策略组。 |
| `Game` | `select` | 任天堂 Switch 与 Xbox 联机大厅策略组（游戏本体下载 CDN 已前置直连）。 |
| `Global` | `select` | 其余未命中细分规则的海外流量兜底策略组。 |
| `🇺🇸 US+` / `🇨🇭 CH+` | `url-test` | 美国 / 瑞士自建固定节点自动测速组。 |
| `🇺🇸 US` / `🇭🇰 HK` / `🇯🇵 JP` / `🇼🇸 TW` / `🇸🇬 SG` / `🇰🇷 KR` | `url-test` | 机场订阅对应国家/地区正则筛选自动测速组（自动剔除免费/试用/失联/高倍率节点）。 |
| `🏴‍☠️ CF` | `url-test` | 优选备份节点自动测速组。 |

---

## 🚀 快速使用指南

### 一、Clash Verge / Mihomo Party 使用方法

1. **导入订阅配置**
   在客户端新建远程配置（Profiles），填入本仓库 `clash.yaml` 的 Raw 链接：
   ```text
   https://raw.githubusercontent.com/Ag-Rock/proxy-conf/main/clash.yaml
   ```

2. **配置全局 Merge 覆写（注入真实节点）**
   由于公开仓库中的 `clash.yaml` 顶部使用的是 `127.0.0.1` 脱敏占位节点，请在客户端的 **「全局扩展覆写配置 (Merge)」** 中填入你的真实订阅与自建节点（会自动覆盖顶部的占位配置）：
   ```yaml
   # Clash Verge Merge 覆写示例
   proxy-providers:
     KKK:
       type: http
       url: "https://your-airport-subscription-url"
       path: ./proxy_provider/KKK.yaml
       interval: 86400
       health-check:
         enable: true
         url: https://www.gstatic.com/generate_204
         interval: 600
         lazy: true
     CF.live:
       type: http
       url: "https://your-backup-sub-1"
       path: ./proxy_provider/CF.live.yaml
       interval: 86400
       proxy: 🚀 手选主流
     CF.art:
       type: http
       url: "https://your-backup-sub-2"
       path: ./proxy_provider/CF.art.yaml
       interval: 86400
       proxy: 🚀 手选主流

   proxies:
     - { name: 🇺🇸 美国-1, server: your.us1.domain, port: 443, type: vmess, uuid: your-uuid, alterId: 0, cipher: auto, udp: true, tls: true, client-fingerprint: chrome, network: ws, ws-opts: { path: /us, headers: { Host: your.us1.domain } } }
     - { name: 🇺🇸 美国-2, server: your.us2.domain, port: 443, type: vmess, uuid: your-uuid, alterId: 0, cipher: auto, udp: true, tls: true, client-fingerprint: chrome, network: ws, ws-opts: { path: /us, headers: { Host: your.us2.domain } } }
     - { name: 🇺🇸 美国-3, server: your.us3.domain, port: 443, type: vmess, uuid: your-uuid, alterId: 0, cipher: auto, udp: true, tls: true, client-fingerprint: chrome, network: ws, ws-opts: { path: /us, headers: { Host: your.us3.domain } } }
     - { name: 🇨🇭 瑞士-1, server: your.ch1.domain, port: 443, type: vmess, uuid: your-uuid, alterId: 0, cipher: auto, udp: true, tls: true, client-fingerprint: chrome, network: ws, ws-opts: { path: /ch, headers: { Host: your.ch1.domain } } }
     - { name: 🇨🇭 瑞士-2, server: your.ch2.domain, port: 443, type: vmess, uuid: your-uuid, alterId: 0, cipher: auto, udp: true, tls: true, client-fingerprint: chrome, network: ws, ws-opts: { path: /ch, headers: { Host: your.ch2.domain } } }
     - { name: 🇨🇭 瑞士-3, server: your.ch3.domain, port: 443, type: vmess, uuid: your-uuid, alterId: 0, cipher: auto, udp: true, tls: true, client-fingerprint: chrome, network: ws, ws-opts: { path: /ch, headers: { Host: your.ch3.domain } } }
   ```

---

### 二、OpenClash (软路由) 使用方法

1. **添加配置订阅**：
   - 进入 `OpenClash` -> `配置订阅` -> `新增`，订阅地址填入 `clash.yaml` 的 Raw 链接（若软路由直连 GitHub 困难，可使用 `https://testingcf.jsdelivr.net/gh/Ag-Rock/proxy-conf@main/clash.yaml` 镜像加速）。
   - **在线订阅转换**：保持**关闭（不勾选）**，以完整保留配置内的策略组与规则结构。
2. **防覆写冲刷设置**：
   - `全局设置 -> 模式设置`：确认启用 **Meta 内核**（支持 `.mrs` 规则集与 `geosite`）。
   - `全局设置 -> DNS 设置`：**不勾选**「自定义上游 DNS 服务器」，保留本配置自带的 `nameserver-policy`。
   - `覆写设置 -> 规则设置`：**不勾选**第三方规则集与自定义规则。
3. **开发者选项注入节点**：
   - 在 `覆写设置 -> 开发者选项`（自定义覆写脚本）的 `exit 0` 上方通过 Ruby 脚本将 `config["proxy-providers"]` 与 `config["proxies"]` 替换为真实节点配置。

---

### 三、Quantumult X 使用方法

在 Quantumult X 配置文件的 `[filter_remote]` 模块顶部按如下顺序引入本仓库的三大核心分流规则（开启 `inserted-resource=true` 确保优先级高于去广告与通用规则）：

```ini
[filter_remote]
# 1. 最高优先级：AI 全链路、个人定制总表与国际金融规则（置于去广告规则之前）
https://raw.githubusercontent.com/Ag-Rock/proxy-conf/main/QX_AI.list, tag=AI, force-policy=AI, update-interval=86400, opt-parser=false, inserted-resource=true, enabled=true
https://raw.githubusercontent.com/Ag-Rock/proxy-conf/main/Private.list, tag=Private, update-interval=86400, opt-parser=true, inserted-resource=true, enabled=true
https://raw.githubusercontent.com/Ag-Rock/proxy-conf/main/Finance.list, tag=Banking, force-policy=Banking, update-interval=86400, opt-parser=false, inserted-resource=true, enabled=true

# 2. 去广告规则（置于上方三条规则之后，防止误杀 AI 遥测与银行风控验证域名）
https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/QuantumultX/Advertising/Advertising.list, tag=Advertising, force-policy=REJECT, update-interval=345600, opt-parser=true, inserted-resource=true, enabled=true
```

重写模块可在 `[rewrite_remote]` 中引用：
```ini
[rewrite_remote]
https://raw.githubusercontent.com/Ag-Rock/proxy-conf/main/AllInOne.conf, tag=AllInOne, update-interval=345600, opt-parser=false, enabled=true
```

---

## 🔄 维护规范

- **双端同步原则**：修改任何分流规则时，务必保持 Clash 端与 Quantumult X 端 **1:1 同步更新**：
  - `AI.yaml` $\leftrightarrow$ `QX_AI.list`
  - `Finance.yaml` $\leftrightarrow$ `Finance.list`
  - `clash.yaml`（内联规则）+ `Private_DIRECT.yaml` $\leftrightarrow$ `Private.list`
- **隐私安全规范**：公开仓库中严禁提交任何真实机场订阅链接、服务器域名/IP、UUID 或私钥凭证；所有敏感节点信息均通过客户端本地覆写（Merge / 本地配置）注入。

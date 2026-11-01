# Proxy-Conf | Clash (Mihomo) / Stash & Quantumult X 多端同步分流配置

本项目维护一套 **Clash (Mihomo / Clash Verge / OpenClash)**、**Stash (iOS / macOS)** 与 **Quantumult X** 多端共享分流目标的配置与规则集。Clash 与 Stash 的主规则逐条同步；QX 保留自身 DNS、UDP 和策略组实现，不能将三端运行行为视为完全一致。

核心针对 **全球 AI 访问与验证**、**美区 Apple 生态与国内满速直连兼顾**、**国际数字银行出口管理** 以及 **流媒体/社媒「控制面与数据面分离」** 四大场景进行了深度定制与优化。

---

## 📁 仓库文件说明

### 1. Clash / Mihomo / Stash 配置文件与规则集
| 文件名 | 类型 | 对应策略组 | 说明 |
| :--- | :--- | :--- | :--- |
| [`clash.yaml`](./clash.yaml) | 主配置 | 全局 | Mihomo (Clash Meta) 完整主配置文件。顶部含脱敏占位节点（用于通过客户端订阅校验），支持通过本地 `Merge` 或 OpenClash 覆写注入真实节点；内置 Fake-IP、精细化 `nameserver-policy` DoH 分流、UDP 443 兼容性策略；纯域名与纯 IP 规则集全量采用 `.mrs` 二进制极速基数树（16 域名集 + 3 IP 集），减少文本规则解析开销。 |
| [`stash.yaml`](./stash.yaml) | 主配置 | 全局 | Stash (iOS / macOS) 远程订阅专用主配置文件（与 `clash.yaml` 规则 1:1 对齐）。针对 Stash 引擎专门适配了展开版 68 项独立 `nameserver-policy` DoH 映射、`default-nameserver` 引导解析及自动检测组 `lazy: true`、600 秒检测间隔；远程规则集针对 Stash 定制为 `format: yaml` 基数树格式，条目加载情况以客户端检查结果为准，支持通过本地 `.stoverride`（`#!replace`）注入真实节点。 |
| [`AI.yaml`](./AI.yaml) | `classical` | `AI` | 全球人工智能与核心验证分流规则集（与 `QX_AI.list` 保持 1:1 同步）。涵盖 Apple Intelligence、iCloud 专用代理、主流大模型、AI 编程 Agent 及人机验证/OAuth/特性开关域名。 |
| [`Finance.yaml`](./Finance.yaml) | `classical` | `Banking` | 国际数字银行、欧洲电子钱包、外汇券商、加密货币交易所及银行级 KYC/反欺诈组件规则集（与 `Finance.list` 保持 1:1 同步）。 |
| [`Private_DIRECT.yaml`](./Private_DIRECT.yaml) | `classical` | `DIRECT` | 个人定制高优先级直连白名单。包含香港金融机构（BOCHK/HSBC HK/ZA Bank/AlipayHK 等）、常用云服务，以及 Windows/Office/Xbox/Switch 满速下载更新 CDN。 |

### 2. Quantumult X 规则集与脚本资源
| 文件名 | 类型 | 对应策略组 | 说明 |
| :--- | :--- | :--- | :--- |
| [`QX_AI.list`](./QX_AI.list) | `filter` | `AI` | Quantumult X 全球人工智能与核心服务分流规则集（与 `AI.yaml` 1:1 同步），最高优先级置顶防截胡与防去广告误杀。 |
| [`Private.list`](./Private.list) | `filter` | 多策略组 | Quantumult X 个人核心定制总表（高优先级 `inserted-resource`）。集成海外加密 DNS、Wi-Fi Calling、防欺诈指纹保护、Apple 双策略组精细分流、全球主流服务「控制面 + 数据面」分离规则及直连白名单（与 YAML 端共享主要业务分流目标；远程通用规则来源及顺序存在端别差异）。 |
| [`Finance.list`](./Finance.list) | `filter` | `Banking` | Quantumult X 国际数字银行、欧洲电子钱包与加密货币分流规则集（与 `Finance.yaml` 1:1 同步）。 |
| [`AllInOne.conf`](./AllInOne.conf) | `rewrite` | - | Quantumult X 综合重写（Rewrite）、重定向与去广告规则合集。 |
| [`resource-parser.js`](./resource-parser.js) | `script` | - | 资源解析器脚本（©Shawn），支持多格式节点订阅解析、筛选重命名及跨平台分流/重写规则转换。 |

---

## 🏗️ 核心分流架构设计

### 1. 控制面与数据面分离（锁定位 + 省流量 + 跑满速）
针对 YouTube、Netflix、Telegram、GitHub、Google、X (Twitter)、Instagram、Facebook、Reddit、Discord、TikTok、Amazon、Adobe 等全球高频服务，采用**控制面与数据面剥离**设计：
- **控制面（主站 / 登录鉴权 / API / 地区解锁与趋势定位）** ➔ 走 `🚀 手选主流` 或专属策略组（如 `Google`），可手动固定节点以减少出口变化；下层自动测速组仍可能换节点。
- **数据面（视频流 / 音频流 / 大图 CDN / 软件安装包与更新包）** ➔ 前置剥离至 `GMedia` 大流量媒体组（如 `googlevideo.com`、`nflxvideo.net`、`twimg.com`、`cdninstagram.com`、`fbcdn.net`、`githubusercontent.com`、`dl.google.com` 等），可使用大带宽/低倍率高速节点，避免挤占高价值或自建节点带宽。

### 2. 苹果生态双轨架构（美区 Apple ID + 全家桶满速直连）
将国内基础服务和海外服务分组管理；实际可用性还取决于账户、地区、设备和服务端限制：
- **`AI` 策略组（智能与隐私隧道）**：承接 Apple Intelligence、Siri AI（`guzzoni.apple.com` / `smoot.apple.com`）、iCloud Private Relay 专用代理（`mask.icloud.com` / `apple-relay.*`，并在全局拦截 UDP 443 前特例放行 MASQUE/QUIC 握手）以及地区准入判定（`gspe1-ssl.ls.apple.com`）。
- **`AppleProxy` 策略组（美区专属服务与商店控制面）**：精准剥离 Apple News、Apple TV+ 控制面、Apple Podcasts、Stocks 以及 App Store 搜索与探索页面接口（`amp-api-edge.apps.apple.com` / `search.itunes.apple.com` 等），默认走美国节点（Apple TV+ 纯视频流 `hls-svod.itunes.apple.com` 剥离至 `GMedia`）。
- **`Apple` 策略组（高速直连保障全链路）**：涵盖 iOS/macOS 系统与固件更新、App Store 应用安装与增量升级包（`mzstatic.com` / `iosapps.itunes.apple.com`）、Apple Music 无损音频流、iCloud 全家桶（相册/云盘/备忘录/APNs 推送）及 Apple Maps 导航定位，配合国内 DNS 解析优先直连（首选项为 `DIRECT`）。

### 3. AI 全链路覆盖与防误杀保护
`AI.yaml` 与 `QX_AI.list` 均置于**广告拦截（`REJECT`）与通用规则之前**，解决 AI 服务常见的“登录死循环”、“人机验证失败”与“地区不支持”问题：
- **底层鉴权与风控白名单**：完整收录 Cloudflare Turnstile / Arkose Labs / hCaptcha / reCAPTCHA 人机验证，Auth0 / Okta / Clerk / WorkOS / Supabase 等 OAuth 统一身份认证组件，以及 Statsig / LaunchDarkly / Datadog / Sentry 等特性开关（Feature Flags）与核心遥测域名，防止被去广告规则误杀导致前端默认判定“所在地区未开放”。
- **全品类 AI 覆盖**：涵盖 OpenAI (ChatGPT/Sora/LiveKit)、Google AI (Gemini/NotebookLM/AI Studio/DeepMind)、Anthropic (Claude)、xAI (Grok)、AI 编程与软件工程 Agent（Cursor / Windsurf / Copilot / Antigravity / Trae / Devin / Lovable / Bolt / v0 等）、AI 搜索与学术（Perplexity / Genspark / Felo / Consensus）、多模态生成（Midjourney / Runway / Luma / Suno / ElevenLabs）、推理算力平台（OpenRouter / Groq / Hugging Face）及全球 `.ai` 顶级域名兜底。

### 4. 金融出口与共享客服

- **Banking**：首选 `🇨🇭 CH+`。在 Banking 内直接筛选瑞士、德国、英国、法国、荷兰、爱尔兰等节点；也可直接选择三个自建瑞士节点。
- **PayPal**：首选 `🇺🇸 US+`。在 PayPal 内直接筛选美国、德国、英国、日本、香港、菲律宾节点。可用地区取决于 KKK 订阅实际提供的节点及名称；筛选组不会凭空生成节点。
- **固定出口**：CH+ / US+ 仍是自动测速组，不能保证固定 IP。需要保持同一出口时，选择具体节点，直接在 Banking / PayPal 中选定节点；节点供应商本身也可能更换出口。没有新增跨地区自动故障切换。
- **Intercom**：`intercom.io` 用于客服组件及接口，`intercomcdn.com` 用于脚本、附件和媒体；不是银行专属风控域名。两者连同 `intercom.com`、`intercom-chat.com`、`intercom-sheets.com` 统一使用 `🚀 手选主流`，从 AI / Finance 清单移出，并先于广告规则匹配。[Intercom 官方说明](https://www.intercom.com/help/en/articles/12292300-resolving-content-security-policy-csp-errors)
- **共享客服的边界**：Intercom 直接使用手选主流，不另建策略组。仅靠共享域名无法识别调用它的银行或 AI 应用，也无法自动保持各应用同 IP。
- **其他共享组件**：Sumsub、Jumio、Onfido 等保留在 Banking；其归类是本配置的取舍，不保证所有应用的验证请求都与主站同出口。香港金融服务保留原有直连策略。

### 5. DNS 分流与端别差异

- **Clash / Stash**：保留国内默认 DoH、Apple/CDN 国内解析，以及 AI、Private Relay、海外 geosite 的 Cloudflare/Google DoH。Clash 使用 `respect-rules`；Stash 保留 `follow-rule`、独立映射及引导 DNS。[Stash 官方 DNS 文档](https://stash.wiki/en/features/dns-server)
- **QX 默认解析**：使用阿里、腾讯 DoH；启用 `no-system` / `no-ipv6`。移除配置 DoH 后不会充当默认备用的普通 DNS 条目。Apple、微软和游戏 CDN 的定向 DNS 改为阿里 DoH，补齐根域名和子域名映射。
- **QX 海外定向解析**：从 QX_AI、Finance、Private 中属于 AI / Banking 的明确域名及手选主流下的五个 Intercom 域名生成 Cloudflare DoH 映射，包括 Private Relay、Apple Intelligence 和 `.ai`。根域名与子域名分别声明，同一上游的重复父子域名会合并。
- **边界**：QX 的关键词规则、远程通用规则及 geosite 不会被自动转换为 DNS 通配规则；未显式覆盖的域名仍用默认 DoH。代理连接通常由节点端解析目标域名，不能把本地 DNS 查询结果当作最终代理目标 IP。QX 内置 DNS 请求不保证服从普通代理规则，因此不承诺海外 DoH 自动通过节点访问；需要在实际 Wi-Fi/蜂窝网络验证可达性。[QX 官方示例](https://github.com/crossutility/Quantumult-X/blob/master/sample.conf)
- **维护**：运行 `python3 proxy-conf/scripts/sync_qx_dns.py` 更新私人 QX 配置中的标记区块；不要手工修改生成区块。脚本不输出订阅、节点凭证或证书。

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
| `Banking` | `select` | 首选 CH+；组内直接列出三个自建瑞士节点和 KKK 的欧洲节点。 |
| `PayPal` | `select` | 首选 US+；组内直接列出三个自建美国节点和 KKK 的美、德、英、日、港、菲节点。 |
| `AppleProxy` | `select` | Apple 美区专属服务（News / TV+ 控制面 / 美区商店搜索）策略组。 |
| `Apple` | `select` | Apple 国内高速保障服务（系统更新 / App 下载 / iCloud / Music）策略组，首选项为 `DIRECT`。 |
| `Google` | `select` | Google 搜索、YouTube 主站控制面与 API 服务策略组。 |
| `Microsoft` | `select` | 微软国际服务与账户策略组（系统更新与 Office CDN 已前置直连）。 |
| `OneDrive` | `select` | OneDrive 云盘同步专属策略组。 |
| `Game` | `select` | 任天堂 Switch 与 Xbox 联机大厅策略组（游戏本体下载 CDN 已前置直连）。 |
| `Global` | `select` | 其余未命中细分规则的海外流量兜底策略组。 |
| `🇺🇸 US+` / `🇨🇭 CH+` | `url-test` | 美国 / 瑞士自建节点自动测速组（可能切换节点）。 |
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

### 三、Stash (iOS / macOS) 使用方法

1. **导入远程订阅配置**：
   - 打开 Stash -> `设置` -> `配置文件` -> `从 URL 下载`，填入 `stash.yaml` 的 Raw 链接：
     ```text
     https://raw.githubusercontent.com/Ag-Rock/proxy-conf/main/stash.yaml
     ```
   - **配置家庭 Wi-Fi 自动挂起（交给软路由 OpenClash）**：
     - 进入 Stash -> `设置` -> `按需连接 (On-Demand)`，开启 `按需连接`，在下方 `排除 SSIDs (Excluded SSIDs)` 中添加家庭 Wi-Fi 名称（如 `Ag`、`Ag_5G`），并确保**关闭** `保持持续运行`。
     - 在 iOS 系统 `设置 -> 隐私与安全性 -> 定位服务 -> Stash` 中将定位权限设为 `始终`（用于识别 Wi-Fi SSID）。

2. **配置本地 `.stoverride` 覆写（注入真实节点）**：
   - 在 Stash 的 `覆写 (Override)` 中新建本地覆写（或放入 `iCloud Drive/Stash/Overrides/local_nodes.stoverride`）并启用，通过 `#!replace` 完整替换 `stash.yaml` 顶部的 `127.0.0.1` 脱敏占位节点：
     ```yaml
     name: 私人节点注入 (Local Nodes)
     desc: 替换 GitHub 公开 stash.yaml 中的 127.0.0.1 占位节点与机场订阅，敏感信息仅保存在本地
     icon: https://raw.githubusercontent.com/Vbaethon/HOMOMIX/refs/heads/main/Icon/Color/Large/Global.png
     category: 本地节点

     proxy-providers: #!replace
       KKK:
         url: "https://your-airport-subscription-url"
         type: http
         interval: 86400
         health-check:
           enable: true
           url: https://www.gstatic.com/generate_204
           interval: 600
           lazy: true
           timeout: 10000
       CF.live:
         url: "https://your-backup-sub-1"
         type: http
         interval: 86400
         proxy: 🚀 手选主流
         health-check:
           enable: true
           url: https://www.gstatic.com/generate_204
           interval: 600
           lazy: true
           timeout: 10000
       CF.art:
         url: "https://your-backup-sub-2"
         type: http
         interval: 86400
         proxy: 🚀 手选主流
         health-check:
           enable: true
           url: https://www.gstatic.com/generate_204
           interval: 600
           lazy: true
           timeout: 10000

     proxies: #!replace
       - { name: 🇺🇸 美国-1, server: your.us1.domain, port: 443, type: vmess, uuid: your-uuid, alterId: 0, cipher: auto, udp: true, tls: true, network: ws, ws-opts: { path: /us, headers: { Host: your.us1.domain } } }
       - { name: 🇺🇸 美国-2, server: your.us2.domain, port: 443, type: vmess, uuid: your-uuid, alterId: 0, cipher: auto, udp: true, tls: true, network: ws, ws-opts: { path: /us, headers: { Host: your.us2.domain } } }
       - { name: 🇺🇸 美国-3, server: your.us3.domain, port: 443, type: vmess, uuid: your-uuid, alterId: 0, cipher: auto, udp: true, tls: true, network: ws, ws-opts: { path: /us, headers: { Host: your.us3.domain } } }
       - { name: 🇨🇭 瑞士-1, server: your.ch1.domain, port: 443, type: vmess, uuid: your-uuid, alterId: 0, cipher: auto, udp: true, tls: true, network: ws, ws-opts: { path: /ch, headers: { Host: your.ch1.domain } } }
       - { name: 🇨🇭 瑞士-2, server: your.ch2.domain, port: 443, type: vmess, uuid: your-uuid, alterId: 0, cipher: auto, udp: true, tls: true, network: ws, ws-opts: { path: /ch, headers: { Host: your.ch2.domain } } }
       - { name: 🇨🇭 瑞士-3, server: your.ch3.domain, port: 443, type: vmess, uuid: your-uuid, alterId: 0, cipher: auto, udp: true, tls: true, network: ws, ws-opts: { path: /ch, headers: { Host: your.ch3.domain } } }
     ```

   - **验证生效**：
     - 在 Stash 首页启动连接，进入「规则提供者 (Rule Providers)」页面点击刷新，确认全部 24 个规则集均正常显示非零条目数量。

---

### 四、Quantumult X 使用方法

私人完整配置为工作区根目录的 `QX_Pro.conf`，不发布到本仓库。Intercom 规则直接引用现有的 `🚀 手选主流`，无需新增策略组。

三个客户端更新后，请检查保存的策略选择：`Apple → DIRECT`、`Banking → CH+`、`PayPal → US+`。新的首项只定义初始选择，不能覆盖客户端已经保存的手动选择。


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

- `Clash_Pro.yaml` 与 `QX_Pro.conf` 是工作区根目录的私人配置，只保存在本地，不纳入公开仓库。
- `Clash_Pro.yaml` 保留真实节点与订阅；全局配置、DNS、策略组、主规则和规则提供者定义与公开 `clash.yaml` 同步，作为完整策略定义备份。远程规则集内容仍由对应文件维护，并非离线内嵌快照。
- `stash.yaml` 的主规则和业务策略与 Clash 同步，但保留 flow-style YAML、独立 DNS 映射、`follow-rule`、引导 DNS、600 秒 lazy 检测，以及 YAML 格式规则提供者；不直接用 Mihomo 配置覆盖它。
- AI.yaml / QX_AI.list、Finance.yaml / Finance.list 保持域名与关键词条目同步；业务规则变动时同步 Private.list 和两个 YAML 主文件，并重新生成 QX DNS。
- Mihomo 的纯域名/IP 提供者保留 MRS；Stash 保留 domain/ipcidr + YAML；复合自定义规则保留 classical + YAML。
- Spotify CDN 已统一为 DIRECT，包括私人 Clash 备份。三端仍有明确差异：QX 默认 GMedia 为速度优选，Clash/Stash 为手选主流；QX 未启用全局 UDP 443 丢弃，Clash/Stash 保留现有拦截与 Private Relay 例外。
- 更新顺序：先更新远程规则，使 Intercom 指向已有的手选主流，再更新客户端配置以移除旧的 Support 组；避免旧规则仍引用已删除的策略组。

在工作区根目录运行（需要 Python 3 和 Ruby/Psych；公开仓库单独克隆时须自行提供两个私人配置）：

```sh
python3 proxy-conf/scripts/sync_qx_dns.py
python3 proxy-conf/scripts/sync_qx_dns.py --check
python3 proxy-conf/scripts/validate_configs.py
git -C proxy-conf diff --check
```

### 2026-11-01 验证结果

- 私人 `Clash_Pro.yaml` 与公开 `clash.yaml` 均通过本机 Mihomo Meta v1.19.32 的 `-t` 原生配置检查；使用临时测试目录，没有切换正在运行的配置。
- 三份 YAML 通过解析、24 个策略组的默认值/引用/循环检查、216 条主规则同步检查、手选节点的地区正则样例检查。
- AI / Finance 两种规则格式一致；Intercom 归属唯一；11 个本地域名分流样例通过。
- QX 通过策略引用、880 条定向 DoH 模式、国内/海外 DNS 样例和生成区块一致性检查。该检查是静态模型，不等同于 QX 原生解析器。
- 阿里、腾讯、Cloudflare 三个 DoH 端点在当前电脑网络绕过环境 HTTP 代理查询 `example.com`，均返回合法 DNS 报文（RCODE 0，含 A 记录）；不代表其他网络也可达。
- 公开配置和文档未包含私人节点 UUID、订阅 URL 或 P12 内容；差异格式检查通过。
- **尚未完成的实机验证**：Stash/QX 原生导入、手机 Wi-Fi/蜂窝网络、真实节点可达性、各账户登录/支付、Private Relay 与流媒体播放。Stash CLI 只能控制已运行内核，QX 非切换式检查界面本次未能打开；未将这些项目标为通过。

### UDP 443 与后续优化建议

1. 本次保留 UDP 443 行为，只修正“能防广告绕过”的过度表述。若没有 QUIC 故障，后续可评估移除全局拦截；如某服务确实异常，优先缩小到该服务的 UDP 443，避免影响其他 QUIC/实时通信。先在单台设备比较播放、下载和通话，再扩展部署。
2. QX 的 `udp_drop_list=443` 是全局端口开关，不能照搬 YAML 的逐域名例外；Private Relay 场景继续保持注释。节点不支持 UDP 时仍受 `fallback_udp_policy=reject` 限制。
3. 金融会话期间优先选择具体节点，不使用跨地区自动切换；Intercom 使用手选主流，不能自动跟随每个业务的不同出口。
4. 后续按连接日志逐步收窄共享基础设施域名（例如 storage.googleapis.com、auth0.com、sentry.io），避免把其他应用一并分流；控制面与媒体出口分离造成服务异常时，先让该服务两部分使用同一出口复测。
5. 私人文件继续本地保存，无需因本次检查更换凭证。Mihomo 控制接口仍使用现有设置；桌面无需局域网控制时建议改为回环监听，路由器需要远程控制时应结合访问限制和强密码。

# Proxy-Conf | Clash (Mihomo) / Stash & Quantumult X 多端同步分流配置

本项目维护一套 **Clash (Mihomo / Clash Verge / OpenClash)**、**Stash (iOS / macOS)** 与 **Quantumult X** 多端共享分流目标的配置与规则集。Clash 与 Stash 的主规则逐条同步；QX 保留自身 DNS、UDP 和策略组实现，不能将三端运行行为视为完全一致。

核心针对 **全球 AI 访问与验证**、**美区 Apple 生态与国内满速直连兼顾**、**国际数字银行出口管理** 以及 **流媒体/社媒「控制面与数据面分离」** 四大场景进行了深度定制与优化。

---

## 📁 仓库文件说明

### 1. Clash / Mihomo / Stash 配置文件与规则集

| 文件名                                         | 类型        | 对应策略组 | 说明                                                                                                                                                                                                                                                                                                                                                              |
| :--------------------------------------------- | :---------- | :--------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [`clash.yaml`](./clash.yaml)                   | 主配置      | 全局       | Mihomo (Clash Meta) 完整主配置文件。顶部含脱敏占位节点（用于通过客户端订阅校验），支持通过本地 `Merge` 或 OpenClash 覆写注入真实节点；内置 Fake-IP、精细化 `nameserver-policy` DoH 分流、UDP 443 按业务规则分流；纯域名与纯 IP 规则集全量采用 `.mrs` 二进制极速基数树（16 域名集 + 3 IP 集），减少文本规则解析开销。                                              |
| [`stash.yaml`](./stash.yaml)                   | 主配置      | 全局       | Stash (iOS / macOS) 远程订阅专用主配置文件（与 `clash.yaml` 规则 1:1 对齐）。针对 Stash 引擎专门适配了独立 `nameserver-policy` DoH 映射、`default-nameserver` 引导解析及自动检测组 `lazy: true`、600 秒检测间隔；远程规则集针对 Stash 定制为 `format: yaml` 基数树格式，条目加载情况以客户端检查结果为准，支持通过本地 `.stoverride`（`#!replace`）注入真实节点。 |
| [`AI.yaml`](./AI.yaml)                         | `classical` | `AI`       | 全球人工智能与核心验证分流规则集（与 `QX_AI.list` 共享主要业务条目）。涵盖 Apple Intelligence、iCloud 专用代理、主流大模型、AI 编程 Agent 及人机验证/OAuth/特性开关域名。                                                                                                                                                                                         |
| [`Finance.yaml`](./Finance.yaml)               | `classical` | `Banking`  | 国际数字银行、欧洲电子钱包、外汇券商、加密货币交易所及银行级 KYC/反欺诈组件规则集（与 `Finance.list` 保持 1:1 同步）。                                                                                                                                                                                                                                            |
| [`Private_DIRECT.yaml`](./Private_DIRECT.yaml) | `classical` | `DIRECT`   | 个人定制高优先级直连白名单。包含香港金融机构（BOCHK/HSBC HK/ZA Bank/AlipayHK 等）、常用云服务，以及 Windows/Office/Xbox/Switch 满速下载更新 CDN。                                                                                                                                                                                                                 |

### 2. Quantumult X 规则集与脚本资源

| 文件名                                       | 类型      | 对应策略组 | 说明                                                                                                                                                                                                                                                                |
| :------------------------------------------- | :-------- | :--------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| [`QX_AI.list`](./QX_AI.list)                 | `filter`  | `AI`       | Quantumult X 全球人工智能与核心服务分流规则集（与 `AI.yaml` 共享主要业务条目，存在端别差异），最高优先级置顶防截胡与防去广告误杀。                                                                                                                                  |
| [`Private.list`](./Private.list)             | `filter`  | 多策略组   | Quantumult X 个人核心定制总表（高优先级 `inserted-resource`）。集成海外加密 DNS、Wi-Fi Calling、防欺诈指纹保护、Apple 双策略组精细分流、全球主流服务「控制面 + 数据面」分离规则及直连白名单（与 YAML 端共享主要业务分流目标；远程通用规则来源及顺序存在端别差异）。 |
| [`Finance.list`](./Finance.list)             | `filter`  | `Banking`  | Quantumult X 国际数字银行、欧洲电子钱包与加密货币分流规则集（与 `Finance.yaml` 1:1 同步）。                                                                                                                                                                         |
| [`AllInOne.conf`](./AllInOne.conf)           | `rewrite` | -          | Quantumult X 综合重写（Rewrite）、重定向与去广告规则合集。                                                                                                                                                                                                          |
| [`resource-parser.js`](./resource-parser.js) | `script`  | -          | 资源解析器脚本（©Shawn），支持多格式节点订阅解析、筛选重命名及跨平台分流/重写规则转换。                                                                                                                                                                             |

---

## 🏗️ 核心分流架构设计

### 1. 控制面与数据面分离（锁定位 + 省流量 + 跑满速）

针对 YouTube、Netflix、Telegram、GitHub、Google、X (Twitter)、Instagram、Facebook、Reddit、Discord、TikTok、Amazon、Adobe 等全球高频服务，采用**控制面与数据面剥离**设计：

- **控制面（主站 / 登录鉴权 / API / 地区解锁与趋势定位）** ➔ 走 `🚀 手选主流` 或专属策略组（如 `Google`），可手动固定节点以减少出口变化；下层自动测速组仍可能换节点。
- **数据面（视频流 / 音频流 / 大图 CDN / 软件安装包与更新包）** ➔ 前置剥离至 `GMedia` 大流量媒体组（如 `googlevideo.com`、`nflxvideo.net`、`twimg.com`、`cdninstagram.com`、`fbcdn.net`、`githubusercontent.com`、`dl.google.com` 等），可使用大带宽/低倍率高速节点，避免挤占高价值或自建节点带宽。

### 2. 苹果生态分流

将国内基础服务和海外服务分组管理；实际可用性还取决于账户、地区、设备和服务端限制：

- **`AppleAI`** 负责 Apple Intelligence、私有云计算（PCC）、Siri、听写与搜索。**`PrivateRelay`** 单独处理引擎捕获并识别的 iCloud 专用代理连接。两组首选都是 `🇺🇸 美国-3`，可独立选择出口，`🇺🇸 US+` 为自动测速备选，`DIRECT` 用于手动对照。[Apple 企业网络主机清单](https://support.apple.com/zh-cn/101555)
- 系统是否启用 Private Relay 取决于设备、网络和 VPN 路由。确认策略命中需要连接日志，系统状态需另外查看。[Apple VPN 与隐私说明](https://www.apple.com/uk/legal/privacy/data/en/vpns/)
- `AI.yaml` 保留跨端共享的 Apple 条目，Clash / Stash 以专用前置规则覆盖。QX 仍使用原有策略，未随之新增这两个组。未确认归属的 Apple 关联主机继续沿原 AI 路径。
- **`AppleProxy` 策略组（美区专属服务与商店控制面）**：精准剥离 Apple News、Apple TV+ 控制面、Apple Podcasts、Stocks 以及 App Store 搜索与探索页面接口（`amp-api-edge.apps.apple.com` / `search.itunes.apple.com` 等），默认通过 `🚀 手选主流`，其首项为美国自动测速组，出口可能变化（Apple TV+ 纯视频流 `hls-svod.itunes.apple.com` 剥离至 `GMedia`）。
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

- **Clash / Stash**：保留国内默认 DoH 和 Apple/CDN 国内解析，AppleAI、Private Relay、AI 和海外 geosite 使用 Cloudflare/Google DoH。AppleAI 新增 `cp4.cloudflare.com`、`guzzoni.apple.com` 和 `+.smoot.apple.com` 定向解析。Clash 使用 `respect-rules`；Stash 保留 `follow-rule`、独立映射及引导 DNS。[Stash 官方 DNS 文档](https://stash.wiki/en/features/dns-server)
- **QX 默认解析**：使用阿里、腾讯 DoH；启用 `no-system` / `no-ipv6`。移除配置 DoH 后不会充当默认备用的普通 DNS 条目。Apple、微软和游戏 CDN 的定向 DNS 改为阿里 DoH，补齐根域名和子域名映射。
- **QX 海外定向解析**：从 QX_AI、Finance、Private 中属于 AI / Banking 的明确域名及手选主流下的五个 Intercom 域名生成 Cloudflare DoH 映射，包括 Private Relay、Apple Intelligence 和 `.ai`。根域名与子域名分别声明，同一上游的重复父子域名会合并。
- **边界**：QX 的关键词规则、远程通用规则及 geosite 不会被自动转换为 DNS 通配规则；未显式覆盖的域名仍用默认 DoH。代理连接通常由节点端解析目标域名，不能把本地 DNS 查询结果当作最终代理目标 IP。QX 内置 DNS 请求不保证服从普通代理规则，因此不承诺海外 DoH 自动通过节点访问；需要在实际 Wi-Fi/蜂窝网络验证可达性。[QX 官方示例](https://github.com/crossutility/Quantumult-X/blob/master/sample.conf)
- **维护**：运行 `python3 proxy-conf/scripts/sync_qx_dns.py` 更新私人 QX 配置中的标记区块；不要手工修改生成区块。脚本不输出订阅、节点凭证或证书。

---

## 🎯 策略组架构一览

| 策略组名称                                                | 类型       | 核心用途说明                                                                                           |
| :-------------------------------------------------------- | :--------- | :----------------------------------------------------------------------------------------------------- |
| `🚀 手选主流`                                             | `select`   | **核心主策略组**。聚合各地区自动测速组与自建节点组，供主流海外控制面与定位服务调用（建议默认选美国）。 |
| `🏎️ 速度优选`                                             | `url-test` | 跨地区全节点自动测速优选，筛选最低延迟可用节点。                                                       |
| `🚑 故障转移`                                             | `fallback` | 按预设地区优先级顺序进行可用性健康检查与自动容灾切换。                                                 |
| `🎯 手选节点`                                             | `select`   | 手动选择冷门地区或特定单节点（如英国 Wi-Fi Calling 等特定需求）。                                      |
| `AI`                                                      | `select`   | ChatGPT、Gemini 等 AI 服务与关联验证域名。                                                             |
| `AppleAI`                                                 | `select`   | Apple Intelligence、PCC、Siri 与搜索，首选 `🇺🇸 美国-3`。                                               |
| `PrivateRelay`                                            | `select`   | iCloud Private Relay 相关连接。                                                                        |
| `GMedia`                                                  | `select`   | **大流量流媒体与 CDN 数据面组**。承接视频流、音频流、社媒大图与软件安装包下载。                        |
| `Banking`                                                 | `select`   | 首选 CH+；组内直接列出三个自建瑞士节点和 KKK 的欧洲节点。                                              |
| `PayPal`                                                  | `select`   | 首选 US+；组内直接列出三个自建美国节点和 KKK 的美、德、英、日、港、菲节点。                            |
| `AppleProxy`                                              | `select`   | Apple 美区专属服务（News / TV+ 控制面 / 美区商店搜索）策略组。                                         |
| `Apple`                                                   | `select`   | Apple 国内高速保障服务（系统更新 / App 下载 / iCloud / Music）策略组，首选项为 `DIRECT`。              |
| `Google`                                                  | `select`   | Google 搜索、YouTube 主站控制面与 API 服务策略组。                                                     |
| `Microsoft`                                               | `select`   | 微软国际服务与账户策略组（系统更新与 Office CDN 已前置直连）。                                         |
| `OneDrive`                                                | `select`   | OneDrive 云盘同步专属策略组。                                                                          |
| `Game`                                                    | `select`   | 任天堂 Switch 与 Xbox 联机大厅策略组（游戏本体下载 CDN 已前置直连）。                                  |
| `Global`                                                  | `select`   | 其余未命中细分规则的海外流量兜底策略组。                                                               |
| `🇺🇸 US+` / `🇨🇭 CH+`                                       | `url-test` | 美国 / 瑞士自建节点自动测速组（可能切换节点）。                                                        |
| `🇺🇸 US` / `🇭🇰 HK` / `🇯🇵 JP` / `🇼🇸 TW` / `🇸🇬 SG` / `🇰🇷 KR` | `url-test` | 机场订阅对应国家/地区正则筛选自动测速组（自动剔除免费/试用/失联/高倍率节点）。                         |
| `🏴‍☠️ CF`                                                   | `url-test` | 优选备份节点自动测速组。                                                                               |

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
     - {
         name: 🇺🇸 美国-1,
         server: your.us1.domain,
         port: 443,
         type: vmess,
         uuid: your-uuid,
         alterId: 0,
         cipher: auto,
         udp: true,
         tls: true,
         client-fingerprint: chrome,
         network: ws,
         ws-opts: { path: /us, headers: { Host: your.us1.domain } },
       }
     - {
         name: 🇺🇸 美国-2,
         server: your.us2.domain,
         port: 443,
         type: vmess,
         uuid: your-uuid,
         alterId: 0,
         cipher: auto,
         udp: true,
         tls: true,
         client-fingerprint: chrome,
         network: ws,
         ws-opts: { path: /us, headers: { Host: your.us2.domain } },
       }
     - {
         name: 🇺🇸 美国-3,
         server: your.us3.domain,
         port: 443,
         type: vmess,
         uuid: your-uuid,
         alterId: 0,
         cipher: auto,
         udp: true,
         tls: true,
         client-fingerprint: chrome,
         network: ws,
         ws-opts: { path: /us, headers: { Host: your.us3.domain } },
       }
     - {
         name: 🇨🇭 瑞士-1,
         server: your.ch1.domain,
         port: 443,
         type: vmess,
         uuid: your-uuid,
         alterId: 0,
         cipher: auto,
         udp: true,
         tls: true,
         client-fingerprint: chrome,
         network: ws,
         ws-opts: { path: /ch, headers: { Host: your.ch1.domain } },
       }
     - {
         name: 🇨🇭 瑞士-2,
         server: your.ch2.domain,
         port: 443,
         type: vmess,
         uuid: your-uuid,
         alterId: 0,
         cipher: auto,
         udp: true,
         tls: true,
         client-fingerprint: chrome,
         network: ws,
         ws-opts: { path: /ch, headers: { Host: your.ch2.domain } },
       }
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
       - {
           name: 🇺🇸 美国-1,
           server: your.us1.domain,
           port: 443,
           type: vmess,
           uuid: your-uuid,
           alterId: 0,
           cipher: auto,
           udp: true,
           tls: true,
           network: ws,
           ws-opts: { path: /us, headers: { Host: your.us1.domain } },
         }
       - {
           name: 🇺🇸 美国-2,
           server: your.us2.domain,
           port: 443,
           type: vmess,
           uuid: your-uuid,
           alterId: 0,
           cipher: auto,
           udp: true,
           tls: true,
           network: ws,
           ws-opts: { path: /us, headers: { Host: your.us2.domain } },
         }
       - {
           name: 🇺🇸 美国-3,
           server: your.us3.domain,
           port: 443,
           type: vmess,
           uuid: your-uuid,
           alterId: 0,
           cipher: auto,
           udp: true,
           tls: true,
           network: ws,
           ws-opts: { path: /us, headers: { Host: your.us3.domain } },
         }
       - {
           name: 🇨🇭 瑞士-1,
           server: your.ch1.domain,
           port: 443,
           type: vmess,
           uuid: your-uuid,
           alterId: 0,
           cipher: auto,
           udp: true,
           tls: true,
           network: ws,
           ws-opts: { path: /ch, headers: { Host: your.ch1.domain } },
         }
       - {
           name: 🇨🇭 瑞士-2,
           server: your.ch2.domain,
           port: 443,
           type: vmess,
           uuid: your-uuid,
           alterId: 0,
           cipher: auto,
           udp: true,
           tls: true,
           network: ws,
           ws-opts: { path: /ch, headers: { Host: your.ch2.domain } },
         }
     ```

   - **验证生效**：
     - 在 Stash 首页启动连接，进入「规则提供者 (Rule Providers)」页面点击刷新，确认全部 24 个规则集均正常显示非零条目数量。

---

### 四、Quantumult X 使用方法

私人完整配置为工作区根目录的 `QX_Pro.conf`，不发布到本仓库。Intercom 规则直接引用现有的 `🚀 手选主流`，无需新增策略组。

Clash / Stash 更新后请检查保存的策略选择，尤其是 `AppleAI`、`PrivateRelay` 和 `Apple`。首项只定义初始选择，客户端可能恢复先前保存的手动选择。

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
- `Clash_Pro.yaml` 保留真实节点与订阅；作为本地完整配置备份，更新状态与公开 `clash.yaml` 分开维护。远程规则集内容仍由对应文件维护，并非离线内嵌快照。
- `stash.yaml` 的主规则和业务策略与 Clash 同步，但保留 flow-style YAML、独立 DNS 映射、`follow-rule`、引导 DNS、600 秒 lazy 检测，以及 YAML 格式规则提供者；不直接用 Mihomo 配置覆盖它。
- 修改共享业务规则时核对 `AI.yaml` / `QX_AI.list`、`Finance.yaml` / `Finance.list` 和 `Private.list` 的策略与优先级。Intercom 已由 QX 的 `Private.list` 路由到手选主流，两份 YAML 主配置有相同的前置规则，可覆盖尚未刷新的 AgAI 缓存。
- Mihomo 的纯域名/IP 提供者保留 MRS；Stash 保留 domain/ipcidr + YAML；复合自定义规则保留 classical + YAML。
- Spotify 的显式 CDN 规则走 `DIRECT`，其余 Spotify 规则集走手选主流。QX 与 Clash / Stash 保留各自的 GMedia 默认策略。

### UDP 443

Clash / Stash 的 UDP 443 由 AppleAI、PrivateRelay、AI、媒体、广告、国内直连和通用兜底规则依次分类。已识别的广告流量仍按广告规则拒绝。UDP 转发取决于节点能力及 TUN、透明代理或 Network Extension 是否捕获流量。QX 保持自身的 UDP 配置。

### 静态验证与上线检查

在公开仓库根目录运行（需要 Ruby / Psych）：

```sh
ruby scripts/validate_configs.rb
git diff --check
```

本次实测每端有 221 条主规则、26 个策略组、24 个规则提供者。脚本检查主规则同序、组引用、循环、DNS 定向映射和本地域名分流。默认使用最小广告样例，传入下载的 `AdvertisingLite.yaml` 可改用实际条目。Mihomo v1.19.32 已在临时目录通过 `-t`，并以本地模拟上游验证 DNS 策略选择。Stash 原生导入、OpenClash 生效配置、iPhone 系统功能和真实节点 UDP 转发仍需实机验证。

控制器配置保留公开占位值。部署时需核对实际监听范围、路由器防火墙、仪表盘依赖及本地私有密钥覆写，控制接口安全整改待完成。

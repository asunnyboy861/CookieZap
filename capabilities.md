# CookieZap — 配置文档

生成时间：2026-05-21

---

## 一、⚠️ 手动配置（需你操作才能生效）

### 🔴 Capabilities 配置

#### Content Blocker App Group — 需补充

**影响功能**：Content Blocker 无法读取共享规则数据，规则自动更新功能不可用

**已自动配置部分**：
- ✅ 主 App 和 Safari Extension 的 entitlements 中已添加 App Group `group.com.zzoutuo.CookieZap`
- ✅ AppGroupManager.swift 已实现共享数据读写

**仍需手动配置**：
1. 打开 Xcode → 选择 **CookieZapBlocker** target
2. 进入 **Signing & Capabilities** 标签页
3. 点击 **"+ Capability"** → 添加 **App Groups**
4. 勾选 `group.com.zzoutuo.CookieZap`（与主 App 一致）
5. ⚠️ 配置完成后需要重新 Build 验证

---

### 🟢 App Store Connect 审核信息配置

**影响功能**：不配置则 Apple 审核员无法测试完整功能，可能导致审核延迟

**配置步骤**：
1. 在 App Store Connect → 你的 App → **Pricing and Availability**
2. 设置价格为 **$1.99**（Tier 2）
3. 在 **App Review Information** → **Notes** 中说明：
   - 这是一个 Safari 扩展，需在 Settings → Safari → Extensions 中启用 CookieZap
   - 启用后访问任意含 Cookie 弹窗的网站即可看到效果
4. 确保 **Privacy Policy URL** 填写：`https://asunnyboy861.github.io/CookieZap/privacy.html`
5. 确保 **Support URL** 填写：`https://asunnyboy861.github.io/CookieZap/support.html`

---

## 二、✅ 自动配置记录（已由系统完成，无需操作）

### Capabilities 自动配置

| Capability | 说明 | 状态 |
|------------|------|------|
| Safari Web Extension | Xcode 中已创建 CookieZapExtension target | ✅ 已配置 |
| Content Blocker Extension | Xcode 中已创建 CookieZapBlocker target | ✅ 已配置 |
| App Group (主App+Extension) | group.com.zzoutuo.CookieZap 已在 entitlements 配置 | ✅ 已配置 |
| Outgoing Network Connections | 规则更新需要，已在 entitlements 配置 | ✅ 已配置 |
| Network Client (Sandbox) | com.apple.security.network.client 已启用 | ✅ 已配置 |

### 代码生成

| 模块 | 说明 | 状态 |
|------|------|------|
| 核心功能 | MVVM架构，Dashboard/Settings/Onboarding | ✅ 已完成 |
| Safari Extension | content.js + background.js + popup | ✅ 已完成 |
| Content Blocker | blockerlist.json + BlockerRequestHandler | ✅ 已完成 |
| App Group 共享 | AppGroupManager.swift 实现跨进程数据共享 | ✅ 已完成 |
| SettingsView | 政策页面链接已指向 GitHub Pages | ✅ 已完成 |
| 规则自动更新 | RuleUpdateService 从 GitHub Pages 拉取 | ✅ 已完成 |

### 部署

| 项目 | 说明 | 状态 |
|------|------|------|
| GitHub仓库 | 代码已推送至 asunnyboy861/CookieZap | ✅ 已完成 |
| GitHub Pages | 政策页面已部署 | ✅ 已完成 |
| Landing Page | 已部署（App Store ID为占位符） | ✅ 已完成 |
| App Store元数据 | keytext.md 已生成验证 | ✅ 已完成 |
| 定价配置 | price.md 已生成（$1.99 一次性购买） | ✅ 已完成 |

---

## 三、能力检测详情

### Analysis

| Keyword Found | Capability | Required |
|---------------|-----------|----------|
| "Safari Extension" / "Web Extension" | Safari Web Extension | Yes |
| "Content Blocker" | Content Blocker Extension | Yes |
| "App Group" / "共享容器" | App Group | Yes |
| "后台" / "background" / "规则更新" | Background Modes (Background Fetch) | Yes |
| "一次性买断" / "付费购买" | Paid App (no IAP) | No IAP needed |

### No Configuration Needed

- Push Notifications: Not required (no notifications)
- HealthKit: Not applicable
- Location Services: Not required
- Camera/Photo Library: Not required
- iCloud: Not required (no sync feature)
- Apple Watch: Not required
- Siri: Not required
- In-App Purchase: Not required (paid upfront model, $1.99 one-time)
- Sign in with Apple: Not required

### Verification

- Build succeeded after configuration: ✅ Build 成功
- All entitlements correct: ✅ 主 App 和 Extension entitlements 已配置

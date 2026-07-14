# 提醒事项 — ReminderClone (iOS)

仿 Apple 提醒事项的 iOS 待办 App。纯 SwiftUI + SwiftData，本地存储，不上架。

## 编译方式

### 方案 A：GitHub Actions 远程编译（推荐）

#### 第一步：创建 GitHub 仓库

1. 打开 [github.com](https://github.com)，登录或注册
2. 点 **+** → **New repository**
3. 填仓库名 `ReminderClone` → **Create repository**
4. 在 Windows 上打开终端（PowerShell），执行：

```bash
# 安装 Git（如果没有）
winget install Git.Git

# 下载代码到本地
cd Desktop
git clone https://github.com/<你的用户名>/ReminderClone.git
cd ReminderClone
```

然后把 `/home/wsh03/juese/ReminderClone/` 里的所有文件复制进去。

#### 第二步：设置 GitHub Secrets（签名信息）

去 GitHub 仓库 → **Settings** → **Secrets and variables** → **Actions** → 添加以下 3 个：

| Secret 名称 | 值说明 |
|-------------|--------|
| `APPLE_ID` | 你的 Apple ID 邮箱（如 `xxx@icloud.com`） |
| `APPLE_ID_PASSWORD` | **App 专用密码**（不是登录密码！） |
| `DEV_TEAM_ID` | 你的 Team ID（后文教你怎么查） |

> **App 专用密码怎么生成？**
> 1. 登录 [appleid.apple.com](https://appleid.apple.com)
> 2. **App-Specific Passwords** → **Generate password**
> 3. 名称填 `GitHub Actions` → 复制生成的密码

> **Team ID 在哪查？**
> 1. 登录 [developer.apple.com](https://developer.apple.com)
> 2. **Account** → **Membership**
> 3. **Team ID** 那一串字符（免费账号也有）

#### 第三步：推送代码，触发编译

```bash
git add .
git commit -m "Initial commit"
git push
```

#### 第四步：下载 .ipa

1. 去 GitHub 仓库 → **Actions** 标签
2. 点正在运行的 `Build iOS IPA` 任务
3. 等十几分钟，编译完成后
4. 在 **Artifacts** 区下载 `ReminderClone-IPA.zip`
5. 解压得到 `.ipa` 文件

#### 第五步：安装到 iPhone

在 Windows 上装 **AltStore**：

1. 下载 [AltStore](https://altstore.io)（Windows 版）
2. 用数据线连 iPhone 到电脑
3. AltStore → 安装 AltServer → 输入 Apple ID
4. 把 `.ipa` 文件拖进 AltStore → 自动安装到 iPhone

> 免费 Apple ID 每 7 天要续签一次，AltStore 支持 Wi-Fi 自动续签。

---

### 方案 B：用 Mac 直接编译（如果有 Mac）

```bash
cd ReminderClone
brew install xcodegen
xcodegen generate      # 生成 .xcodeproj
open ReminderClone.xcodeproj
```

然后在 Xcode 里选自己的 iPhone -> Cmd+R 运行。

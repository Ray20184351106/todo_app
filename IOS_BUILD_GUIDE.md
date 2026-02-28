# iOS APP 构建指南

本指南说明如何使用 GitHub Actions 免费构建 iOS APP，无需付费开发者账号。

---

## 📋 前置要求

| 项目 | 要求 |
|------|------|
| GitHub 账号 | ✅ 需要（免费） |
| Apple ID | ✅ 需要（免费，用于签名） |
| Windows 电脑 | ✅ 需要 |
| 数据线 | ✅ 需要（连接 iPhone） |
| Mac 电脑 | ❌ 不需要 |
| 开发者账号 | ❌ 不需要 |

---

## 🚀 快速开始

### 第一步：推送代码到 GitHub

```bash
git add .
git commit -m "Add iOS build workflow"
git push
```

### 第二步：触发构建

1. 访问你的 GitHub 仓库
2. 点击 **Actions** 标签页
3. 选择 **Build iOS IPA** 工作流
4. 点击 **Run workflow** → **Run workflow**

### 第三步：等待构建完成

- 构建时间约 5-10 分钟
- 完成后会出现 ✅ 绿色勾
- 下载 IPA 文件（在 Artifacts 区域）

---

## 📱 安装到 iPhone

### 方法一：Sideloadly（推荐，Windows 可用）

1. **下载 Sideloadly**
   - 官网：https://sideloadly.io
   - 免费软件，支持 Windows

2. **连接 iPhone**
   - 用数据线连接电脑
   - iPhone 上信任此电脑

3. **安装 APP**
   - 打开 Sideloadly
   - 选择下载的 IPA 文件
   - 选择你的 iPhone
   - 输入 Apple ID 和密码（仅用于生成签名）
   - 等待安装完成

4. **信任开发者证书**
   - iPhone: 设置 → 通用 → VPN 与设备管理
   - 找到你的 Apple ID，点击信任

### 方法二：AltStore（需要 Mac）

1. 下载 AltStore：https://altstore.io
2. 安装 AltStore 到 iPhone
3. 用 AltStore 打开 IPA 文件

---

## ⏰ 关于有效期

| 签名类型 | 有效期 |
|---------|--------|
| 免费签名 | 7 天 |
| 到期后 | 重新安装即可 |

**建议**：收藏此页面，到期后重新下载最新 IPA 安装。

---

## 🔧 常见问题

### Q1: 提示"无法验证开发者"？
A: iPhone 设置 → 通用 → VPN 与设备管理 → 信任证书

### Q2: 7 天后 APP 打不开？
A: 免费签名到期，重新安装即可

### Q3: 构建失败怎么办？
A: 检查 GitHub Actions 日志，通常是网络问题，重新运行即可

### Q4: 可以给女朋友的手机安装吗？
A: 可以！用她的 Apple ID 签名安装即可

---

## 📁 文件位置

```
.github/workflows/ios.yml     # GitHub Actions 配置
```

---

## 🎉 完成！

现在你可以在不需要 Mac 和付费开发者账号的情况下，
自己构建 iOS APP 并安装到 iPhone 上使用！

**有问题？** 查看 GitHub Actions 的构建日志获取详细信息。

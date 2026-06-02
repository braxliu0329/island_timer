# IslandTimer

IslandTimer 是一款面向 macOS 的灵动岛（Notch）风格番茄钟应用：将计时信息与交互尽量“收纳”到屏幕顶部刘海区域附近，以更低打扰的方式完成专注与休息切换。应用以菜单栏形态运行，并提供计时器与备忘两种模式。

仓库地址：<https://github.com/braxliu0329/island_timer>

## 功能特性

- 灵动岛式悬停交互：窗口折叠时贴合刘海区域，鼠标悬停自动展开，移出自动折叠
- 番茄钟计时：支持开始、暂停、重置；专注/休息两种阶段
- 备忘模式：在同一窗口内切换为可编辑文本，内容自动保存
- 设置面板：自定义专注/休息时长；支持屏幕共享/录屏时隐藏岛屿窗口
- 统计面板：展示连续专注天数、累计完成次数与近期活动

## 技术栈

- Swift 5.9+ / Swift Package Manager
- SwiftUI：界面与动画
- AppKit：`NSPanel`（无边框置顶窗口）、`NSStatusItem`（菜单栏入口）
- Combine：状态绑定与持久化触发

## 环境要求

- macOS 13.0 或更高版本
- Xcode 15+ 或安装 Command Line Tools（用于 Swift 5.9 工具链）
- 建议在带刘海屏的 MacBook 上使用以获得最佳视觉效果（非必需）

## 快速上手

### 方式一：Swift Package Manager 直接运行

```bash
git clone https://github.com/braxliu0329/island_timer.git
cd island_timer
swift run IslandTimer
```

如需 Release 构建：

```bash
swift run -c release IslandTimer
```

### 方式二：使用 Xcode 打开

1. 使用 Xcode 打开 `Package.swift`
2. 选择可执行目标 `IslandTimer` 并运行

## 使用指南

### 菜单栏入口

- 启动后，菜单栏会出现应用图标
- 点击图标可打开菜单，并可在「计时器 / 备忘」之间切换
- 菜单中可打开「设置…」「统计…」窗口

### 计时器模式

- 折叠态：仅显示精简信息，尽量不占用屏幕空间
- 展开态：可进行开始、暂停、重置等操作

### 备忘模式

- 展开后可直接编辑文本内容
- 文本自动持久化保存，重启应用后仍会保留

### 设置与屏幕共享

- 在「设置…」中可调整专注/休息时长
- 可开启「隐藏岛屿窗口」用于屏幕共享或录屏场景

## 数据与隐私

- 计时配置、统计数据与备忘内容存储在本机 `UserDefaults` 中
- 本项目不包含联网同步逻辑

## 贡献指南

欢迎 Issue 与 Pull Request：

1. Fork 本仓库并从 `main` 创建分支
2. 保持改动聚焦（一个 PR 尽量只做一类事情）
3. 确保本地可编译运行（至少通过 `swift build` / `swift run`）
4. 在 PR 中清晰描述变更动机、实现方式与验证方式

问题反馈：<https://github.com/braxliu0329/island_timer/issues>

## 许可证

本项目采用 MIT License，详见 [LICENSE](LICENSE)。

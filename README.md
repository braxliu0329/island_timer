# Island Timer 🏝️

Island Timer 是一款专为 macOS 设计的灵动岛风格番茄钟应用。它巧妙地利用了 MacBook 的刘海屏（Notch）区域，提供了一种优雅且非侵入性的计时体验。

## ✨ 特性

- **灵动岛交互**：完美的 Notch 集成，计时器在刘海区域展开和收起，动画平滑自然。
- **多种计时模式**：内置「专注模式」和「休息模式」。
- **智能展开**：
  - **折叠态**：与刘海融为一体，不占用屏幕空间。
  - **运行态**：显示精简的时间进度。
  - **悬停态/展开态**：鼠标悬停展开完整控制面板，支持开始、暂停、重置、跳过和切换模式。
- **个性化设置**：支持自定义专注时长和休息时长。
- **每日统计**：自动记录您每天的专注/休息次数和总时长。
- **系统集成**：纯菜单栏应用体验，左键或右键点击菜单栏图标即可快速唤出「设置」、「统计」及退出应用。
- **声音提醒**：倒计时结束时会自动播放系统提示音提醒。

## 🚀 快速开始

### 环境要求
- macOS 13.0 或更高版本
- 建议在带有刘海屏的 MacBook (M1/M2/M3 系列) 上使用，以获得最佳视觉效果。

### 安装与运行
1. 克隆本项目：
   ```bash
   git clone https://github.com/braxliu/island_timer.git
   ```
2. 进入项目目录：
   ```bash
   cd island_timer
   ```
3. 使用 Swift Package Manager 运行：
   ```bash
   swift run IslandTimer
   ```

## 🛠️ 技术栈
- **Swift 5.9+**
- **SwiftUI**: 用于构建灵动岛 UI 和交互动画。
- **AppKit (NSPanel, NSStatusItem)**: 用于实现窗口的置顶、跨桌面显示、精确的刘海位置定位以及菜单栏图标管理。
- **Combine**: 用于计时器逻辑与 UI 的响应式绑定。

## 📂 项目结构
- `IslandTimerApp.swift`: 应用入口，配置菜单栏状态项及窗口管理。
- `IslandWindow.swift`: 自定义 `NSPanel` 窗口，处理层级、透明度及交互区域。
- `IslandView.swift`: 核心 SwiftUI 视图，包含灵动岛各种状态下的 UI 逻辑。
- `TimerManager.swift`: 计时器核心逻辑，处理时间倒计时、状态转换及每日统计数据的持久化。
- `DisplaySettings.swift`: 管理灵动岛的尺寸及展开状态。
- `SettingsView.swift`: 自定义时长设置面板。
- `StatisticsView.swift`: 每日专注与休息统计数据展示面板。

## 📝 路线图 (Roadmap)
- [x] 添加倒计时结束后的音效提醒。
- [x] 支持自定义工作/休息时长。
- [x] 每日历史统计及名人名言激励功能。
- [ ] 增加圆角调整。
- [ ] 支持长期历史数据图表展示。

## 📄 开源协议
本项目采用 [MIT License](LICENSE) 开源。

---
*欢迎提交 Issue 或 Pull Request 参与贡献！*

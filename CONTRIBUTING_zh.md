# 参与贡献 ContainerUI

[English Documentation](CONTRIBUTING.md)

感谢你有兴趣参与贡献！ContainerUI 是 `container` CLI 运行时的原生 macOS 图形管理工具，基于 SwiftUI + MVVM 构建。

## 快速上手

```bash
git clone git@github.com:SterbenSQ/container-ui.git
cd container-ui
swift build
swift run
```

### 环境要求
- macOS 26+
- Xcode 16.0+（或 Swift 6.0 工具链）
- [`container` CLI](https://github.com/apple/container) 已安装至 `/usr/local/bin/container`

## 项目架构

```
CLI (/usr/local/bin/container)
        ↑ Process
ContainerService (actor)          ← 服务层
        ↑ async/await
ViewModels (@MainActor)           ← 业务逻辑
        ↑ @Published
Views (SwiftUI)                   ← 界面层
```

- **零外部依赖** — 纯 Swift + SPM
- **MVVM**：Models 为 `Codable`，ViewModels 为 `@MainActor ObservableObject`，Views 为纯 SwiftUI
- **Actor 服务**：`ContainerService` 基于 actor 保证子进程 I/O 线程安全
- **环境注入**：`LocalizationManager` 和 `DashboardViewModel` 通过 `@EnvironmentObject` 注入

## 代码风格

- 命名、缩进（4 空格）与注释风格与现有代码保持一致
- 使用 `// MARK: -` 分隔逻辑区块
- ViewModels 放 `ViewModels/`，Views 放 `Views/`，Models 放 `Models/`，Services 放 `Services/`
- 国际化字符串：同时在 `en.json` 和 `zh.json` 中添加 key，通过 `l10n["key"]` 或 `l10n.format("key", [...])` 访问

## 添加新功能

1. **服务层**：如需要，在 `ContainerService` 中添加 CLI 封装方法
2. **模型层**：为新的 JSON 响应创建 `Codable` 结构体
3. **ViewModel**：创建 `@MainActor ObservableObject`，使用 `@Published` 管理状态
4. **View**：构建 SwiftUI 视图，通过 `@StateObject` 注入 ViewModel
5. **国际化**：将所有面向用户的字符串添加到 `en.json` 和 `zh.json`
6. **接入**：通过导航或 sheet 在父视图中接入新页面

## Bug 报告

提交 Issue 时请包含：
- macOS 版本
- `container --version` 输出
- 复现步骤
- 预期行为与实际行为

## Pull Request

1. 从 `master` 创建功能分支
2. 保持改动聚焦 — 每个 PR 只包含一个功能或修复
3. 提交前确保 `swift build` 通过
4. 如果新增或修改了 UI 文案，请同时更新 `en.json` 和 `zh.json`

## 许可证

参与贡献即表示你同意将贡献内容以 [MIT 许可证](LICENSE) 授权。

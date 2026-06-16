# Contributing to ContainerUI

[中文文档](CONTRIBUTING_zh.md)

Thanks for your interest in contributing! ContainerUI is a native macOS GUI for the `container` CLI runtime, built with SwiftUI + MVVM.

## Getting Started

```bash
git clone git@github.com:SterbenSQ/container-ui.git
cd container-ui
swift build
swift run
```

### Prerequisites
- macOS 26+
- Xcode 16.0+ (or Swift 6.0 toolchain)
- [`container` CLI](https://github.com/apple/container) installed at `/usr/local/bin/container`

## Project Architecture

```
CLI (/usr/local/bin/container)
        ↑ Process
ContainerService (actor)          ← Service layer
        ↑ async/await
ViewModels (@MainActor)           ← Business logic
        ↑ @Published
Views (SwiftUI)                   ← UI layer
```

- **Zero external dependencies** — pure Swift + SPM
- **MVVM**: Models are `Codable`, ViewModels are `@MainActor ObservableObject`, Views are pure SwiftUI
- **Actor service**: `ContainerService` guarantees thread-safe subprocess I/O
- **Environment injection**: `LocalizationManager` and `DashboardViewModel` are `@EnvironmentObject`

## Code Style

- Match the existing code in naming, indentation (4 spaces), and comment style
- Use `// MARK: -` to separate logical sections
- ViewModels go in `ViewModels/`, Views in `Views/`, Models in `Models/`, Services in `Services/`
- Localized strings: add keys to both `en.json` and `zh.json`, access via `l10n["key"]` or `l10n.format("key", [...])`

## Adding a Feature

1. **Service**: Add the CLI wrapper method to `ContainerService` if needed
2. **Models**: Create `Codable` structs for any new JSON responses
3. **ViewModel**: Create an `@MainActor ObservableObject` with `@Published` state
4. **View**: Build the SwiftUI view, inject ViewModel via `@StateObject`
5. **Localization**: Add all user-facing strings to `en.json` and `zh.json`
6. **Wire up**: Connect the new view via navigation or sheet in the parent

## Bug Reports

When filing an issue, include:
- macOS version
- `container --version` output
- Steps to reproduce
- Expected vs actual behavior

## Pull Requests

1. Create a feature branch from `master`
2. Keep changes focused — one feature or fix per PR
3. Verify `swift build` passes before submitting
4. Update both `en.json` and `zh.json` if you add or change UI text

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).

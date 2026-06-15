# ContainerUI

ContainerUI is a native macOS desktop application that provides a graphical user interface for the **`container`** CLI runtime. Think of it as "Docker Desktop" for the Apple container ecosystem — manage containers, images, and system resources from a clean SwiftUI interface.

<p align="center">
  <img src="Resources/Assets.xcassets/AppIcon.appiconset/icon_256x256.png" alt="ContainerUI" width="128" />
</p>

## Features

### Dashboard
- System health overview with start/stop controls for the container daemon
- Disk usage breakdown (images, containers, volumes, reclaimable space)
- Container and image counts at a glance
- Version info for the API server

### Container Management
- **List & Search** — browse all containers with real-time status indicators, filter by running state, and search by name or image
- **Lifecycle Controls** — start, stop, kill, and delete containers with swipe actions and context menus
- **Detailed Inspect** — view full container configuration including ports, mounts, environment variables, labels, and network settings
- **Live Stats** — CPU, memory, I/O, and network usage with 2-second auto-refresh
- **Logs** — scrollable, monospaced log viewer for container output

### Container Creation
- Select image and assign a name
- Configure CPU cores (stepper) and memory limit
- Dynamic port mappings (host ↔ container)
- Volume mounts
- Environment variables
- Network selection
- Toggles: Rosetta emulation, SSH access, read-only rootfs

### Image Management
- **List & Search** — browse local images with platform badges, sizes, and creation dates
- **Pull** — pull images from remote registries by reference
- **Delete** — remove unused images with swipe-to-delete

### Image Building
- Select a build context directory via native file picker
- Tag the resulting image
- Watch build output in real time

### Bilingual UI
- Full English and 简体中文 localization (142 keys each)
- Instant language switching via menu bar (`⌘E` / `⌘C`) or toolbar
- Auto-detects system language on first launch

## Requirements

| Requirement | Version |
|-------------|---------|
| **macOS** | 15.0 (Sequoia) or later |
| **Swift** | 6.0 |
| **Xcode** | 16.0+ (recommended) |
| **Container CLI** | `/usr/local/bin/container` |

> **Important**: ContainerUI depends on the `container` CLI runtime being installed at `/usr/local/bin/container`. The app will display an error if the binary is not found.

## Installation

### Build from Source

```bash
# Clone the repository
git clone git@github.com:SterbenSQ/container-ui.git
cd container-ui

# Build in debug mode
swift build

# Build in release mode
swift build -c release

# Run
swift run
```

### Generate Xcode Project (optional)

```bash
swift package generate-xcodeproj
open ContainerUI.xcodeproj
```

## Architecture

ContainerUI follows the **MVVM** (Model-View-ViewModel) pattern built entirely with SwiftUI:

```
┌──────────────────────────────────────┐
│  /usr/local/bin/container (CLI)      │  ←  External runtime
└──────────────┬───────────────────────┘
               │  Process (subprocess)
┌──────────────▼───────────────────────┐
│  ContainerService (actor)            │  ←  Service layer
│  - JSON + plain text execution       │
│  - 60s timeout, temp-file based I/O  │
└──────────────┬───────────────────────┘
               │  async/await
┌──────────────▼───────────────────────┐
│  ViewModels (@MainActor Observable)  │  ←  Business logic
│  - Polling, state, error handling    │
└──────────────┬───────────────────────┘
               │  @Published / @EnvironmentObject
┌──────────────▼───────────────────────┐
│  Views (SwiftUI)                     │  ←  Presentation
│  - TabView with 4 tabs              │
│  - Reactive localization            │
└──────────────────────────────────────┘
```

### Key Design Decisions

- **Zero external dependencies** — pure Swift and SPM, no third-party packages
- **Actor-based service** — `ContainerService` is an `actor` for thread-safe subprocess execution
- **@MainActor ViewModels** — all UI state mutations happen on the main actor
- **Environment-based dependency injection** — `LocalizationManager` and `DashboardViewModel` injected at the root, available everywhere
- **Structured concurrency** — auto-refresh loops use `Task.sleep`, automatically cancelled on view disappearance
- **Typed error handling** — `ContainerError` enum with localized messages per error case

## Project Structure

```
ContainerUI/
├── Package.swift                    # SPM manifest (macOS 15+, Swift 6.0)
├── Sources/
│   └── ContainerUI/
│       ├── App.swift                # @main entry point
│       ├── ContentView.swift        # Root tab layout
│       ├── Models/                  # Codable data models
│       │   ├── ContainerModel.swift
│       │   ├── ImageModel.swift
│       │   └── SystemModel.swift
│       ├── Services/               # Business logic layer
│       │   ├── ContainerService.swift
│       │   └── LocalizationManager.swift
│       ├── ViewModels/             # Observable state objects
│       │   ├── DashboardViewModel.swift
│       │   ├── ContainerListViewModel.swift
│       │   ├── ContainerDetailViewModel.swift
│       │   ├── ContainerCreateViewModel.swift
│       │   ├── ImageListViewModel.swift
│       │   └── ImageBuildViewModel.swift
│       ├── Views/                  # SwiftUI views
│       │   ├── DashboardView.swift
│       │   ├── ContainerListView.swift
│       │   ├── ContainerRowView.swift
│       │   ├── ContainerDetailView.swift
│       │   ├── ContainerCreateView.swift
│       │   ├── ImageListView.swift
│       │   ├── ImageRowView.swift
│       │   └── ImageBuildView.swift
│       └── Resources/
│           └── localization/
│               ├── en.json         # 142 English strings
│               └── zh.json         # 142 Chinese strings
```

## Usage

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `⌘E` | Switch to English |
| `⌘C` | Switch to 简体中文 |

### Tabs

| Tab | Purpose |
|-----|---------|
| **Dashboard** | System status, disk usage, version |
| **Containers** | List, create, manage containers |
| **Images** | List, pull, delete images |
| **Build** | Build images from a directory |

## License

This project is maintained by [SterbenSQ](https://github.com/SterbenSQ). License information to be added.

# iOS

iOS 目录承载 `Now` 的 Swift 原生实现，当前采用本地 Swift Package + SwiftUI Demo 的结构：

- `Packages/NowCore`
- `Packages/NowHybrid`
- `NowSimple.xcodeproj`
- `NowSimple`

当前主线目标是在线 H5 容器可用，明确不包含离线 H5 包下载、离线模式切换，以及相关占位接口。

## 目录说明

- `Packages/NowCore`
  基础设施层，负责初始化、服务定位、文件系统、偏好存储、Keychain 加密存储、主线程和网络状态
- `Packages/NowHybrid`
  Hybrid 容器层，负责 `WKWebView`、`localx://` 本地资源、JS Bridge、Cookie 和 SwiftUI 包装
- `NowSimple`
  SwiftUI Demo 宿主，用于演示在线 URL、bundle 页面和 sandbox 页面

## 关键入口

- App 入口：
  - `NowSimple/NowSimpleApp.swift`
- Demo 状态与加载逻辑：
  - `NowSimple/HybridDemoViewModel.swift`
- Core 实现：
  - `Packages/NowCore/Sources/NowCore/NowCore.swift`
- Hybrid 实现：
  - `Packages/NowHybrid/Sources/NowHybrid/NowHybrid.swift`
- Demo 页面：
  - `NowSimple/Demo/hybrid-demo.html`

## 快速验证

```bash
swift test --package-path /Users/hanklee/Desktop/Now/iOS/Packages/NowCore
swift test --package-path /Users/hanklee/Desktop/Now/iOS/Packages/NowHybrid
xcodebuild -project /Users/hanklee/Desktop/Now/iOS/NowSimple.xcodeproj -scheme NowSimple -destination 'generic/platform=iOS' build
```

## 文档

- 已实现计划：
  - [`PLAN.md`](/Users/hanklee/Desktop/Now/iOS/PLAN.md)
- 根目录协作说明：
  - [`../AGENT.md`](/Users/hanklee/Desktop/Now/AGENT.md)

## 当前状态

- 已完成在线 URL、bundle H5、sandbox H5 的 Demo 接入
- 已完成显式注册式 JS Bridge 和默认存储 bridge
- 已有 package tests 和 `xcodebuild` 验证
- 还没有补手动点击验收记录

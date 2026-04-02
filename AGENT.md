# Now Agent Guide

## 项目目标

这个仓库用于承载 `NowCore` 和 `NowHybrid` 的跨平台原生实现，目前已经落地：

- Android：Kotlin / Android Library + Compose Demo
- iOS：Swift Package + SwiftUI Demo

当前主线目标是“在线 H5 容器可用”，不是离线包方案。后续维护时默认保持以下边界：

- 保留 `Now` / `Wilmar` 命名体系，方便和 MAUI 版本对照
- `NowCore` 负责基础设施，不承载 Hybrid 容器逻辑
- `NowHybrid` 负责 WebView、JS Bridge、本地资源加载和 Demo 宿主接入
- 不实现离线 H5 包下载、离线模式切换，也不要为它们预埋空接口

## 目录结构

- `android`
  Android 原生实现，包含 `:now:core`、`:now:hybrid` 和 `:app` Demo
- `iOS`
  iOS 原生实现，包含 `Packages/NowCore`、`Packages/NowHybrid` 和 `NowSimple` Demo App

## Android 现状

- 工程根目录：
  - `/Users/hanklee/Desktop/Now/android`
- 模块：
  - `now/core`
  - `now/hybrid`
  - `app`
- 入口：
  - `app/src/main/java/com/hankle/nowsimple/MainActivity.kt`
- 关键能力：
  - `NowCore.initialize(context)`
  - `NowHybrid.initialize(context)`
  - `WilmarHybridWebView`
  - `WilmarHybridView` Compose 包装
  - 注解式 JS Bridge
  - `NowJsBridge` 默认存储桥接

Android 验证命令：

```bash
cd /Users/hanklee/Desktop/Now/android
./gradlew :app:assembleDebug :now:core:testDebugUnitTest :now:hybrid:testDebugUnitTest
```

## iOS 现状

- 工程根目录：
  - `/Users/hanklee/Desktop/Now/iOS`
- 包：
  - `Packages/NowCore`
  - `Packages/NowHybrid`
- App 宿主：
  - `NowSimple.xcodeproj`
  - `NowSimple/NowSimpleApp.swift`
  - `NowSimple/HybridDemoViewModel.swift`
- 关键能力：
  - `NowCore.initialize(context:)`
  - `NowHybrid.initialize(config:)`
  - `WilmarHybridWebView`
  - `WilmarHybridView` SwiftUI 包装
  - 显式注册式 JS Bridge
  - `localx://bundle/...` 与 `localx://sandbox/...`

iOS 验证命令：

```bash
swift test --package-path /Users/hanklee/Desktop/Now/iOS/Packages/NowCore
swift test --package-path /Users/hanklee/Desktop/Now/iOS/Packages/NowHybrid
xcodebuild -project /Users/hanklee/Desktop/Now/iOS/NowSimple.xcodeproj -scheme NowSimple -destination 'generic/platform=iOS' build
```

## 文档约定

- 根目录说明放在 `README.md`
- 平台计划文档放在：
  - `android/PLAN.md`
  - `iOS/PLAN.md`
- 计划文档默认写“已实现内容 + 已验证命令 + 剩余空白”，不要只写理想方案
- 如果改动了模块边界、公开 API、Demo 宿主或验证命令，需要同步更新对应 `PLAN.md`

## 当前已知空白

- Android 还没有完成真机层面的交互验收记录
- iOS 目前已有 package tests 和 `xcodebuild` 验证，但还没有补一份手动点验清单
- 根目录 `README.md` 现在已经补成项目入口说明，但还不是完整对外发布文档

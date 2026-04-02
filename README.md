# Now

`Now` 是一个跨平台原生 Hybrid 容器仓库，当前包含两套实现：

- [`android`](/Users/hanklee/Desktop/Now/android)
  Kotlin / Android Library 版本，包含 `:now:core`、`:now:hybrid` 和 Compose Demo `:app`
- [`iOS`](/Users/hanklee/Desktop/Now/iOS)
  Swift Package 版本，包含 `NowCore`、`NowHybrid` 和 SwiftUI Demo `NowSimple`

当前主线目标是在线 H5 容器可用，明确不包含离线 H5 包下载、离线模式切换，以及相关预留接口。

## 文档入口

- 协作说明：
  - [`AGENT.md`](/Users/hanklee/Desktop/Now/AGENT.md)
- Android 已实现计划：
  - [`android/PLAN.md`](/Users/hanklee/Desktop/Now/android/PLAN.md)
- iOS 已实现计划：
  - [`iOS/PLAN.md`](/Users/hanklee/Desktop/Now/iOS/PLAN.md)

## 快速验证

Android：

```bash
cd /Users/hanklee/Desktop/Now/android
./gradlew :app:assembleDebug :now:core:testDebugUnitTest :now:hybrid:testDebugUnitTest
```

iOS：

```bash
swift test --package-path /Users/hanklee/Desktop/Now/iOS/Packages/NowCore
swift test --package-path /Users/hanklee/Desktop/Now/iOS/Packages/NowHybrid
xcodebuild -project /Users/hanklee/Desktop/Now/iOS/NowSimple.xcodeproj -scheme NowSimple -destination 'generic/platform=iOS' build
```

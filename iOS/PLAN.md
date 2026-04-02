# iOS 已实现计划：`NowCore` 与 `NowHybrid`

## Summary

`/Users/hanklee/Desktop/Now/iOS` 已按 Swift Package 方式完成首版实现：

- `Packages/NowCore`
- `Packages/NowHybrid`
- `NowSimple` 作为 SwiftUI Demo 宿主

当前实现目标是在线主链路可用，已经具备：

- `NowCore`：初始化、服务定位、文件系统、偏好存储、Keychain 加密存储、主线程、网络状态、基础系统能力
- `NowHybrid`：`WKWebView` 容器、JS Bridge、Cookie 同步、加载进度、`localx://` 本地资源加载、SwiftUI 包装
- Demo：在线 URL、bundle 静态页、sandbox 运行时页面、同步/异步 bridge 演示

明确未实现：

- 离线 H5 包下载
- 离线模式切换
- 针对离线方案的占位接口

## 已实现的 Public APIs / Interfaces

### `NowCore`

- `NowCore.initialize(context:)`
- `WilmarServiceLocator`
- `IPlatformSettingService`
- `IFileSystemService`
- `NowPreferences`
- `EncryptedPreferences`
- `NowFileSystem`
- `WilmarMainThread`
- `NowConnectivity`
- `NowEssential`

实现说明：

- `NowPreferences` 基于 `UserDefaults`
- `EncryptedPreferences` 基于 Keychain
- `IPlatformSettingService` 首期支持跳系统设置页和定位服务开关状态
- `NowEssential` 当前只保留主链路实际需要的基础能力

### `NowHybrid`

- `NowHybrid.initialize(config:)`
- `WilmarHybridWebView`
- `WilmarLocalSource`
- `INowBridge`
- `NowJsBridgeManager`
- `NowJsBridge`
- `HybResponse`
- `WilmarHybridView`

实现说明：

- JS Bridge 已采用显式注册式 API，不做注解扫描
- bridge 同时支持同步返回与异步完成后回调
- `localx://` 已支持 `bundle` 与 `sandbox`
- 底层以 `UIKit + WKWebView` 为核心，`SwiftUI` 只做包装

## 实现落点

### 1. 包结构

关键文件：

- `Packages/NowCore/Package.swift`
- `Packages/NowHybrid/Package.swift`

已完成：

- `NowHybrid` 已依赖 `NowCore`
- `NowSimple.xcodeproj` 已接入两个本地 package

### 2. `NowCore` 基础设施层

核心文件：

- `Packages/NowCore/Sources/NowCore/NowCore.swift`

已经完成：

- `NowCore.initialize(context:)`
- 默认服务注册
- `WilmarServiceLocator`
- `NowPreferences`
- `EncryptedPreferences`
- `NowFileSystem`
- `WilmarMainThread`
- `NowConnectivity`
- `NowEssential`

### 3. `NowHybrid` 容器层

核心文件：

- `Packages/NowHybrid/Sources/NowHybrid/NowHybrid.swift`

已经完成：

- `WilmarHybridWebView`
- `WKUserContentController` bridge 注入
- `WKScriptMessageHandler` 消息接收
- `WKURLSchemeHandler` 本地资源映射
- `localx://bundle/...`
- `localx://sandbox/...`
- 进度回调
- `evaluateJavaScript`
- Cookie 同步
- `canGoBack`
- `goBack()`
- `dispose()`

### 4. JS Bridge 体系

已经完成：

- `BridgeInvocationRequest`
- `HybResponse`
- `INowBridge`
- `NowJsBridgeManager`
- `NowJsBridge`

当前默认 bridge 已支持：

- `saveStorage`
- `getStorage`
- `removeStorage`

### 5. Demo / 宿主接入

宿主文件：

- `NowSimple/NowSimpleApp.swift`
- `NowSimple/ContentView.swift`
- `NowSimple/HybridDemoViewModel.swift`
- `NowSimple/Demo/hybrid-demo.html`

已经完成：

- App 启动时初始化 `NowCore` 与 `NowHybrid`
- SwiftUI 页面承载 `WilmarHybridView`
- 在线 URL 演示
- bundle H5 演示
- sandbox H5 演示
- 自定义 demo bridge
- 默认 `NowJsBridge` 存储桥接演示

## 已验证内容

已通过的 package tests：

```bash
swift test --package-path /Users/hanklee/Desktop/Now/iOS/Packages/NowCore
swift test --package-path /Users/hanklee/Desktop/Now/iOS/Packages/NowHybrid
```

已通过的工程构建：

```bash
xcodebuild -project /Users/hanklee/Desktop/Now/iOS/NowSimple.xcodeproj -scheme NowSimple -destination 'generic/platform=iOS' build
```

## 当前剩余空白

- 还没有补充一份手动点击验收记录
- 暂未实现视频全屏等更深层 `WKUIDelegate` 行为验收
- 当前仓库里仍保留 `Pods/` 目录，但主工程文档应继续以本地 Swift Package 结构为准

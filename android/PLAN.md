# Android 已实现计划：`now:core` 与 `now:hybrid`

## Summary

`/Users/hanklee/Desktop/Now/android` 已完成首版 Kotlin/Android 原生实现，当前目录结构为：

- `:now:core`
- `:now:hybrid`
- `:app`

目前实现目标是在线 H5 主链路可用，已经具备：

- `NowCore`：初始化、服务定位、文件系统、偏好存储、主线程、网络状态、基础系统能力
- `NowHybrid`：WebView 容器、`localx://` 本地资源、JS Bridge、Compose 包装
- `app`：Compose Demo 宿主、在线页面加载、内嵌 H5 bridge 验证页

明确未实现：

- 离线 H5 包下载
- 离线模式切换
- 针对离线能力的扩展点

## 已实现的 Public APIs / Interfaces

### `now:core`

- `NowCore.initialize(context)`
- `WilmarServiceLocator`
- `IPlatformSettingService`
- `IFileSystemService`
- `NowFileSystem`
- `NowPreferences`
- `EncryptedPreferences`
- `WilmarMainThread`
- `NowConnectivity`
- `NowEssential`

### `now:hybrid`

- `NowHybrid.initialize(context)`
- `WilmarHybridWebView`
- `WilmarLocalSource`
- `INowBridge`
- `INowJsBridge`
- `NowJsBridgeManager`
- `JsBridgePlugin`
- `@JsNativeClass`
- `@JsInterface`
- `@JsParam`
- `@JsCallback`
- `@WebView`
- `NowJsBridge`
- `WilmarHybridView`

## 实现落点

### 1. 构建与模块基础

关键文件：

- `settings.gradle.kts`
- `now/core/build.gradle.kts`
- `now/hybrid/build.gradle.kts`

已完成：

- `:now:core` 与 `:now:hybrid` 作为 Android Library 接入
- namespace 已统一为：
  - `com.hankle.now.core`
  - `com.hankle.now.hybrid`
- `:now:hybrid` 已依赖 `:now:core`

### 2. `now:core` 基础设施层

核心实现文件：

- `now/core/src/main/java/com/hankle/now/core/NowCore.kt`
- `now/core/src/main/java/com/hankle/now/core/service/WilmarServiceLocator.kt`
- `now/core/src/main/java/com/hankle/now/core/storage/NowPreferences.kt`
- `now/core/src/main/java/com/hankle/now/core/storage/EncryptedPreferences.kt`
- `now/core/src/main/java/com/hankle/now/core/essential/NowConnectivity.kt`

已完成：

- 应用级初始化与默认服务注册
- 文件系统路径映射
- 明文偏好存储
- 加密偏好存储
- 主线程封装
- 网络状态读取
- 基础系统能力封装

### 3. `now:hybrid` 容器层

核心实现文件：

- `now/hybrid/src/main/java/com/hankle/now/hybrid/NowHybrid.kt`
- `now/hybrid/src/main/java/com/hankle/now/hybrid/web/WilmarHybridWebView.kt`
- `now/hybrid/src/main/java/com/hankle/now/hybrid/web/WilmarLocalSource.kt`
- `now/hybrid/src/main/java/com/hankle/now/hybrid/compose/WilmarHybridView.kt`

已完成：

- 原生 `WebView` 封装
- URL 加载与 HTML 直载
- 进度回调
- `localx://` 本地资源定位
- Compose 包装层

### 4. JS Bridge 体系

核心实现文件：

- `now/hybrid/src/main/java/com/hankle/now/hybrid/jsbridge/JsBridgePlugin.kt`
- `now/hybrid/src/main/java/com/hankle/now/hybrid/jsbridge/NowJsBridge.kt`
- `now/hybrid/src/main/java/com/hankle/now/hybrid/jsbridge/NowJsBridgeManager.kt`
- `now/hybrid/src/main/java/com/hankle/now/hybrid/bridge/BridgeInvocationRequest.kt`
- `now/hybrid/src/main/java/com/hankle/now/hybrid/bridge/BridgeMethodInvoker.kt`

已完成：

- 注解式 bridge 绑定
- 请求解析与方法分发
- JS 回调结果封装
- 默认存储 bridge

当前默认 bridge 已支持：

- `saveStorage`
- `getStorage`
- `removeStorage`

### 5. Demo / 宿主接入

宿主文件：

- `app/src/main/java/com/hankle/nowsimple/MainActivity.kt`

已完成：

- App 启动时初始化 `NowCore` 与 `NowHybrid`
- Compose 页面承载 `WilmarHybridView`
- 在线页面加载按钮
- 内嵌 H5 bridge demo 页面
- demo bridge `echoMessage`

## 已验证内容

Android 实现此前已经通过以下验证命令：

```bash
cd /Users/hanklee/Desktop/Now/android
./gradlew :app:assembleDebug :now:core:testDebugUnitTest :now:hybrid:testDebugUnitTest
```

单元测试覆盖到：

- `NowPreferences`
- `WilmarServiceLocator`
- `BridgeInvocationRequest`
- `BridgeMethodInvoker`
- `WilmarLocalSource`

## 当前剩余空白

- 还没有补真机或模拟器的交互验收记录
- `WebChromeClient` 的更深层多媒体/全屏行为还缺少专项验收说明
- Demo 目前偏功能验证，尚未整理成正式对外示例

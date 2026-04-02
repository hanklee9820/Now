# Android

Android 目录承载 `Now` 的 Kotlin / Android 原生实现，当前包含三个模块：

- `:now:core`
- `:now:hybrid`
- `:app`

当前主线目标是在线 H5 容器可用，明确不包含离线 H5 包下载、离线模式切换，以及相关占位接口。

## 模块说明

- `now/core`
  基础设施层，负责初始化、服务定位、文件系统、偏好存储、主线程和网络状态等通用能力
- `now/hybrid`
  Hybrid 容器层，负责 `WebView`、`localx://` 本地资源、JS Bridge 和 Compose 包装
- `app`
  Demo 宿主，只用于验证库可用，不承载库逻辑

## 关键入口

- App 入口：
  - `app/src/main/java/com/hankle/nowsimple/MainActivity.kt`
- Core 初始化：
  - `now/core/src/main/java/com/hankle/now/core/NowCore.kt`
- Hybrid 初始化：
  - `now/hybrid/src/main/java/com/hankle/now/hybrid/NowHybrid.kt`
- WebView 容器：
  - `now/hybrid/src/main/java/com/hankle/now/hybrid/web/WilmarHybridWebView.kt`
- 默认存储桥：
  - `now/hybrid/src/main/java/com/hankle/now/hybrid/jsbridge/NowJsBridge.kt`

## 快速验证

```bash
cd /Users/hanklee/Desktop/Now/android
./gradlew :app:assembleDebug :now:core:testDebugUnitTest :now:hybrid:testDebugUnitTest
```

## 文档

- 已实现计划：
  - [`PLAN.md`](/Users/hanklee/Desktop/Now/android/PLAN.md)
- 根目录协作说明：
  - [`../AGENT.md`](/Users/hanklee/Desktop/Now/AGENT.md)

## 当前状态

- 已完成在线页面加载和内嵌 H5 bridge demo
- 已有 `NowPreferences`、`WilmarServiceLocator`、bridge 解析和 `WilmarLocalSource` 的单元测试
- 还没有补真机或模拟器的交互验收记录

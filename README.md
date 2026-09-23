# 生日提醒 · Birthday Reminder

一个本地优先（local-first）的 Flutter 应用，用于管理家人朋友的**农历 / 公历**生日并自动提醒。

> A local-first Flutter app for managing lunar & solar birthday reminders for family and friends.

## 功能

- 农历 / 公历生日录入，自动互转；正确处理**闰月**、**腊月无三十**、**公历 2 月 29 日平年回退**等边界
- 按临近程度排序的生日列表，**今日寿星置顶高亮**并显示倒计时
- 本地通知提醒：可为每位联系人自定义提前天数（0 = 当天）、统一提醒时刻；设备重启后自动恢复
- 搜索、按关系筛选、月份总览、统计概览（本月寿星 / 今年已过与未过）
- 头像、备注、年龄（周岁 / 虚岁）
- 数据导出 / 导入 JSON 备份（支持合并或覆盖）
- 深色模式，跟随系统
- **全部数据保存在本机**，无联网、无账号、无第三方数据 SDK

## 技术栈

| 用途 | 选型 |
| --- | --- |
| 框架 | Flutter 3 / Dart 3 |
| 状态管理 | Riverpod |
| 本地数据库 | drift + SQLite |
| 农历换算 | lunar |
| 本地通知 | flutter_local_notifications + timezone |
| 路由 | go_router |
| 备份 IO | file_picker + share_plus |

## 目录结构

```
lib/
  core/theme/               主题
  features/
    calendar/               历法引擎（核心深模块，纯函数，可完全隔离测试）
    persons/                联系人实体、drift 仓储、Providers
    reminders/              提醒规划与调度、通知网关
    backup/                 备份编解码与导入导出服务
    settings/               设置
    dashboard/              界面：列表 / 编辑 / 详情 / 月份总览 / 设置
  routes/                   路由
test/                       单元测试与组件测试（103 项）
docs/                       PRD
third_party/sqlite3/        SQLite amalgamation（供 Android 本地编译）
assets/icon/                应用图标源文件
```

## 构建与运行

需要 Flutter 3.47+（Dart 3.13+）、Android SDK（含 NDK）、JDK 17。

```bash
flutter pub get
flutter run
```

### 测试与检查

```bash
flutter test
flutter analyze
```

### 打包

```bash
# 按 CPU 架构拆分（推荐，单包约 20MB）
flutter build apk --release --split-per-abi

# App Bundle（上架 Google Play）
flutter build appbundle --release
```

### 重新生成应用图标

修改 `assets/icon/` 下的图片后运行：

```bash
dart run flutter_launcher_icons
```

## 关于 SQLite 与构建镜像

- `pubspec.yaml` 中的 `hooks.user_defines.sqlite3` 使 Android 构建直接使用
  `third_party/sqlite3/sqlite3.c`（SQLite 3.50.4 amalgamation，公有领域）本地编译，
  避免构建时访问 GitHub 下载预编译库。若你的网络可访问 GitHub，可删除该段配置以改用官方预编译库。
- `android/gradle/wrapper/gradle-wrapper.properties` 及 `android/settings.gradle.kts`、
  `android/build.gradle.kts` 使用了腾讯 / 阿里云镜像以加速国内构建。如需官方源，
  可将其替换回 `services.gradle.org`、`google()`、`mavenCentral()`。
- 若项目位于 `D:` 盘而 pub 缓存在 `C:` 盘，`android/gradle.properties` 中的
  `kotlin.incremental=false` 用于规避 Kotlin 增量编译的跨盘符缺陷
  （`this and base files have different roots`）。

## 隐私

本应用不联网、不上传任何数据，所有信息仅保存在设备本机的 SQLite 数据库中。
导出的备份文件由用户自行保管。

## 许可

[MIT License](LICENSE)

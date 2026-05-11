# la_le_me_app

「拉了么」Flutter 客户端 —— 隐私优先的生理健康记录与轻社交排名应用

## 项目结构

```
lib/
├── main.dart                         # 应用入口，路由注册
├── models/
│   ├── achievement.dart              # 成就系统定义（13 种成就）
│   ├── profile_model.dart            # 用户档案模型（BMI、腰臀比）
│   ├── ranking.dart                  # 段位系统与排行榜数据模型
│   ├── score.dart                    # 积分乘数与结算结果模型
│   ├── season.dart                   # 赛季管理与历史模型
│   └── toilet_record.dart            # 如厕记录模型（含 RecordType 枚举）
├── providers/
│   ├── ranking_provider.dart         # 排行榜状态管理 (Riverpod)
│   └── record_provider.dart          # 记录状态管理 (Riverpod)
├── screens/
│   ├── ai_config_page.dart           # AI 大模型配置页面
│   ├── backup_page.dart              # 云端备份页面
│   ├── data_management_page.dart     # 数据管理页面
│   ├── home_page.dart                # 首页（问候语、核心卡片、快速记录）
│   ├── main_shell.dart               # 底部 4 Tab 主壳
│   ├── profile_page.dart             # 个人档案页面
│   ├── ranking_page.dart             # 排行榜（全球/同城/好友）
│   ├── record_detail_page.dart       # 详细记录页面
│   ├── security_page.dart            # 安全设置页面
│   ├── settings_page.dart            # 设置主页面
│   ├── stats_page.dart               # 统计入口页
│   └── stats_pages.dart              # 周/月/年统计页面
├── services/
│   ├── achievement_service.dart      # 成就自动检测与解锁
│   ├── ai_service.dart               # AI 肠道顾问（多厂商大模型）
│   ├── anomaly_detector.dart         # 异常预警（便秘/腹泻/血便）
│   ├── anti_cheat_service.dart       # 客户端反作弊预检
│   ├── api_config.dart               # 环境变量与 API 配置
│   ├── api_service.dart              # REST API 客户端 (Dio + JWT)
│   ├── backup_encryption.dart        # AES-256-GCM 加密备份/解密
│   ├── database_factory_io.dart      # SQLite 数据库工厂 (IO)
│   ├── database_factory_stub.dart    # SQLite 数据库工厂 (Stub)
│   ├── database_factory_web.dart     # SQLite 数据库工厂 (Web)
│   ├── database_service.dart         # SQLite CRUD 服务
│   ├── notification_service.dart     # 8 种本地通知类型
│   ├── regularity_calculator.dart    # 规律指数/健康等级/年度关键词
│   ├── score_calculator.dart         # 六维积分引擎 (R/H/T/P/S/M)
│   ├── season_service.dart           # 赛季切换与重置
│   ├── settings_service.dart         # 应用偏好持久化
│   └── theme_service.dart            # Light/Dark/OLED 主题
└── utils/
    ├── app_utils.dart                # 通用工具函数
    └── theme.dart                    # 主题颜色、样式常量
```

## 核心依赖

| 依赖 | 版本 | 用途 |
|------|------|------|
| flutter_riverpod | ^2.5.0 | 响应式状态管理 |
| sqflite | ^2.3.0 | 本地 SQLite 数据库 |
| dio | ^5.4.0 | HTTP 网络请求 |
| fl_chart | ^0.67.0 | 原生图表渲染 |
| crypto + pointycastle | ^3.x | AES-256-GCM 加密 |
| local_auth | ^2.2.0 | 生物识别 (Face ID/指纹) |
| flutter_secure_storage | ^9.2.1 | 安全 Key-Value 存储 |
| web_socket_channel | ^3.0.3 | WebSocket 实时推送 |
| uuid | ^4.3.3 | UUID 生成 |
| intl | ^0.19.0 | 国际化日期格式化 |

## 快速开始

```bash
cd la-le-me-app

# 配置 Android 本地属性（首次构建需要）
echo "sdk.dir=<你的Android SDK路径>" > android/local.properties
echo "flutter.sdk=<你的Flutter SDK路径>" >> android/local.properties

# 安装依赖
flutter pub get

# 开发调试
flutter run

# 构建 Release APK
flutter build apk --release

# 输出路径
# build/app/outputs/flutter-apk/app-release.apk
```

## Android 签名

项目已配置 `kaptree` 正式签名（RSA 2048-bit，有效期 10000 天）：

| 文件 | 说明 |
|------|------|
| `android/app/kaptree.keystore` | 密钥库文件 |
| `android/key.properties` | 签名凭据（已加入 `.gitignore`） |

## 环境变量

使用 `--dart-define` 切换后端环境：

| ENV | 后端地址 | 用途 |
|-----|---------|------|
| `dev` (默认) | `http://10.0.2.2:8080` | Android 模拟器本地开发 |
| `staging` | `https://staging-api.laleme.app` | 预发布环境 |
| `prod` | `https://api.laleme.app` | 生产环境 |

```bash
flutter run --dart-define=ENV=dev
flutter build apk --dart-define=ENV=prod
```

## 运行测试

```bash
flutter analyze    # 静态分析
flutter test       # 单元测试
```

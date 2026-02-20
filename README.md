# Body Controller - 个人健身App

一个为算法工程师设计的个人健身App，支持跑步和力量训练记录，集成AI教练功能。

## 功能特性

### 🏃 跑步记录
- 快速记录跑步数据（距离、时间、配速、体感）
- 实时计算配速
- 支持历史补录
- 快速距离标签（5km、10km、15km、半马）

### 💪 力量训练记录
- 3分化模板（推日、拉日、腿日）
- 内置动作清单
- 多组数据录入（重量、次数、RPE）
- 自动计算训练容量

### 🎯 目标追踪
- 半程马拉松目标（日期、完赛时间）
- 力量目标（深蹲、卧推、硬拉）
- 进度可视化
- 倒计时提醒

### 🤖 AI教练
- 数据洞察分析（跑量趋势、强度分布、力量进展、恢复信号）
- 智能训练计划生成
- 支持多轮对话调整
- 集成阿里云百炼API

## 技术栈

- **框架**: Flutter 3.19
- **状态管理**: Riverpod
- **本地存储**: Drift (SQLite)
- **UI设计**: Material Design 3
- **图表**: fl_chart
- **AI服务**: 阿里云百炼 (DashScope)

## 项目结构

```
lib/
├── data/
│   ├── database/          # 数据库相关
│   │   ├── database.dart          # 数据库Schema
│   │   └── database_manager.dart  # 数据库管理
│   ├── repositories/      # 数据仓库
│   │   ├── run_repository.dart
│   │   ├── strength_repository.dart
│   │   ├── goal_repository.dart
│   │   └── ai_config_repository.dart
│   ├── services/          # 服务层
│   │   └── ai_service.dart
│   └── providers/         # Riverpod Providers
│       └── providers.dart
└── presentation/
    └── screens/           # 页面
        ├── main.dart
        ├── run_record_screen.dart
        ├── strength_record_screen.dart
        ├── records_list_screen.dart
        ├── goals_screen.dart
        └── ai_coach_screen.dart
```

## 安装和运行

### 前置要求

- Flutter SDK 3.19 或更高版本
- Dart SDK 3.0 或更高版本
- Android Studio 或 VS Code（推荐）
- Android 设备或模拟器

### 安装步骤

1. 克隆或下载项目到本地

2. 安装依赖：
```bash
flutter pub get
```

3. 生成数据库代码（如果修改了database.dart）：
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. 运行应用：
```bash
flutter run
```

## 使用说明

### 首次使用

1. **配置AI服务**：
   - 进入"AI教练"页面
   - 点击设置图标
   - 输入阿里云百炼API Key
   - 保存配置

2. **记录训练**：
   - 点击"记录"标签
   - 选择"跑步"或"力量训练"
   - 填写训练数据并保存

3. **设定目标**：
   - 进入"目标"页面
   - 点击添加按钮
   - 选择目标类型并填写信息

### AI教练功能

- **数据洞察**：点击"数据洞察"按钮，AI会分析您的训练数据
- **生成计划**：点击"生成计划"按钮，AI会制定下周训练计划
- **对话调整**：在输入框中输入问题，与AI对话调整计划

## 数据隐私

- 所有数据存储在本地SQLite数据库中
- 不会上传到云端（除非用户配置了云端备份）
- AI API Key仅用于调用阿里云百炼服务

## 开发说明

### 数据库迁移

如果需要修改数据库Schema：

1. 修改 `lib/data/database/database.dart`
2. 增加schemaVersion
3. 实现升级逻辑
4. 运行 `flutter pub run build_runner build`

### 添加新功能

1. 在 `data/repositories/` 中添加数据访问逻辑
2. 在 `data/providers/` 中添加Provider
3. 在 `presentation/screens/` 中创建UI页面
4. 在 `main.dart` 中注册导航

## 许可证

本项目为个人使用项目，仅供学习和参考。

## 联系方式

如有问题或建议，请通过以下方式联系：
- 提交Issue
- 发送邮件

## 更新日志

### v1.0.0 (2024-02-20)
- 初始版本发布
- 实现跑步记录功能
- 实现力量训练记录功能
- 实现目标追踪功能
- 集成AI教练（阿里云百炼）
- Material Design 3 UI设计
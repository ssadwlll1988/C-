# C盘清理大师 - Flutter版本

这是一个使用Flutter开发的C盘清理工具，功能类似于Python版本的c-disk-cleaning-program。

## 功能特点

- 🧹 基础清理：扫描和清理系统临时文件、缓存等
- 🔍 深度扫描：深度扫描系统中的垃圾文件（待实现）
- 📁 大文件管理：查找和管理大文件（待实现）
- 💻 软件管理：管理软件安装和迁移（待实现）

## 环境要求

- Flutter SDK (>=2.19.0)
- Dart SDK (>=2.19.0)
- Windows操作系统

## 安装步骤

1. 确保已安装Flutter SDK并配置好环境变量
2. 克隆或下载本项目到本地
3. 在项目根目录运行以下命令获取依赖：
   ```bash
   flutter pub get
   ```
4. 运行应用：
   ```bash
   flutter run
   ```

## 项目结构

```
lib/
├── main.dart                 # 应用入口
├── screens/                  # 页面组件
│   ├── home_screen.dart      # 主屏幕
│   ├── basic_clean_tab.dart  # 基础清理标签页
│   ├── deep_scan_tab.dart    # 深度扫描标签页
│   ├── large_file_tab.dart   # 大文件管理标签页
│   └── software_tab.dart     # 软件管理标签页
├── providers/                # 状态管理
│   └── clean_provider.dart   # 清理功能提供者
└── utils/                    # 工具类
    └── disk_utils.dart       # 磁盘操作工具
```

## 注意事项

- 本应用需要管理员权限才能访问系统目录
- 清理操作不可逆，请谨慎选择要清理的项目
- 部分功能仍在开发中

## 开发计划

- [ ] 完善深度扫描功能
- [ ] 实现大文件管理功能
- [ ] 实现软件管理功能
- [ ] 添加更多清理类别
- [ ] 优化性能和用户体验
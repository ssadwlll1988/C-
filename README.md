# C盘卫士 - Flutter版本

<div align="center">

[![Release](https://img.shields.io/github/v/release/ssadwlll1988/C-?label=Release&style=for-the-badge)](https://github.com/ssadwlll1988/C-/releases/tag/C%E7%9B%98%E6%B8%85%E7%90%86%E5%B7%A5%E5%85%B7)
[![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Windows-lightgrey?style=for-the-badge)]()

**🎉 v1.0.0 正式发布！** [立即下载](https://github.com/ssadwlll1988/C-/releases/tag/C%E7%9B%98%E6%B8%85%E7%90%86%E5%B7%A5%E5%85%B7) | [查看更新日志](https://github.com/ssadwlll1988/C-/releases/tag/C%E7%9B%98%E6%B8%85%E7%90%86%E5%B7%A5%E5%85%B7)

</div>

---

这是一个使用Flutter开发的C盘清理工具，功能与Python版本的c-disk-cleaning-program完全一致。

## ✨ 功能特点

### 🧹 一键清理
- 扫描和清理系统临时文件、缓存等
- 支持30+个清理类别（系统临时、系统缓存、浏览器缓存、驱动缓存等）
- 智能识别安全可清理项
- 全选/取消全选功能
- 实时显示可清理空间大小

### 🔍 深度扫描
- 全盘扫描日志文件、临时文件、安装包残留
- 扫描系统补丁缓存、垃圾文件扩展名
- 深度扫描所有浏览器缓存（Chrome、Edge、Firefox等）
- Python编译缓存(__pycache__)扫描
- 开发工具缓存自动发现（VS Code、JetBrains、Android Studio等）
- 软件缓存智能识别

### 📁 大文件管理
- 自定义文件大小阈值（50MB-1000MB）
- 多线程并行扫描，提升扫描速度
- 支持暂停/继续/停止扫描
- 按文件名、路径、大小、类型、修改时间排序
- 双击打开文件所在目录
- 批量删除选中的大文件

### 💻 软件搬家
- 扫描已安装的软件（从注册表读取）
- 显示软件名称、发布者、版本、占用大小、安装路径
- 支持软件图标显示
- 搬迁到指定磁盘（创建符号链接）
- 搬迁进度实时显示
- 失败自动回滚

### 📊 C盘分析
- 可视化显示C盘使用情况
- 按文件夹分类统计（Program Files、Users、Windows等）
- 饼图展示各分类占比
- 详细列表显示每个文件夹的大小
- 快速定位占用空间大的目录

## 🛠️ 环境要求

- **Flutter SDK**: >=2.19.0 <4.0.0
- **Dart SDK**: >=2.19.0 <4.0.0
- **操作系统**: Windows 10/11
- **Visual Studio**: 2022（需要安装"使用C++的桌面开发"工作负载）
- **CMake**: 必需组件

## 📦 安装步骤

### 🚀 快速开始（推荐）

**直接下载 Release 版本：**
- 📥 [GitHub Release](https://github.com/ssadwlll1988/C-/releases/tag/C%E7%9B%98%E6%B8%85%E7%90%86%E5%B7%A5%E5%85%B7)
- 📥 [Gitee Release](https://gitee.com/ssadwlll1988/Flutter/releases)

下载后解压，双击运行 `c_disk_cleaning_program.exe` 即可使用！

> 💡 **提示**：建议右键 → “以管理员身份运行”以获得完整功能。

---

### 方法一：从源码编译

1. 克隆仓库：
   ```bash
   git clone https://github.com/ssadwlll1988/C-.git
   cd C-
   ```

2. 获取依赖：
   ```bash
   flutter pub get
   ```

3. 运行应用：
   ```bash
   flutter run -d windows
   ```

### 方法二：从 Gitee 克隆（国内更快）

1. 克隆仓库：
   ```bash
   git clone https://gitee.com/ssadwlll1988/Flutter.git
   cd Flutter_Project
   ```

2. 获取依赖：
   ```bash
   flutter pub get
   ```

3. 运行应用：
   ```bash
   flutter run -d windows
   ```

### 方法三：直接运行

如果已经配置好Flutter环境：
```bash
cd Flutter_Project
flutter pub get
flutter run -d windows
```

## 🏗️ 项目结构

```
lib/
├── main.dart                      # 应用入口
├── config/                        # 配置文件
│   ├── scan_categories.dart       # 扫描类别配置（30+类别）
│   ├── analysis_config.dart       # 磁盘分析配置
│   ├── skip_rules.dart            # 跳过规则
│   └── software_db.dart           # 软件数据库
├── screens/                       # 页面组件
│   ├── home_screen.dart           # 主屏幕（侧边栏导航）
│   ├── basic_clean_tab.dart       # 一键清理标签页
│   ├── deep_scan_tab.dart         # 深度扫描标签页
│   ├── large_file_tab.dart        # 大文件管理标签页
│   ├── software_tab.dart          # 软件搬家标签页
│   └── analysis_tab.dart          # C盘分析标签页
├── providers/                     # 状态管理（Provider模式）
│   ├── clean_provider.dart        # 基础清理提供者
│   ├── deep_scan_provider.dart    # 深度扫描提供者
│   ├── large_file_provider.dart   # 大文件管理提供者
│   ├── software_provider.dart     # 软件搬家提供者
│   └── analysis_provider.dart     # C盘分析提供者
└── utils/                         # 工具类
    ├── disk_utils.dart            # 磁盘操作工具（跨平台）
    ├── disk_utils_io.dart         # Windows实现（FFI调用）
    └── disk_utils_web.dart        # Web实现（占位）
```

## 🔧 技术栈

- **UI框架**: Flutter (Material Design 3)
- **状态管理**: Provider
- **Windows API**: win32 package + FFI
- **并发处理**: Isolate（避免阻塞UI）
- **本地存储**: shared_preferences
- **国际化**: intl

## ⚠️ 注意事项

1. **管理员权限**: 本应用需要管理员权限才能访问系统目录（如C:\Windows\Temp）
2. **谨慎清理**: 清理操作不可逆，请仔细阅读每个项目的描述
3. **备份重要数据**: 清理前建议备份重要文件
4. **首次扫描**: 深度扫描和大文件扫描可能需要较长时间
5. **软件搬家**: 搬迁过程中请勿使用相关软件，搬迁后原位置会创建符号链接

## 🎯 与Python版对比

| 功能 | Python版 | Flutter版 | 状态 |
|------|---------|----------|------|
| 基础清理 | ✅ | ✅ | 完全一致 |
| 深度扫描 | ✅ | ✅ | 完全一致 |
| 大文件管理 | ✅ | ✅ | 完全一致 |
| 软件搬家 | ✅ | ✅ | 完全一致 |
| C盘分析 | ✅ | ✅ | 完全一致 |
| UI美观度 | CustomTkinter | Material Design 3 | Flutter更现代 |
| 性能 | 单线程为主 | 多线程+Isolate | Flutter更优 |
| 跨平台 | ❌ Windows only | ✅ 可扩展 | Flutter潜力更大 |

## 🚀 构建发布版本

```bash
# 构建Windows release版本
flutter build windows --release

# 生成的exe位于
build/windows/x64/runner/Release/
```

## 📝 开发计划

- [x] 完善基础清理功能（30+类别）
- [x] 实现深度扫描功能
- [x] 实现大文件管理功能
- [x] 实现软件搬家功能
- [x] 实现C盘分析功能
- [ ] 添加更多浏览器支持
- [ ] 优化扫描性能（增量扫描）
- [ ] 添加清理历史记录
- [ ] 支持自定义清理规则
- [ ] 添加定时清理功能
- [ ] 打包为独立exe文件

## 📥 下载

### 预编译版本（推荐）

- **GitHub Release**: https://github.com/ssadwlll1988/C-/releases/tag/C%E7%9B%98%E6%B8%85%E7%90%86%E5%B7%A5%E5%85%B7
- **Gitee Release**: https://gitee.com/ssadwlll1988/Flutter/releases

下载后解压，双击运行即可使用！

### 从源码编译

参见上方的"安装步骤"部分。

---

## 🤝 贡献

欢迎提交Issue和Pull Request！

## 📄 许可证

MIT License
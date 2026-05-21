@echo off
chcp 65001 >nul
echo ========================================
echo   C盘卫士 - 项目完整性检查
echo ========================================
echo.

REM 检查 Flutter 是否安装
echo [1/7] 检查 Flutter 环境...
where flutter >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Flutter 未安装或未添加到 PATH
    echo    请下载: https://docs.flutter.dev/get-started/install/windows
    goto :end
) else (
    echo ✅ Flutter 已安装
    flutter --version | findstr "Flutter"
)
echo.

REM 检查 Git
echo [2/7] 检查 Git...
where git >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Git 未安装
    echo    请下载: https://git-scm.com/download/win
    goto :end
) else (
    echo ✅ Git 已安装
)
echo.

REM 检查项目文件
echo [3/7] 检查项目文件...
if not exist "pubspec.yaml" (
    echo ❌ pubspec.yaml 不存在
    goto :end
) else (
    echo ✅ pubspec.yaml 存在
)

if not exist "lib\main.dart" (
    echo ❌ lib\main.dart 不存在
    goto :end
) else (
    echo ✅ lib\main.dart 存在
)
echo.

REM 检查关键目录
echo [4/7] 检查关键目录...
if not exist "lib\config" (
    echo ❌ lib\config 目录不存在
    goto :end
) else (
    echo ✅ lib\config 目录存在
)

if not exist "lib\screens" (
    echo ❌ lib\screens 目录不存在
    goto :end
) else (
    echo ✅ lib\screens 目录存在
)

if not exist "lib\providers" (
    echo ❌ lib\providers 目录不存在
    goto :end
) else (
    echo ✅ lib\providers 目录存在
)

if not exist "lib\utils" (
    echo ❌ lib\utils 目录不存在
    goto :end
) else (
    echo ✅ lib\utils 目录存在
)
echo.

REM 获取依赖
echo [5/7] 获取 Flutter 依赖...
call flutter pub get
if %errorlevel% neq 0 (
    echo ❌ 依赖获取失败
    goto :end
) else (
    echo ✅ 依赖获取成功
)
echo.

REM 运行分析
echo [6/7] 运行代码分析...
call flutter analyze > analyze_result.txt 2>&1
findstr /C:"errors found" analyze_result.txt >nul
if %errorlevel% equ 0 (
    echo ❌ 发现错误，请查看 analyze_result.txt
    type analyze_result.txt
    goto :end
) else (
    echo ✅ 代码分析通过（可能有警告，但无错误）
)
del analyze_result.txt
echo.

REM 检查 Visual Studio
echo [7/7] 检查 Visual Studio...
call flutter doctor | findstr "Visual Studio" > vs_check.txt
type vs_check.txt
findstr /C:"[X]" vs_check.txt >nul
if %errorlevel% equ 0 (
    echo ⚠️  Visual Studio 配置可能不完整
    echo    请运行 flutter doctor 查看详情
) else (
    echo ✅ Visual Studio 配置正常
)
del vs_check.txt
echo.

echo ========================================
echo   检查完成！
echo ========================================
echo.
echo 下一步：
echo   1. 运行 flutter run -d windows 启动应用
echo   2. 或以管理员身份运行以获得完整权限
echo.

:end
pause

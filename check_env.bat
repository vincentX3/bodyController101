@echo off
echo ========================================
echo 环境配置检查
echo ========================================
echo.

echo [1] 检查Flutter SDK...
where flutter >nul 2>&1
if %errorlevel% == 0 (
    echo     [OK] Flutter已安装
    flutter --version 2>&1 | findstr "Flutter"
) else (
    echo     [ERROR] Flutter未找到
)
echo.

echo [2] 检查Java JDK...
java -version 2>&1 | findstr "version"
echo.

echo [3] 检查Android Studio...
if exist "D:\Software\Android Studio" (
    echo     [OK] Android Studio已安装
) else (
    echo     [ERROR] Android Studio未找到
)
echo.

echo [4] 检查环境变量...
echo     ANDROID_HOME: %ANDROID_HOME%
echo     ANDROID_SDK_ROOT: %ANDROID_SDK_ROOT%
echo.

echo [5] 检查项目目录...
cd /d "D:\bodyController101"
if exist pubspec.yaml (
    echo     [OK] 项目文件存在
) else (
    echo     [ERROR] 项目文件未找到
)
echo.

echo ========================================
echo 检查完成
echo ========================================
pause
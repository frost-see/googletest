@echo off
REM ============================================================================
REM Google Test 自动编译脚本 (Windows)
REM 用途: 快速编译 Google Test 和 Google Mock 框架
REM 使用: build.bat [选项]
REM ============================================================================

setlocal enabledelayedexpansion

REM 默认参数
set BUILD_TYPE=Release
set BUILD_TESTS=ON
set BUILD_SAMPLES=ON
set BUILD_GMOCK=ON
set BUILD_SHARED_LIBS=OFF
set VERBOSE=OFF
set INSTALL=OFF
set CLEAN=OFF

REM 颜色定义 (模拟)
set BLUE=[34m
set GREEN=[32m
set YELLOW=[33m
set RED=[31m
set NC=[0m

REM 打印帮助信息
if "%1"=="" goto :usage_short
if "%1"=="--help" goto :usage
if "%1"=="-h" goto :usage
if "%1"=="/?" goto :usage

REM 解析参数
:parse_args
if "%1"=="" goto :run_build
if "%1"=="-t" (
    set BUILD_TYPE=%2
    shift
    shift
    goto :parse_args
)
if "%1"=="--type" (
    set BUILD_TYPE=%2
    shift
    shift
    goto :parse_args
)
if "%1"=="--no-tests" (
    set BUILD_TESTS=OFF
    shift
    goto :parse_args
)
if "%1"=="--no-samples" (
    set BUILD_SAMPLES=OFF
    shift
    goto :parse_args
)
if "%1"=="--no-gmock" (
    set BUILD_GMOCK=OFF
    shift
    goto :parse_args
)
if "%1"=="--shared" (
    set BUILD_SHARED_LIBS=ON
    shift
    goto :parse_args
)
if "%1"=="-v" (
    set VERBOSE=ON
    shift
    goto :parse_args
)
if "%1"=="--verbose" (
    set VERBOSE=ON
    shift
    goto :parse_args
)
if "%1"=="--clean" (
    set CLEAN=ON
    shift
    goto :parse_args
)
if "%1"=="--install" (
    set INSTALL=ON
    shift
    goto :parse_args
)

:run_build
echo.
echo [32m[INFO][0m 开始编译 Google Test 框架
echo.
echo 编译配置:
echo   编译类型:       %BUILD_TYPE%
echo   构建 GoogleMock: %BUILD_GMOCK%
echo   构建 tests:     %BUILD_TESTS%
echo   构建 samples:   %BUILD_SAMPLES%
if "%BUILD_SHARED_LIBS%"=="ON" (
    echo   库类型:         共享库
) else (
    echo   库类型:         静态库
)
echo.

REM 获取脚本目录
set SCRIPT_DIR=%~dp0
set BUILD_DIR=%SCRIPT_DIR%..

REM 清空 build 目录（如果指定了 --clean）
if "%CLEAN%"=="ON" (
    if exist "%BUILD_DIR%\build" (
        echo [33m[WARNING][0m 删除现有 build\cmake 目录
        rmdir /s /q "%BUILD_DIR%\build\cmake" 2>nul
    )
)

REM 创建 cmake build 目录
if not exist "%BUILD_DIR%\build\cmake" (
    echo [32m[INFO][0m 创建 cmake 构建目录
    mkdir "%BUILD_DIR%\build\cmake"
)

cd /d "%BUILD_DIR%\build\cmake"

REM 运行 CMake
echo [32m[INFO][0m 运行 CMake 配置...
cmake ^
    -DCMAKE_BUILD_TYPE=%BUILD_TYPE% ^
    -DBUILD_GMOCK=%BUILD_GMOCK% ^
    -DBUILD_SHARED_LIBS=%BUILD_SHARED_LIBS% ^
    -Dgtest_build_tests=%BUILD_TESTS% ^
    -Dgtest_build_samples=%BUILD_SAMPLES% ^
    -Dgmock_build_tests=%BUILD_TESTS% ^
    "%BUILD_DIR%"

if errorlevel 1 (
    echo [31m[ERROR][0m CMake 配置失败！
    goto :error
)

echo [32m[SUCCESS][0m CMake 配置成功
echo.

REM 编译
echo [32m[INFO][0m 编译项目...
cmake --build . --config %BUILD_TYPE%

if errorlevel 1 (
    echo [31m[ERROR][0m 编译失败！
    goto :error
)

echo [32m[SUCCESS][0m 编译成功！
echo.

REM 运行测试
if "%BUILD_TESTS%"=="ON" (
    echo [32m[INFO][0m 运行测试...
    ctest --build-config %BUILD_TYPE% --verbose
    if errorlevel 1 (
        echo [33m[WARNING][0m 部分测试失败，但编译已完成
    ) else (
        echo [32m[SUCCESS][0m 所有测试通过！
    )
    echo.
)

REM 显示结果信息
echo [32m[INFO][0m 编译结果信息:
echo   build 目录:     %BUILD_DIR%\build\cmake
if exist "%BUILD_DIR%\build\cmake\lib" (
    echo   库文件位置:     %BUILD_DIR%\build\cmake\lib
    dir "%BUILD_DIR%\build\cmake\lib"
)
if exist "%BUILD_DIR%\build\cmake\bin" (
    echo   可执行文件位置: %BUILD_DIR%\build\cmake\bin
    dir "%BUILD_DIR%\build\cmake\bin"
)
echo.

echo [32m[SUCCESS][0m 编译完成！
echo.
echo [34m后续步骤:[0m
echo   1. 查看编译结果:
echo      cd %BUILD_DIR%\build\cmake
echo      dir lib
echo      dir bin
echo.
echo   2. 在项目中使用 Google Test:
echo      target_link_libraries(your_test gtest_main)
echo.
echo   3. 打开 Visual Studio 解决方案:
echo      start "%BUILD_DIR%\build\cmake\googletest.sln"
echo.

goto :end

:usage_short
echo 用法: build.bat [选项]
echo 使用 build.bat --help 查看完整帮助信息
echo.
goto :end

:usage
echo.
echo Google Test 自动编译脚本 (Windows)
echo.
echo 用法: build.bat [选项]
echo.
echo 选项:
echo   -h, --help              显示此帮助信息
echo   -t, --type TYPE         编译类型 (Release/Debug), 默认: Release
echo   --no-tests              不编译测试程序
echo   --no-samples            不编译示例程序
echo   --no-gmock              仅编译 GoogleTest，不编译 GoogleMock
echo   --shared                编译为共享库
echo   -v, --verbose           详细输出
echo   --clean                 清空 build 目录后重新编译
echo.
echo 示例:
echo   build.bat                          # 默认编译（Release 模式）
echo   build.bat -t Debug                 # Debug 模式编译
echo   build.bat --no-tests --no-samples  # 不编译测试和示例
echo   build.bat --shared                 # 编译共享库
echo   build.bat --clean                  # 清空并重新编译
echo.
goto :end

:error
echo.
echo [31m[ERROR][0m 编译过程中出现错误！
exit /b 1

:end
endlocal
exit /b 0

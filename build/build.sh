#!/bin/bash

################################################################################
# Google Test 自动编译脚本
# 用途: 快速编译 Google Test 和 Google Mock 框架
# 使用: ./build.sh [选项]
################################################################################

set -e  # 任何命令失败时退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 默认参数
BUILD_TYPE="Release"
BUILD_TESTS=ON
BUILD_SAMPLES=ON
BUILD_GMOCK=ON
BUILD_SHARED_LIBS=OFF
JOBS=$(nproc 2>/dev/null || echo 1)
VERBOSE=OFF

# 打印帮助信息
print_help() {
    cat << EOF
${BLUE}Google Test 自动编译脚本${NC}

用法: ./build.sh [选项]

选项:
    -h, --help              显示此帮助信息
    -t, --type TYPE         编译类型 (Release/Debug), 默认: Release
    --no-tests              不编译测试程序
    --no-samples            不编译示例程序
    --no-gmock              仅编译 GoogleTest，不编译 GoogleMock
    --shared                编译为共享库 (.so/.dll)
    -j, --jobs N            并行编译任务数，默认: 自动检测
    -v, --verbose           详细输出
    --clean                 清空 build 目录后重新编译
    --install               编译后安装到系统

示例:
    ./build.sh                          # 默认编译（Release 模式）
    ./build.sh -t Debug                 # Debug 模式编译
    ./build.sh --no-tests --no-samples  # 不编译测试和示例
    ./build.sh --shared -j 4            # 编译共享库，使用 4 个并行任务
    ./build.sh --clean --install        # 清空并重新编译，然后安装

EOF
}

# 打印信息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 解析命令行参数
INSTALL=OFF
CLEAN=OFF

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            print_help
            exit 0
            ;;
        -t|--type)
            BUILD_TYPE="$2"
            shift 2
            ;;
        --no-tests)
            BUILD_TESTS=OFF
            shift
            ;;
        --no-samples)
            BUILD_SAMPLES=OFF
            shift
            ;;
        --no-gmock)
            BUILD_GMOCK=OFF
            shift
            ;;
        --shared)
            BUILD_SHARED_LIBS=ON
            shift
            ;;
        -j|--jobs)
            JOBS="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=ON
            shift
            ;;
        --clean)
            CLEAN=ON
            shift
            ;;
        --install)
            INSTALL=ON
            shift
            ;;
        *)
            print_error "未知选项: $1"
            print_help
            exit 1
            ;;
    esac
done

# 显示编译配置
print_info "开始编译 Google Test 框架"
echo ""
echo "编译配置:"
echo "  编译类型:       $BUILD_TYPE"
echo "  构建 GoogleMock: $BUILD_GMOCK"
echo "  构建 tests:     $BUILD_TESTS"
echo "  构建 samples:   $BUILD_SAMPLES"
echo "  库类型:         $([ "$BUILD_SHARED_LIBS" = "ON" ] && echo "共享库" || echo "静态库")"
echo "  并行任务:       $JOBS"
echo "  安装:           $([ "$INSTALL" = "ON" ] && echo "是" || echo "否")"
echo ""

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_CMAKE_DIR="$PROJECT_DIR/build/cmake"

# 清空 build 目录（如果指定了 --clean）
if [ "$CLEAN" = "ON" ]; then
    if [ -d "$BUILD_CMAKE_DIR" ]; then
        print_warning "删除现有 build/cmake 目录: $BUILD_CMAKE_DIR"
        rm -rf "$BUILD_CMAKE_DIR"
    fi
fi

# 创建 cmake build 目录
if [ ! -d "$BUILD_CMAKE_DIR" ]; then
    print_info "创建 cmake 构建目录: $BUILD_CMAKE_DIR"
    mkdir -p "$BUILD_CMAKE_DIR"
fi

cd "$BUILD_CMAKE_DIR"

# 运行 CMake
print_info "运行 CMake 配置..."
cmake \
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
    -DBUILD_GMOCK="$BUILD_GMOCK" \
    -DBUILD_SHARED_LIBS="$BUILD_SHARED_LIBS" \
    -Dgtest_build_tests="$BUILD_TESTS" \
    -Dgtest_build_samples="$BUILD_SAMPLES" \
    -Dgmock_build_tests="$BUILD_TESTS" \
    "$PROJECT_DIR"

if [ $? -ne 0 ]; then
    print_error "CMake 配置失败！"
    exit 1
fi

print_success "CMake 配置成功"
echo ""

# 编译
print_info "编译项目（使用 $JOBS 个并行任务）..."
if make -j "$JOBS"; then
    print_success "编译成功！"
else
    print_error "编译失败！"
    exit 1
fi

echo ""

# 运行测试
if [ "$BUILD_TESTS" = "ON" ]; then
    print_info "运行测试..."
    if make test; then
        print_success "所有测试通过！"
    else
        print_warning "部分测试失败，但编译已完成"
    fi
    echo ""
fi

# 显示编译结果信息
print_info "编译结果信息:"
echo "  build 目录:     $BUILD_CMAKE_DIR"
if [ -d "$BUILD_CMAKE_DIR/lib" ]; then
    echo "  库文件位置:     $BUILD_CMAKE_DIR/lib"
    ls -lh "$BUILD_CMAKE_DIR/lib" 2>/dev/null || true
fi
if [ -d "$BUILD_CMAKE_DIR/bin" ]; then
    echo "  可执行文件位置: $BUILD_CMAKE_DIR/bin"
    ls -lh "$BUILD_CMAKE_DIR/bin" 2>/dev/null | head -5 || true
fi
echo ""

# 安装（如果指定了 --install）
if [ "$INSTALL" = "ON" ]; then
    print_info "安装到系统..."
    if sudo make install; then
        print_success "安装成功！"
    else
        print_error "安装失败！"
        exit 1
    fi
    echo ""
fi

# 显示使用说明
print_success "编译完成！"
echo ""
echo "${BLUE}后续步骤:${NC}"
echo "  1. 查看编译结果:"
echo "     cd $BUILD_CMAKE_DIR"
echo "     ls -la lib/"
echo "     ls -la bin/"
echo ""
echo "  2. 运行示例测试:"
if [ "$BUILD_SAMPLES" = "ON" ]; then
    echo "     $BUILD_CMAKE_DIR/bin/sample1_unittest"
fi
echo ""
echo "  3. 在项目中使用 Google Test:"
echo "     target_link_libraries(your_test gtest_main)"
echo ""
echo "  4. 查看更多选项:"
echo "     ./build.sh --help"
echo ""

exit 0

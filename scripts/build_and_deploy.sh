#!/bin/bash

# Flutter项目自动化构建和部署脚本
# 支持多平台构建、自动化测试、版本管理和部署

set -e  # 遇到错误立即退出

# 脚本配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$SCRIPT_DIR/deploy_config.json"
VERSION_FILE="$PROJECT_ROOT/version.json"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查依赖
check_dependencies() {
    log_info "检查构建依赖..."

    # 检查Flutter
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter未安装或未添加到PATH"
        exit 1
    fi

    # 检查Git
    if ! command -v git &> /dev/null; then
        log_error "Git未安装或未添加到PATH"
        exit 1
    fi

    # 检查Python (用于部署脚本)
    if ! command -v python3 &> /dev/null; then
        log_error "Python3未安装或未添加到PATH"
        exit 1
    fi

    log_success "依赖检查完成"
}

# 加载配置
load_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_info "创建默认配置文件..."
        python3 -c "
import json
import os

default_config = {
    'build': {
        'android': {'enabled': True, 'debug': True, 'release': True, 'aab': True},
        'ios': {'enabled': True, 'debug': True, 'release': True},
        'web': {'enabled': True, 'pwa': True},
        'windows': {'enabled': True, 'arch': ['x64', 'x86']},
        'linux': {'enabled': True, 'arch': ['x64', 'arm64']},
        'macos': {'enabled': True, 'arch': ['x64', 'arm64']}
    },
    'test': {
        'enabled': True,
        'unit': True,
        'widget': True,
        'integration': True,
        'coverage': True
    },
    'deploy': {
        'environments': ['dev', 'staging', 'prod'],
        'auto_version': True,
        'git': {'auto_commit': False, 'auto_tag': False, 'auto_push': False},
        'release': {'github': True, 'firebase': False, 'play_store': False}
    }
}

with open('$CONFIG_FILE', 'w', encoding='utf-8') as f:
    json.dump(default_config, f, indent=2, ensure_ascii=False)
"
    fi

    log_success "配置加载完成"
}

# 版本管理
version_management() {
    local version_type=${1:-build}

    if [[ ! -f "$VERSION_FILE" ]]; then
        log_info "创建版本文件..."
        python3 -c "
import json
from datetime import datetime

version_info = {
    'version': '1.0.0',
    'build': 0,
    'timestamp': datetime.now().isoformat(),
    'changelog': '初始版本'
}

with open('$VERSION_FILE', 'w', encoding='utf-8') as f:
    json.dump(version_info, f, indent=2, ensure_ascii=False)
"
    fi

    # 更新版本号
    python3 -c "
import json
from datetime import datetime

with open('$VERSION_FILE', 'r', encoding='utf-8') as f:
    version_info = json.load(f)

version_parts = version_info['version'].split('.')
major, minor, patch = int(version_parts[0]), int(version_parts[1]), int(version_parts[2])

if '$version_type' == 'major':
    major += 1
    minor = 0
    patch = 0
elif '$version_type' == 'minor':
    minor += 1
    patch = 0
elif '$version_type' == 'patch':
    patch += 1
else:  # build
    version_info['build'] += 1

version_info['version'] = f'{major}.{minor}.{patch}'
version_info['timestamp'] = datetime.now().isoformat()

with open('$VERSION_FILE', 'w', encoding='utf-8') as f:
    json.dump(version_info, f, indent=2, ensure_ascii=False)

print(f'版本更新为: {version_info[\"version\"]} (Build {version_info[\"build\"]})')
"
}

# 清理项目
clean_project() {
    log_info "清理项目..."

    cd "$PROJECT_ROOT"

    # Flutter清理
    flutter clean

    # 删除构建目录
    rm -rf build/
    rm -rf dist/

    # 删除临时文件
    find . -name "*.log" -type f -delete
    find . -name ".DS_Store" -type f -delete

    log_success "项目清理完成"
}

# 获取依赖
get_dependencies() {
    log_info "获取项目依赖..."

    cd "$PROJECT_ROOT"

    # Flutter依赖
    flutter pub get

    # 如果有package.json，获取Node.js依赖
    if [[ -f "package.json" ]]; then
        if command -v npm &> /dev/null; then
            npm install
        elif command -v yarn &> /dev/null; then
            yarn install
        fi
    fi

    log_success "依赖获取完成"
}

# 运行测试
run_tests() {
    log_info "运行测试..."

    cd "$PROJECT_ROOT"

    # Flutter测试
    flutter test

    # 生成覆盖率报告
    if [[ -f "test/coverage_test.dart" ]]; then
        flutter test --coverage
        log_info "测试覆盖率报告已生成: coverage/lcov.info"
    fi

    # 代码格式检查
    flutter analyze

    log_success "测试完成"
}

# 构建Android
build_android() {
    log_info "构建Android应用..."

    cd "$PROJECT_ROOT"

    # Debug构建
    flutter build apk --debug --output=build/android/debug/

    # Release构建
    flutter build apk --release --output=build/android/release/

    # AAB构建
    flutter build appbundle --release --output=build/android/release/

    log_success "Android构建完成"
}

# 构建iOS
build_ios() {
    log_info "构建iOS应用..."

    cd "$PROJECT_ROOT"

    # Debug构建
    flutter build ios --debug --simulator

    # Release构建
    flutter build ios --release

    # Archive
    if command -v xcodebuild &> /dev/null; then
        xcodebuild -workspace ios/Runner.xcworkspace \
                   -scheme Runner \
                   -configuration Release \
                   -destination generic/platform=iOS \
                   archive -archivePath=build/ios/Runner.xcarchive
    fi

    log_success "iOS构建完成"
}

# 构建Web
build_web() {
    log_info "构建Web应用..."

    cd "$PROJECT_ROOT"

    # Web构建
    flutter build web --base-href=/ --web-renderer=html

    # PWA构建
    if grep -q '"pwa": true' "$CONFIG_FILE"; then
        flutter build web --pwa
    fi

    log_success "Web构建完成"
}

# 构建桌面应用
build_desktop() {
    log_info "构建桌面应用..."

    cd "$PROJECT_ROOT"

    # 检查Flutter桌面支持
    if ! flutter config | grep -q "enable-windows-desktop"; then
        flutter config --enable-windows-desktop
    fi
    if ! flutter config | grep -q "enable-linux-desktop"; then
        flutter config --enable-linux-desktop
    fi
    if ! flutter config | grep -q "enable-macos-desktop"; then
        flutter config --enable-macos-desktop
    fi

    # Windows构建
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        flutter build windows --release
    fi

    # Linux构建
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        flutter build linux --release
    fi

    # macOS构建
    if [[ "$OSTYPE" == "darwin"* ]]; then
        flutter build macos --release
    fi

    log_success "桌面应用构建完成"
}

# 创建发布归档
create_release_archive() {
    log_info "创建发布归档..."

    cd "$PROJECT_ROOT"

    # 读取版本信息
    VERSION=$(python3 -c "
import json
with open('$VERSION_FILE', 'r', encoding='utf-8') as f:
    version_info = json.load(f)
print(f'{version_info[\"version\"]}-build{version_info[\"build\"]}')
")

    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    ARCHIVE_NAME="chaoxingrc_v${VERSION}_${TIMESTAMP}"

    # 创建发布目录
    mkdir -p dist/

    # 复制构建产物
    if [[ -d "build" ]]; then
        cp -r build/ "dist/${ARCHIVE_NAME}/"
    fi

    # 复制版本文件
    cp "$VERSION_FILE" "dist/${ARCHIVE_NAME}/"

    # 创建归档
    cd dist/
    tar -czf "${ARCHIVE_NAME}.tar.gz" "${ARCHIVE_NAME}/"

    # 计算MD5
    if command -v md5 &> /dev/null; then
        md5 "${ARCHIVE_NAME}.tar.gz" > "${ARCHIVE_NAME}.md5"
    elif command -v md5sum &> /dev/null; then
        md5sum "${ARCHIVE_NAME}.tar.gz" > "${ARCHIVE_NAME}.md5"
    fi

    log_success "发布归档创建完成: dist/${ARCHIVE_NAME}.tar.gz"
}

# Git操作
git_operations() {
    local auto_commit=$1
    local auto_tag=$2
    local auto_push=$3

    if [[ "$auto_commit" != "true" ]]; then
        log_info "跳过Git自动提交"
        return
    fi

    cd "$PROJECT_ROOT"

    # 检查Git状态
    if [[ -n $(git status --porcelain) ]]; then
        log_info "Git有未提交的更改，开始提交..."

        # 读取版本信息
        VERSION=$(python3 -c "
import json
with open('$VERSION_FILE', 'r', encoding='utf-8') as f:
    version_info = json.load(f)
print(version_info['version'])
")
        BUILD=$(python3 -c "
import json
with open('$VERSION_FILE', 'r', encoding='utf-8') as f:
    version_info = json.load(f)
print(version_info['build'])
")

        # 添加文件
        git add .

        # 提交
        git commit -m "Build $BUILD - Release $VERSION

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

        # 创建标签
        if [[ "$auto_tag" == "true" ]]; then
            TAG_NAME="v${VERSION}-build${BUILD}"
            git tag -a "$TAG_NAME" -m "Release $TAG_NAME"
            log_info "创建Git标签: $TAG_NAME"
        fi

        # 推送
        if [[ "$auto_push" == "true" ]]; then
            git push origin main
            if [[ "$auto_tag" == "true" ]]; then
                git push origin "$TAG_NAME"
            fi
            log_info "推送到远程仓库"
        fi

        log_success "Git操作完成"
    else
        log_info "没有未提交的更改，跳过Git操作"
    fi
}

# 创建GitHub Release
create_github_release() {
    log_info "创建GitHub Release..."

    # 检查GitHub CLI
    if ! command -v gh &> /dev/null; then
        log_warning "GitHub CLI未安装，跳过GitHub Release创建"
        return
    fi

    cd "$PROJECT_ROOT"

    # 读取版本信息
    VERSION=$(python3 -c "
import json
with open('$VERSION_FILE', 'r', encoding='utf-8') as f:
    version_info = json.load(f)
print(f'{version_info[\"version\"]}-build{version_info[\"build\"]}')
")

    # 检查标签是否存在
    TAG_NAME="v${VERSION}"
    if git tag | grep -q "$TAG_NAME"; then
        log_info "标签 $TAG_NAME 已存在，创建GitHub Release..."

        # 查找最新的发布归档
        LATEST_ARCHIVE=$(ls -t dist/*.tar.gz 2>/dev/null | head -1)
        if [[ -n "$LATEST_ARCHIVE" ]]; then
            gh release create "$TAG_NAME" "$LATEST_ARCHIVE" \
                --title "Release $TAG_NAME" \
                --notes "自动发布版本 $TAG_NAME" \
                --latest
            log_success "GitHub Release创建完成"
        else
            log_warning "未找到发布归档，跳过GitHub Release创建"
        fi
    else
        log_warning "标签 $TAG_NAME 不存在，跳过GitHub Release创建"
    fi
}

# 部署到Firebase
deploy_firebase() {
    log_info "部署到Firebase..."

    # 检查Firebase CLI
    if ! command -v firebase &> /dev/null; then
        log_warning "Firebase CLI未安装，跳过Firebase部署"
        return
    fi

    cd "$PROJECT_ROOT"

    # 检查Firebase项目
    if [[ ! -f "firebase.json" ]]; then
        log_warning "未找到firebase.json，跳过Firebase部署"
        return
    fi

    # 部署Web应用到Firebase Hosting
    if [[ -d "build/web" ]]; then
        firebase deploy --only hosting
        log_success "Firebase部署完成"
    else
        log_warning "未找到Web构建产物，跳过Firebase部署"
    fi
}

# 主函数
main() {
    local version_type=${1:-build}
    local skip_tests=${2:-false}
    local skip_build=${3:-false}
    local platform=${4:-all}
    local auto_commit=${5:-false}
    local auto_tag=${6:-false}
    local auto_push=${7:-false}

    log_info "开始Flutter项目构建和部署..."

    # 检查依赖
    check_dependencies

    # 加载配置
    load_config

    # 版本管理
    if [[ "$skip_build" != "true" ]]; then
        version_management "$version_type"
    fi

    # 清理项目
    clean_project

    # 获取依赖
    get_dependencies

    # 运行测试
    if [[ "$skip_tests" != "true" ]]; then
        run_tests
    fi

    # 构建应用
    if [[ "$skip_build" != "true" ]]; then
        case "$platform" in
            "android")
                build_android
                ;;
            "ios")
                build_ios
                ;;
            "web")
                build_web
                ;;
            "desktop")
                build_desktop
                ;;
            "all")
                build_android
                build_ios
                build_web
                build_desktop
                ;;
            *)
                log_error "未知的平台: $platform"
                exit 1
                ;;
        esac

        # 创建发布归档
        create_release_archive
    fi

    # Git操作
    git_operations "$auto_commit" "$auto_tag" "$auto_push"

    # 创建GitHub Release
    create_github_release

    # Firebase部署
    deploy_firebase

    log_success "构建和部署流程完成！"
}

# 显示帮助信息
show_help() {
    cat << EOF
Flutter项目自动化构建和部署脚本

用法: $0 [选项] [参数]

选项:
    -h, --help          显示帮助信息
    -v, --version TYPE  版本更新类型 (build|patch|minor|major)，默认: build
    -t, --skip-tests    跳过测试
    -b, --skip-build    跳过构建
    -p, --platform P    指定构建平台 (android|ios|web|desktop|all)，默认: all
    -c, --commit        自动提交Git更改
    -g, --tag           自动创建Git标签
    -u, --push          自动推送到远程仓库

示例:
    $0                                          # 默认构建所有平台
    $0 --version patch --platform android      # 发布补丁版本，只构建Android
    $0 --skip-tests --skip-build --commit      # 只提交Git更改，不测试不构建
    $0 --version minor --tag --push            # 发布次版本，创建标签并推送

配置文件:
    scripts/deploy_config.json    # 构建和部署配置
    version.json                  # 版本信息

EOF
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--version)
            version_type="$2"
            shift 2
            ;;
        -t|--skip-tests)
            skip_tests="true"
            shift
            ;;
        -b|--skip-build)
            skip_build="true"
            shift
            ;;
        -p|--platform)
            platform="$2"
            shift 2
            ;;
        -c|--commit)
            auto_commit="true"
            shift
            ;;
        -g|--tag)
            auto_tag="true"
            shift
            ;;
        -u|--push)
            auto_push="true"
            shift
            ;;
        *)
            log_error "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
done

# 设置默认值
version_type=${version_type:-build}
skip_tests=${skip_tests:-false}
skip_build=${skip_build:-false}
platform=${platform:-all}
auto_commit=${auto_commit:-false}
auto_tag=${auto_tag:-false}
auto_push=${auto_push:-false}

# 执行主函数
main "$version_type" "$skip_tests" "$skip_build" "$platform" "$auto_commit" "$auto_tag" "$auto_push"
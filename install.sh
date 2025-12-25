#!/bin/bash

# ByteDance CLI 工具安装脚本
# 支持安装 logid、lark 和 ark 工具

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 默认配置
GITHUB_REPO="DreamCats/byted-cli-scripts"
INSTALL_DIR="$HOME/.local/bin"
TOOLS=("logid" "lark" "ark")
VERSION="latest"
UNINSTALL=false
VERBOSE=false

# 帮助信息
show_help() {
    cat << EOF
ByteDance CLI 工具安装脚本

使用方法: $0 [选项] [工具名]

选项:
    -v, --version <版本>    安装指定版本 (默认: latest)
    -d, --dir <目录>      安装目录 (默认: ~/.local/bin)
    -u, --uninstall       卸载工具
    --verbose             显示详细输出
    -h, --help            显示帮助信息

工具名:
    logid                  日志查询工具
    lark                   Lark API 工具
    ark                    Ark AI 图片生成工具
    all                    安装所有工具 (默认)

示例:
    $0                     # 安装所有工具的最新版本
    $0 logid               # 仅安装 logid
    $0 ark                 # 仅安装 ark
    $0 -v v1.0.0 all       # 安装所有工具的 v1.0.0 版本
    $0 -u                  # 卸载所有工具
    $0 -u ark              # 仅卸载 ark

环境变量:
    HTTP_PROXY             HTTP 代理设置
    HTTPS_PROXY            HTTPS 代理设置

EOF
}

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

log_debug() {
    if [ "$VERBOSE" = true ]; then
        echo -e "[DEBUG] $1"
    fi
}

# 解析参数
parse_args() {
    TOOL_TO_INSTALL="all"

    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--version)
                VERSION="$2"
                shift 2
                ;;
            -d|--dir)
                INSTALL_DIR="$2"
                shift 2
                ;;
            -u|--uninstall)
                UNINSTALL=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            logid|lark|ark|all)
                TOOL_TO_INSTALL="$1"
                shift
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# 检查依赖
check_dependencies() {
    local deps=("curl" "tar")
    local missing_deps=()

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done

    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "缺少依赖: ${missing_deps[*]}"
        log_info "请安装缺失的依赖后重试"
        exit 1
    fi
}

# 检测系统信息
detect_system() {
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)

    case $OS in
        linux*)
            PLATFORM="linux"
            ;;
        darwin*)
            PLATFORM="macos"
            ;;
        mingw*|msys*|cygwin*)
            PLATFORM="windows"
            ;;
        *)
            log_error "不支持的操作系统: $OS"
            exit 1
            ;;
    esac

    case $ARCH in
        x86_64|amd64)
            ARCH="x64"
            ;;
        aarch64|arm64)
            ARCH="arm64"
            ;;
        armv7l)
            ARCH="arm"
            ;;
        *)
            log_error "不支持的架构: $ARCH"
            exit 1
            ;;
    esac

    log_debug "检测到系统: $PLATFORM-$ARCH"
}

# 获取最新版本
get_latest_version() {
    local api_url="https://api.github.com/repos/$GITHUB_REPO/releases/latest"
    local proxy_args=""

    # 设置代理
    if [ -n "$HTTPS_PROXY" ]; then
        proxy_args="-x $HTTPS_PROXY"
    elif [ -n "$HTTP_PROXY" ]; then
        proxy_args="-x $HTTP_PROXY"
    fi

    log_info "正在获取最新版本信息..."

    local response
    if response=$(curl -s $proxy_args "$api_url" 2>/dev/null); then
        VERSION=$(echo "$response" | grep '"tag_name":' | sed -E 's/.*"tag_name": "([^"]+)".*/\1/')
        if [ -z "$VERSION" ]; then
            log_error "无法获取最新版本信息"
            exit 1
        fi
        log_info "最新版本: $VERSION"
    else
        log_error "无法连接到 GitHub API"
        exit 1
    fi
}

# 下载文件
download_file() {
    local url="$1"
    local output="$2"
    local proxy_args=""

    if [ -n "$HTTPS_PROXY" ]; then
        proxy_args="-x $HTTPS_PROXY"
    elif [ -n "$HTTP_PROXY" ]; then
        proxy_args="-x $HTTP_PROXY"
    fi

    log_info "正在下载: $url"

    if curl -L -o "$output" $proxy_args "$url" 2>/dev/null; then
        log_debug "下载完成: $output"
    else
        log_error "下载失败: $url"
        rm -f "$output"
        exit 1
    fi
}

# 验证校验和
verify_checksum() {
    local file="$1"
    local expected_checksum="$2"

    if [ -z "$expected_checksum" ]; then
        log_warning "未提供校验和，跳过验证"
        return 0
    fi

    local actual_checksum
    actual_checksum=$(sha256sum "$file" | awk '{print $1}')

    if [ "$actual_checksum" = "$expected_checksum" ]; then
        log_success "校验和验证通过"
    else
        log_error "校验和验证失败"
        log_debug "期望: $expected_checksum"
        log_debug "实际: $actual_checksum"
        rm -f "$file"
        exit 1
    fi
}

# 安装工具
install_tool() {
    local tool="$1"
    local version="$2"
    local install_dir="$3"

    # 保存原始版本号（带v）用于URL
    local raw_version="$version"
    # 移除版本号前面的 'v' 前缀（如果存在）用于文件名
    version="${version#v}"

    log_info "正在安装 $tool v$version..."

    # 构建下载 URL
    local filename="${tool}-${version}-${PLATFORM}-${ARCH}.tar.gz"
    local download_url="https://github.com/$GITHUB_REPO/releases/download/${raw_version}/$filename"

    # 临时目录
    local temp_dir
    temp_dir=$(mktemp -d)
    trap 'rm -rf "$temp_dir"' EXIT

    # 下载文件
    local archive_path="$temp_dir/$filename"
    download_file "$download_url" "$archive_path"

    # 下载校验和文件（如果存在）
    local checksum_url="https://github.com/$GITHUB_REPO/releases/download/${raw_version}/SHA256SUMS"
    local checksum_path="$temp_dir/SHA256SUMS"
    local expected_checksum=""

    if curl -s -o "$checksum_path" "$checksum_url" 2>/dev/null; then
        expected_checksum=$(grep "$filename" "$checksum_path" 2>/dev/null | awk '{print $1}')
    fi

    # 验证校验和
    verify_checksum "$archive_path" "$expected_checksum"

    # 解压
    log_info "正在解压文件..."
    tar -xzf "$archive_path" -C "$temp_dir"

    # 确保安装目录存在
    mkdir -p "$install_dir"

    # 复制二进制文件
    local binary_name="${tool}-cli"
    if [ "$tool" = "logid" ]; then
        binary_name="logid"
    fi

    local binary_path="$temp_dir/$binary_name"
    if [ -f "$binary_path" ]; then
        cp "$binary_path" "$install_dir/"
        chmod +x "$install_dir/$binary_name"
        log_success "$tool 安装完成: $install_dir/$binary_name"
    else
        log_error "未找到二进制文件: $binary_path"
        exit 1
    fi
}

# 卸载工具
uninstall_tool() {
    local tool="$1"
    local install_dir="$2"

    log_info "正在卸载 $tool..."

    local binary_name="${tool}-cli"
    if [ "$tool" = "logid" ]; then
        binary_name="logid"
    fi

    local binary_path="$install_dir/$binary_name"

    if [ -f "$binary_path" ]; then
        rm -f "$binary_path"
        log_success "$tool 已卸载"
    else
        log_warning "$tool 未安装或不在预期位置"
    fi
}

# 更新 PATH
update_path() {
    local install_dir="$1"
    local shell_rc=""

    # 检测当前 shell
    if [ -n "$BASH_VERSION" ]; then
        shell_rc="$HOME/.bashrc"
    elif [ -n "$ZSH_VERSION" ]; then
        shell_rc="$HOME/.zshrc"
    else
        shell_rc="$HOME/.profile"
    fi

    # 检查 PATH 是否已包含安装目录
    if [[ ":$PATH:" != *":$install_dir:"* ]]; then
        log_info "正在更新 PATH..."

        # 添加到 shell rc 文件
        echo "" >> "$shell_rc"
        echo "# ByteDance CLI tools" >> "$shell_rc"
        echo "export PATH=\"$install_dir:\$PATH\"" >> "$shell_rc"

        log_info "已将 $install_dir 添加到 PATH"
        log_info "请运行以下命令使更改生效:"
        log_info "  source $shell_rc"
    fi
}

# 主函数
main() {
    parse_args "$@"

    if [ "$UNINSTALL" = true ]; then
        # 卸载模式
        if [ "$TOOL_TO_INSTALL" = "all" ]; then
            for tool in "${TOOLS[@]}"; do
                uninstall_tool "$tool" "$INSTALL_DIR"
            done
        else
            uninstall_tool "$TOOL_TO_INSTALL" "$INSTALL_DIR"
        fi
    else
        # 安装模式
        check_dependencies
        detect_system

        if [ "$VERSION" = "latest" ]; then
            get_latest_version
        fi

        # 确保安装目录存在
        mkdir -p "$INSTALL_DIR"

        if [ "$TOOL_TO_INSTALL" = "all" ]; then
            for tool in "${TOOLS[@]}"; do
                install_tool "$tool" "$VERSION" "$INSTALL_DIR"
            done
        else
            install_tool "$TOOL_TO_INSTALL" "$VERSION" "$INSTALL_DIR"
        fi

        # 更新 PATH
        update_path "$INSTALL_DIR"

        # 创建配置文件
        create_config_files

        log_success "安装完成!"
        log_info "安装目录: $INSTALL_DIR"
        log_info "配置文件目录: $HOME/.byted-cli"
        log_info "当前 PATH: $PATH"
    fi
}

# 创建配置文件
create_config_files() {
    local config_dir="$HOME/.byted-cli"

    # 创建配置目录
    if [ ! -d "$config_dir" ]; then
        mkdir -p "$config_dir"
        log_info "创建配置目录: $config_dir"
    fi

    # 创建 logid 配置
    local logid_env="$config_dir/logid/.env"
    if [ ! -f "$logid_env" ]; then
        mkdir -p "$config_dir/logid"
        cat > "$logid_env" << 'EOF'
# logid 配置文件
# 字节跳动手动设置的 CAS SESSION 环境变量示例
# 复制此文件为 .env 并填入你的实际 CAS SESSION 值

# 美区 CAS SESSION
CAS_SESSION_US=your_us_session_cookie_here

# 国际化区域 CAS SESSION
CAS_SESSION_I18n=your_i18n_session_cookie_here

# 中国区 CAS SESSION（如果需要）
CAS_SESSION_CN=your_cn_session_cookie_here

# 通用 CAS SESSION（当区域特定的 CAS_SESSION 未设置时使用）
CAS_SESSION=your_default_session_cookie_here

# 日志开关（可选，默认关闭）
# 设置为 true, on, 1, yes 启用日志，false, off, 0, no 禁用日志
ENABLE_LOGGING=false

# 日志级别（当 ENABLE_LOGGING=true 时生效）
RUST_LOG=info
EOF
        log_success "创建 logid 配置文件: $logid_env"
    fi

    # 创建 lark 配置
    local lark_env="$config_dir/lark/.env"
    if [ ! -f "$lark_env" ]; then
        mkdir -p "$config_dir/lark"
        cat > "$lark_env" << 'EOF'
# Lark API 配置
# 复制此文件为 .env 并填入你的应用信息

# Lark 应用的 App ID
APP_ID=your_app_id_here

# Lark 应用的 App Secret
APP_SECRET=your_app_secret_here
EOF
        log_success "创建 lark 配置文件: $lark_env"
    fi

    # 创建 ark 配置
    local ark_env="$config_dir/ark/.env"
    if [ ! -f "$ark_env" ]; then
        mkdir -p "$config_dir/ark"
        cat > "$ark_env" << 'EOF'
# Ark API 配置
# 复制此文件为 .env 并填入你的认证信息

# CAS_SESSION_API Cookie（必填）
# 获取方式：登录火山引擎控制台 > F12 > Application > Cookies > CAS_SESSION_API
CAS_SESSION_API=your_cas_session_api_cookie_here

# 账户 ID（可选，默认：2100583705）
ARK_ACCOUNT_ID=2100583705

# Web ID（可选）
ARK_WEB_ID=your_web_id_here
EOF
        log_success "创建 ark 配置文件: $ark_env"
    fi

    # 设置权限
    chmod 600 "$logid_env" "$lark_env" "$ark_env" 2>/dev/null || true
}

# 运行主函数
main "$@"
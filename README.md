# byted-cli-scripts

ByteDance CLI 工具集安装脚本，支持快速安装 `logid`、`lark` 和 `ark` 三个命令行工具。

## 工具列表

### logid - 日志查询工具
- 支持多区域查询（美区/国际化/中国区）
- JWT 认证自动管理
- 消息过滤（PSM 和自定义规则）
- 多种输出格式（文本/JSON）

### lark - Lark API 交互工具
- 知识空间管理和文档操作
- 文档创建、编辑、转换
- 消息服务（发送消息、搜索聊天）
- 文件管理（上传、导入）

### ark - Ark AI 图片生成工具
- AI 图片生成（自然语言描述生成高质量图片）
- SSE 流式响应（实时获取图片生成进度）
- JWT 认证（自动获取和刷新认证令牌，支持令牌缓存）

## 安装

### 快速安装（推荐）

#### Unix/Linux/macOS
```bash
curl -sSL https://raw.githubusercontent.com/DreamCats/byted-cli-scripts/main/install.sh | bash
```

#### Windows
```powershell
iwr -useb https://raw.githubusercontent.com/DreamCats/byted-cli-scripts/main/install.ps1 | iex
```

### 高级安装选项

下载安装脚本后可使用以下选项：

```bash
# 安装所有工具（默认）
./install.sh

# 仅安装特定工具
./install.sh logid
./install.sh lark
./install.sh ark

# 安装指定版本
./install.sh -v v1.0.0 all

# 自定义安装目录
./install.sh -d /usr/local/bin all

# 卸载工具
./install.sh -u
./install.sh -u ark
```

#### 参数说明
| 选项 | 说明 |
|------|------|
| `-v, --version <版本>` | 安装指定版本（默认: latest） |
| `-d, --dir <目录>` | 安装目录（默认: ~/.local/bin） |
| `-u, --uninstall` | 卸载工具 |
| `--verbose` | 显示详细输出 |
| `-h, --help` | 显示帮助信息 |

#### 支持的工具
- `logid` - 日志查询工具
- `lark` - Lark API 工具
- `ark` - Ark AI 图片生成工具
- `all` - 安装所有工具（默认）

## 配置

安装完成后，配置文件位于 `~/.byted-cli/` 目录下：

### logid 配置
编辑 `~/.byted-cli/logid/.env`：

```bash
# 美区 CAS SESSION
CAS_SESSION_US=your_us_session_cookie_here

# 国际化区域 CAS SESSION
CAS_SESSION_I18n=your_i18n_session_cookie_here

# 中国区 CAS SESSION（如果需要）
CAS_SESSION_CN=your_cn_session_cookie_here

# 通用 CAS SESSION（当区域特定的 CAS_SESSION 未设置时使用）
CAS_SESSION=your_default_session_cookie_here

# 日志开关（可选，默认关闭）
ENABLE_LOGGING=false
RUST_LOG=info
```

### lark 配置
编辑 `~/.byted-cli/lark/.env`：

```bash
# Lark 应用的 App ID
APP_ID=your_app_id_here

# Lark 应用的 App Secret
APP_SECRET=your_app_secret_here
```

### ark 配置
编辑 `~/.byted-cli/ark/.env`：

```bash
# CAS_SESSION_API Cookie（必填）
CAS_SESSION_API=your_cas_session_api_cookie_here

# 账户 ID（可选，默认：2100583705）
ARK_ACCOUNT_ID=2100583705

# Web ID（可选）
ARK_WEB_ID=your_web_id_here
```

## 环境变量支持

安装脚本支持通过环境变量设置代理：

```bash
export HTTP_PROXY=http://proxy.example.com:8080
export HTTPS_PROXY=http://proxy.example.com:8080

./install.sh
```

## 系统要求

- **操作系统**: Linux, macOS, Windows
- **架构**: x64, arm64
- **依赖**: curl, tar

## 工作流

本项目使用 GitHub Actions 从私有仓库 `DreamCats/byted-cli` 自动接收构建产物并发布到公开仓库。

## 许可证

MIT License

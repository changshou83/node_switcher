# Node Switcher

Windows 环境下的 Node.js 版本快速切换工具，支持批处理（.bat）和 PowerShell（.ps1）双脚本。

## 为什么需要这个工具？

在日常开发中，你可能会遇到以下问题：

- **工具版本要求**：像 Claude Code 这类 AI 辅助工具可能需要特定的 Node.js 版本
- **不想污染全局环境**：希望为不同项目或工具单独配置 Node.js 版本，而不影响其他应用

Node Switcher 让你可以在一个命令行窗口中快速切换 Node.js 版本，**仅影响当前会话**，不会修改全局配置，安全且灵活。

## 功能特性

- 🔄 快速切换本地多个 Node.js 版本
- ⚙️ 支持配置默认版本，一键切换
- 🎨 交互式版本选择界面
- 💾 配置持久化存储（`%USERPROFILE%\.node_switcher\config`）
- 🖥️ 支持 CMD 和 PowerShell 双环境
- 🔒 会话级别切换，不影响全局环境

## 安装

1. 克隆或下载本项目
2. 将 `node_switcher.bat` 或 `node_switcher.ps1` 放置到系统 PATH 中的目录，或直接使用完整路径调用

## 快速开始

### 1. 配置版本目录

```cmd
# CMD
node_switcher set NODE_VERSIONS_DIR=C:\nodejs

# PowerShell
.\node_switcher.ps1 set NODE_VERSIONS_DIR=C:\nodejs
```

### 2. （可选）设置默认版本

```cmd
# CMD
node_switcher set DEFAULT_VERSION=v18.17.0

# PowerShell
.\node_switcher.ps1 set DEFAULT_VERSION=v18.17.0
```

### 3. 切换版本

```cmd
# 直接使用（若有默认版本则自动切换）
node_switcher

# 交互式选择
node_switcher select
```

## 使用方法

| 命令 | 说明 |
|------|------|
| `node_switcher` | 使用默认版本（若已设置），否则进入交互选择 |
| `node_switcher select` | 强制进入交互式选择 |
| `node_switcher show` | 显示当前配置 |
| `node_switcher set KEY=VALUE` | 更新配置项 |
| `node_switcher help` | 显示帮助信息 |

### 配置项说明

- `NODE_VERSIONS_DIR`：存放 Node.js 版本的目录（每个版本一个子文件夹）
- `DEFAULT_VERSION`：默认使用的 Node.js 版本名称

### 项目级配置

在项目根目录创建 `.node_switcher` 文件，可覆盖用户级配置：

```
NODE_VERSIONS_DIR=C:\nodejs
DEFAULT_VERSION=v18.17.0
```

**配置优先级**：项目配置 > 用户配置

例如：
- 用户配置 `DEFAULT_VERSION=v20.10.0`
- 项目配置 `DEFAULT_VERSION=v18.17.0`
- 最终使用：`v18.17.0`（项目配置优先）

## 目录结构示例

```
C:\nodejs\
├── v16.20.0\
├── v18.17.0\
├── v20.10.0\
└── v21.6.0\
```

## 注意事项

- 切换版本仅在当前会话生效，新终端需重新运行命令
- 配置文件位于 `%USERPROFILE%\.node_switcher\config`
- 确保各版本目录下包含可执行的 `node.exe`

## 许可证

MIT License
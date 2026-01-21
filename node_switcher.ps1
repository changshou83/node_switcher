#Requires -Version 5.1

param(
    [Parameter(Position = 0)]
    [string]$Command = "",
    
    [Parameter(Position = 1, ValueFromRemainingArguments)]
    [string[]]$Arguments
)

# Save original PATH before modifications
$ORIGINAL_PATH = $env:PATH

$USER_DIR = Join-Path $env:USERPROFILE ".node_switcher"
$CONFIG_FILE = Join-Path $USER_DIR "config"

# Default configuration values
$NODE_VERSIONS_DIR = ""
$DEFAULT_VERSION = ""

# Load configuration from file
if (Test-Path $CONFIG_FILE) {
    Get-Content $CONFIG_FILE | ForEach-Object {
        if ($_ -match "^NODE_VERSIONS_DIR=(.+)$") {
            $NODE_VERSIONS_DIR = $Matches[1].Trim()
        } elseif ($_ -match "^DEFAULT_VERSION=(.+)$") {
            $DEFAULT_VERSION = $Matches[1].Trim()
        }
    }
}

# Load project-level configuration (overrides user config)
$PROJECT_CONFIG = Join-Path $PWD ".node_switcher"
if (Test-Path $PROJECT_CONFIG) {
    Get-Content $PROJECT_CONFIG | ForEach-Object {
        if ($_ -match "^NODE_VERSIONS_DIR=(.+)$") {
            $NODE_VERSIONS_DIR = $Matches[1].Trim()
        } elseif ($_ -match "^DEFAULT_VERSION=(.+)$") {
            $DEFAULT_VERSION = $Matches[1].Trim()
        }
    }
}

# Handle set command
if ($Command -eq "set") {
    if ($Arguments.Count -eq 0 -or $Arguments[0] -notmatch "^.+=.+$") {
        Write-Host "Error: Please specify KEY=VALUE"
        exit 1
    }

    # Ensure config directory exists
    if (-not (Test-Path $USER_DIR)) {
        New-Item -ItemType Directory -Path $USER_DIR -Force | Out-Null
    }

    $ARG = $Arguments[0]
    $KEY_ONLY = ($ARG -split "=", 2)[0]
    $VALUE = ($ARG -split "=", 2)[1]

    # Build new config in memory
    $NODE_VERSIONS_DIR_TMP = $NODE_VERSIONS_DIR
    $DEFAULT_VERSION_TMP = $DEFAULT_VERSION

    if ($KEY_ONLY -ieq "NODE_VERSIONS_DIR") {
        $NODE_VERSIONS_DIR_TMP = $VALUE
    } elseif ($KEY_ONLY -ieq "DEFAULT_VERSION") {
        $DEFAULT_VERSION_TMP = $VALUE
    }

    # Write new config
    @"
NODE_VERSIONS_DIR=$NODE_VERSIONS_DIR_TMP
DEFAULT_VERSION=$DEFAULT_VERSION_TMP
"@ | Out-File -FilePath $CONFIG_FILE -Encoding UTF8

    Write-Host "Configuration updated: $KEY_ONLY=$VALUE"
    exit 0
}

# Handle show command
if ($Command -eq "show") {
    Write-Host "Current Configuration:"
    Write-Host "======================="
    Write-Host "NODE_VERSIONS_DIR=$NODE_VERSIONS_DIR"
    Write-Host "DEFAULT_VERSION=$DEFAULT_VERSION"
    Write-Host ""
    Write-Host "Configuration Sources:"
    Write-Host "  User config: $CONFIG_FILE"
    $PROJECT_CONFIG = Join-Path $PWD ".node_switcher"
    if (Test-Path $PROJECT_CONFIG) {
        Write-Host "  Project config: $PROJECT_CONFIG (overrides user config)"
    } else {
        Write-Host "  Project config: Not found"
    }
    exit 0
}

# Handle select command (skip default, interactive selection)
if ($Command -eq "select") {
    InteractiveSelection
    exit
}

# Handle help command
if ($Command -eq "help") {
    Write-Host "Node Switcher Usage:"
    Write-Host ""
    Write-Host "  node_switcher.ps1               - Select version (use default if set)"
    Write-Host "  node_switcher.ps1 select        - Interactive selection (skip default)"
    Write-Host "  node_switcher.ps1 show          - Show current configuration"
    Write-Host "  node_switcher.ps1 set KEY=VALUE - Update configuration"
    Write-Host "  node_switcher.ps1 help          - Show this help message"
    Write-Host ""
    Write-Host "Configuration Options:"
    Write-Host "  NODE_VERSIONS_DIR  - Directory containing Node.js versions"
    Write-Host "  DEFAULT_VERSION    - Default version (if set, auto-switch to it)"
    exit 0
}

# Validate configuration
if ([string]::IsNullOrEmpty($NODE_VERSIONS_DIR)) {
    Write-Host "Error: NODE_VERSIONS_DIR not configured"
    Write-Host ""
    Write-Host "Configuration file: $CONFIG_FILE"
    Write-Host ""
    Write-Host "Please set up your configuration first:"
    Write-Host "  node_switcher.ps1 set NODE_VERSIONS_DIR=YOUR_PATH"
    Write-Host "  node_switcher.ps1 set DEFAULT_VERSION=YOUR_VERSION"
    Write-Host ""
    Write-Host "For more information, run: node_switcher.ps1 help"
    exit 1
}

# Check if versions directory exists
if (-not (Test-Path $NODE_VERSIONS_DIR)) {
    Write-Host "Error: Versions directory not found: $NODE_VERSIONS_DIR"
    Write-Host ""
    Write-Host "Please check your configuration with: node_switcher.ps1 show"
    Write-Host ""
    Write-Host "To update the path, run:"
    Write-Host "  node_switcher.ps1 set NODE_VERSIONS_DIR=YOUR_PATH"
    exit 1
}

# If default version is configured (not empty), switch directly
$SWITCH_DONE = $false
if (-not [string]::IsNullOrEmpty($DEFAULT_VERSION)) {
    $DEFAULT_PATH = Join-Path $NODE_VERSIONS_DIR $DEFAULT_VERSION
    if (Test-Path $DEFAULT_PATH) {
        $SELECTED_PATH = $DEFAULT_PATH
        $env:PATH = "$SELECTED_PATH;$ORIGINAL_PATH"
        Write-Host "Node.js version switched to: $DEFAULT_VERSION"
        Write-Host "Current Node.js version:"
        node --version
        $SWITCH_DONE = $true
    } else {
        Write-Host "Warning: Default version $DEFAULT_VERSION not found, falling back to interactive mode"
    }
}

# If not switched, do interactive selection
if (-not $SWITCH_DONE) {
    InteractiveSelection
}

function InteractiveSelection {
    # Validate configuration
    if ([string]::IsNullOrEmpty($NODE_VERSIONS_DIR)) {
        Write-Host "Error: NODE_VERSIONS_DIR not configured"
        Write-Host ""
        Write-Host "Configuration file: $CONFIG_FILE"
        Write-Host ""
        Write-Host "Please set up your configuration first:"
        Write-Host "  node_switcher.ps1 set NODE_VERSIONS_DIR=YOUR_PATH"
        Write-Host "  node_switcher.ps1 set DEFAULT_VERSION=YOUR_VERSION"
        Write-Host ""
        Write-Host "For more information, run: node_switcher.ps1 help"
        exit 1
    }

    # Check if versions directory exists
    if (-not (Test-Path $NODE_VERSIONS_DIR)) {
        Write-Host "Error: Versions directory not found: $NODE_VERSIONS_DIR"
        Write-Host ""
        Write-Host "Please check your configuration with: node_switcher.ps1 show"
        Write-Host ""
        Write-Host "To update the path, run:"
        Write-Host "  node_switcher.ps1 set NODE_VERSIONS_DIR=YOUR_PATH"
        exit 1
    }

    # Show current Node.js version
    Write-Host "Current Node.js version:"
    try {
        node --version 2>$null
    } catch {
        Write-Host "Node.js not detected"
    }

    # List available versions
    Write-Host ""
    Write-Host "Available Node.js versions:"
    Write-Host "======================="

    $VERSIONS = Get-ChildItem -Path $NODE_VERSIONS_DIR -Directory | Select-Object -ExpandProperty Name

    if ($VERSIONS.Count -eq 0) {
        Write-Host "No available Node.js versions found in: $NODE_VERSIONS_DIR"
        Write-Host ""
        Write-Host "Please check your versions directory and ensure it contains Node.js version folders."
        Write-Host ""
        Write-Host "Current configuration:"
        & $PSScriptRoot\node_switcher.ps1 show
        exit 1
    }

    for ($i = 0; $i -lt $VERSIONS.Count; $i++) {
        Write-Host "$($i + 1). $($VERSIONS[$i])"
    }

    # User selects version
    Write-Host ""
    $CHOICE = Read-Host "Please enter version number (1-$($VERSIONS.Count))"

    # Validate input and switch version
    if ($CHOICE -notmatch "^\d+$" -or [int]$CHOICE -lt 1 -or [int]$CHOICE -gt $VERSIONS.Count) {
        Write-Host "Error: Please enter a number between 1-$($VERSIONS.Count)"
        exit 1
    }

    # Build new PATH
    $SELECTED_VERSION = $VERSIONS[[int]$CHOICE - 1]
    $SELECTED_PATH = Join-Path $NODE_VERSIONS_DIR $SELECTED_VERSION
    $env:PATH = "$SELECTED_PATH;$ORIGINAL_PATH"

    # Show switch result
    Write-Host ""
    Write-Host "Node.js version switched to: $SELECTED_VERSION"
}
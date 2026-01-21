@echo off
setlocal enabledelayedexpansion

:: Save original PATH before modifications
set "ORIGINAL_PATH=%PATH%"

set "USER_DIR=%USERPROFILE%\.node_switcher"
set "CONFIG_FILE=%USER_DIR%\config"

:: Default configuration values
set "NODE_VERSIONS_DIR="
set "DEFAULT_VERSION="

:: Load configuration from file
if exist "%CONFIG_FILE%" (
    for /f "usebackq tokens=1,* delims==" %%a in ("%CONFIG_FILE%") do (
        if /i "%%a"=="NODE_VERSIONS_DIR" set "NODE_VERSIONS_DIR=%%b"
        if /i "%%a"=="DEFAULT_VERSION" set "DEFAULT_VERSION=%%b"
    )
)

:: Load project-level configuration (overrides user config)
set "PROJECT_CONFIG=%CD%\.node_switcher"
if exist "%PROJECT_CONFIG%" (
    for /f "usebackq tokens=1,* delims==" %%a in ("%PROJECT_CONFIG%") do (
        if /i "%%a"=="NODE_VERSIONS_DIR" set "NODE_VERSIONS_DIR=%%b"
        if /i "%%a"=="DEFAULT_VERSION" set "DEFAULT_VERSION=%%b"
    )
)

:: Trim spaces from DEFAULT_VERSION
for /f "tokens=*" %%a in ("%DEFAULT_VERSION%") do set "DEFAULT_VERSION=%%a"

:: Handle set command
if "%~1"=="" goto after_commands
if /i "%~1"=="set" (
    if "%~2"=="" (
        echo Error: Please specify KEY=VALUE
        exit /b 1
    )

    :: Ensure config directory exists
    2>nul mkdir "%USER_DIR%"

    :: Get the full argument (including = and value)
    for /f "tokens=2" %%a in ("%*") do set "ARG=%%a"

    :: Extract KEY (before first =)
    for /f "delims==" %%k in ("!ARG!") do set "KEY_ONLY=%%k"

    :: Extract VALUE (after first =)
    for /f "tokens=2 delims==" %%v in ("!ARG!") do set "VALUE=%%v"

    :: Build new config in memory
    set "NODE_VERSIONS_DIR_TMP=!NODE_VERSIONS_DIR!"
    set "DEFAULT_VERSION_TMP=!DEFAULT_VERSION!"

    if /i "!KEY_ONLY!"=="NODE_VERSIONS_DIR" set "NODE_VERSIONS_DIR_TMP=!VALUE!"
    if /i "!KEY_ONLY!"=="DEFAULT_VERSION" set "DEFAULT_VERSION_TMP=!VALUE!"

    :: Write new config
    >"%CONFIG_FILE%" (
        echo NODE_VERSIONS_DIR=!NODE_VERSIONS_DIR_TMP!
        echo DEFAULT_VERSION=!DEFAULT_VERSION_TMP!
    )

    echo Configuration updated: !KEY_ONLY!=!VALUE!
    exit /b 0
)

:: Handle show command
if /i "%~1"=="show" (
    echo Current Configuration:
    echo =======================
    echo NODE_VERSIONS_DIR=!NODE_VERSIONS_DIR!
    echo DEFAULT_VERSION=!DEFAULT_VERSION!
    echo.
    echo Configuration Sources:
    echo   User config: %CONFIG_FILE%
    if exist "%PROJECT_CONFIG%" (
        echo   Project config: %PROJECT_CONFIG% ^(overrides user config^)
    ) else (
        echo   Project config: Not found
    )
    exit /b 0
)

:: Handle select command (skip default, interactive selection)
if /i "%~1"=="select" (
    goto interactive_selection
)

:: Handle help command
if /i "%~1"=="help" (
    echo Node Switcher Usage:
    echo.
    echo   node_switcher               - Select version (use default if set)
    echo   node_switcher select        - Interactive selection (skip default)
    echo   node_switcher show          - Show current configuration
    echo   node_switcher set KEY=VALUE - Update configuration
    echo   node_switcher help          - Show this help message
    echo.
    echo Configuration Options:
    echo   NODE_VERSIONS_DIR  - Directory containing Node.js versions
    echo   DEFAULT_VERSION    - Default version (if set, auto-switch to it)
    exit /b 0
)

:after_commands

:: Validate configuration
if "!NODE_VERSIONS_DIR!"=="" (
    echo Error: NODE_VERSIONS_DIR not configured
    echo.
    echo Configuration file: %CONFIG_FILE%
    echo.
    echo Please set up your configuration first:
    echo   node_switcher set NODE_VERSIONS_DIR=YOUR_PATH
    echo   node_switcher set DEFAULT_VERSION=YOUR_VERSION
    echo.
    echo For more information, run: node_switcher help
    exit /b 1
)

:: Check if versions directory exists
if not exist "!NODE_VERSIONS_DIR!" (
    echo Error: Versions directory not found: !NODE_VERSIONS_DIR!
    echo.
    echo Please check your configuration with: node_switcher show
    echo.
    echo To update the path, run:
    echo   node_switcher set NODE_VERSIONS_DIR=YOUR_PATH
    exit /b 1
)

:: If default version is configured (not empty), switch directly
set "SWITCH_DONE=0"
if not "!DEFAULT_VERSION!"=="" (
    if exist "!NODE_VERSIONS_DIR!\!DEFAULT_VERSION!" (
        set "SELECTED_PATH=!NODE_VERSIONS_DIR!\!DEFAULT_VERSION!"
        set "PATH=!SELECTED_PATH!;!ORIGINAL_PATH!"
        echo Node.js version switched to: !DEFAULT_VERSION!
        echo Current Node.js version:
        node --version
        for /f "delims=" %%p in ("!PATH!") do set "FINAL_PATH=%%p"
        set "SWITCH_DONE=1"
    ) else (
        echo Warning: Default version !DEFAULT_VERSION! not found, falling back to interactive mode
    )
)

:: If not switched, do interactive selection
if "!SWITCH_DONE!"=="0" (
    goto interactive_selection
)

:: Exit with new PATH
for /f "delims=" %%p in ("!FINAL_PATH!") do endlocal & set "PATH=%%p" & exit /b 0

:: Interactive selection (also reached via 'select' command)
:interactive_selection

:: Validate configuration
if "!NODE_VERSIONS_DIR!"=="" (
    echo Error: NODE_VERSIONS_DIR not configured
    echo.
    echo Configuration file: %CONFIG_FILE%
    echo.
    echo Please set up your configuration first:
    echo   node_switcher set NODE_VERSIONS_DIR=YOUR_PATH
    echo   node_switcher set DEFAULT_VERSION=YOUR_VERSION
    echo.
    echo For more information, run: node_switcher help
    exit /b 1
)

:: Check if versions directory exists
if not exist "!NODE_VERSIONS_DIR!" (
    echo Error: Versions directory not found: !NODE_VERSIONS_DIR!
    echo.
    echo Please check your configuration with: node_switcher show
    echo.
    echo To update the path, run:
    echo   node_switcher set NODE_VERSIONS_DIR=YOUR_PATH
    exit /b 1
)

:: Show current Node.js version
echo Current Node.js version:
node --version 2>nul || echo Node.js not detected

:: List available versions
echo.
echo Available Node.js versions:
echo =======================
set /a COUNT=0

for /d %%i in ("!NODE_VERSIONS_DIR!\*") do (
    set /a COUNT+=1
    set VERSIONS[!COUNT!]=%%~nxi
    echo !COUNT!. %%~nxi
)

:: Check if any versions are available
if %COUNT% equ 0 (
    echo No available Node.js versions found in: !NODE_VERSIONS_DIR!
    echo.
    echo Please check your versions directory and ensure it contains Node.js version folders.
    echo.
    echo Current configuration:
    node_switcher show
    exit /b 1
)

:: User selects version
echo.
set /p CHOICE=Please enter version number (1-%COUNT%):

:: Trim trailing spaces from CHOICE
:trim_choice
if not "!CHOICE:~-1!"==" " goto after_trim
set "CHOICE=!CHOICE:~0,-1!"
goto trim_choice
:after_trim

:: Validate input and switch version
if "!CHOICE!"=="" goto INVALID
for /f "delims=0123456789" %%i in ("!CHOICE!") do goto INVALID
if !CHOICE! lss 1 goto INVALID
if !CHOICE! gtr %COUNT% goto INVALID

:: Build new PATH
set "SELECTED_VERSION=!VERSIONS[%CHOICE%]!"
set "SELECTED_PATH=!NODE_VERSIONS_DIR!\!SELECTED_VERSION!"
set "PATH=!SELECTED_PATH!;!ORIGINAL_PATH!"

:: Show switch result
echo.
echo Node.js version switched to: !SELECTED_VERSION!

:: Apply to current session and exit
for /f "delims=" %%p in ("!PATH!") do set "FINAL_PATH=%%p"
for /f "delims=" %%p in ("!FINAL_PATH!") do endlocal & set "PATH=%%p" & exit /b 0

:INVALID
echo Error: Please enter a number between 1-%COUNT%
exit /b 1
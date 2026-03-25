@echo off
REM ============================================================================
REM BulletS Region Crossing Patch Applicator for Windows
REM ============================================================================
REM This script applies the BulletS-crossing.patch to the OpenSimulator repository.
REM
REM Usage:
REM   insert_patch.bat [options] [patch_file]
REM
REM Options:
REM   -h, --help          Show this help message
REM   -d, --dry-run       Test patch without applying
REM   -r, --revert        Revert the patch from the repository
REM   -v, --verbose       Show detailed output
REM
REM Examples:
REM   insert_patch.bat BulletS-crossing.patch
REM   insert_patch.bat --dry-run BulletS-crossing.patch
REM   insert_patch.bat --revert BulletS-crossing.patch
REM
REM ============================================================================

setlocal enabledelayedexpansion
cls

REM Initialize variables
set "PATCH_FILE="
set "DRY_RUN=0"
set "REVERT=0"
set "VERBOSE=0"
set "HELP=0"
set "SCRIPT_DIR=%~dp0"
set "OPENSIM_DIR=%SCRIPT_DIR%opensim"
set "PATCH_DIR=%SCRIPT_DIR%patch"

REM Color codes (using Windows color command)
set "COLOR_GREEN=0A"
set "COLOR_YELLOW=0E"
set "COLOR_RED=0C"
set "COLOR_WHITE=0F"
set "COLOR_RESET=07"

REM Parse command line arguments
:parse_args
if "%~1"=="" goto args_done
if /i "%~1"=="-h" goto show_help
if /i "%~1"=="--help" goto show_help
if /i "%~1"=="-d" (
    set "DRY_RUN=1"
    shift
    goto parse_args
)
if /i "%~1"=="--dry-run" (
    set "DRY_RUN=1"
    shift
    goto parse_args
)
if /i "%~1"=="-v" (
    set "VERBOSE=1"
    shift
    goto parse_args
)
if /i "%~1"=="--verbose" (
    set "VERBOSE=1"
    shift
    goto parse_args
)
if /i "%~1"=="-r" (
    set "REVERT=1"
    shift
    goto parse_args
)
if /i "%~1"=="--revert" (
    set "REVERT=1"
    shift
    goto parse_args
)

REM Check if it's a patch file
if not "!PATCH_FILE!"=="" (
    echo Error: Multiple patch files specified
    goto error_exit
)
set "PATCH_FILE=%~1"
shift
goto parse_args

:args_done

REM Show help if requested
if !HELP! equ 1 goto show_help

REM Parse patch file name if provided
if "!PATCH_FILE!"=="" (
    set "PATCH_FILE=BulletS-crossing.patch"
)

REM Determine full patch file path
if exist "!PATCH_FILE!" (
    set "FULL_PATCH_PATH=!PATCH_FILE!"
) else if exist "!PATCH_DIR!\!PATCH_FILE!" (
    set "FULL_PATCH_PATH=!PATCH_DIR!\!PATCH_FILE!"
) else (
    echo.
    call :print_error "ERROR: Patch file not found: !PATCH_FILE!"
    echo.
    echo Searched locations:
    echo   1. !PATCH_FILE!
    echo   2. !PATCH_DIR!\!PATCH_FILE!
    echo.
    goto error_exit
)

REM Initialize output
call :print_header "BulletS Region Crossing Patch Applicator"
echo.
echo Script Directory: !SCRIPT_DIR!
echo OpenSim Directory: !OPENSIM_DIR!
echo Patch File: !FULL_PATCH_PATH!
if !DRY_RUN! equ 1 echo Mode: DRY-RUN (no changes will be applied)
if !REVERT! equ 1 echo Mode: REVERT (patch will be removed)
if !VERBOSE! equ 1 echo Mode: VERBOSE (detailed output enabled)
echo.

REM Check prerequisites
call :check_prerequisites

REM Change to OpenSim directory
if not exist "!OPENSIM_DIR!" (
    call :print_error "ERROR: OpenSim directory not found: !OPENSIM_DIR!"
    goto error_exit
)

cd /d "!OPENSIM_DIR!" || (
    call :print_error "ERROR: Could not change to OpenSim directory"
    goto error_exit
)

if !VERBOSE! equ 1 (
    call :print_info "Changed directory to: !OPENSIM_DIR!"
)

REM Display patch info
call :print_info "=== Patch Information ==="
git apply --stat "!FULL_PATCH_PATH!" 2>nul
if !ERRORLEVEL! neq 0 (
    call :print_error "ERROR: Could not read patch file"
    goto error_exit
)
echo.

REM Perform the patch operation
if !REVERT! equ 1 (
    call :revert_patch
) else (
    call :apply_patch
)

goto end_success

REM ============================================================================
REM Function: Check Prerequisites
REM ============================================================================
:check_prerequisites
if !VERBOSE! equ 1 (
    call :print_info "Checking prerequisites..."
)

REM Check if git is installed
git --version >nul 2>&1
if !ERRORLEVEL! neq 0 (
    call :print_error "ERROR: Git is not installed or not in PATH"
    call :print_error "Please install Git and ensure git command is available"
    goto error_exit
)

if !VERBOSE! equ 1 (
    call :print_info "✓ Git is installed"
)

REM Check if patch directory exists
if not exist "!PATCH_DIR!" (
    if !VERBOSE! equ 1 (
        call :print_warning "Creating patch directory: !PATCH_DIR!"
    )
    mkdir "!PATCH_DIR!" 2>nul
)

goto end_function

REM ============================================================================
REM Function: Apply Patch
REM ============================================================================
:apply_patch
if !DRY_RUN! equ 1 (
    call :print_info "=== DRY-RUN MODE ==="
    echo Testing patch application without making changes...
    echo.
    git apply --check "!FULL_PATCH_PATH!" 2>&1
    set "PATCH_RESULT=!ERRORLEVEL!"
    
    if !PATCH_RESULT! equ 0 (
        call :print_info "✓ Patch can be applied successfully"
        echo.
        call :print_info "Ready to apply. Run without --dry-run to apply the patch:"
        echo   insert_patch.bat !PATCH_FILE!
    ) else (
        call :print_error "✗ Patch cannot be applied"
        echo.
        call :print_error "The patch may conflict with the current code."
        echo Possible reasons:
        echo   1. Patch was already applied
        echo   2. Code has been modified since patch creation
        echo   3. Patch is from a different version
    )
) else (
    call :print_info "=== APPLYING PATCH ==="
    echo Applying patch to repository...
    echo.
    
    REM Check if already applied
    git apply --check "!FULL_PATCH_PATH!" >nul 2>&1
    if !ERRORLEVEL! neq 0 (
        call :print_warning "Patch may already be applied or there are conflicts"
        echo Attempting to apply anyway...
        echo.
    )
    
    git apply "!FULL_PATCH_PATH!" 2>&1
    set "PATCH_RESULT=!ERRORLEVEL!"
    
    if !PATCH_RESULT! equ 0 (
        call :print_info "✓ Patch applied successfully"
        echo.
        call :print_info "Next steps:"
        echo   1. Review the changes: git diff
        echo   2. Stage changes: git add .
        echo   3. Commit changes: git commit -m "Apply BulletS region crossing fix"
        echo   4. Build the project: runprebuild.bat ^&^& Visual Studio
    ) else (
        call :print_error "✗ Patch application failed"
        echo.
        call :print_error "Error details above"
        goto error_exit
    )
)

goto end_function

REM ============================================================================
REM Function: Revert Patch
REM ============================================================================
:revert_patch
call :print_info "=== REVERTING PATCH ==="
echo Attempting to revert patch from repository...
echo.

git apply --reverse --check "!FULL_PATCH_PATH!" >nul 2>&1
if !ERRORLEVEL! neq 0 (
    call :print_warning "Patch may not be applied, or revert check failed"
    echo.
)

if !DRY_RUN! equ 1 (
    call :print_info "DRY-RUN: Testing revert without making changes..."
    echo.
    git apply --reverse --check "!FULL_PATCH_PATH!" 2>&1
    set "PATCH_RESULT=!ERRORLEVEL!"
    
    if !PATCH_RESULT! equ 0 (
        call :print_info "✓ Patch can be reverted successfully"
        echo.
        call :print_info "Ready to revert. Run without --dry-run to revert the patch:"
        echo   insert_patch.bat --revert !PATCH_FILE!
    ) else (
        call :print_error "✗ Patch cannot be reverted"
    )
) else (
    git apply --reverse "!FULL_PATCH_PATH!" 2>&1
    set "PATCH_RESULT=!ERRORLEVEL!"
    
    if !PATCH_RESULT! equ 0 (
        call :print_info "✓ Patch reverted successfully"
        echo.
        call :print_info "Next steps:"
        echo   1. Review the changes: git diff
        echo   2. Stage changes: git add .
        echo   3. Commit changes: git commit -m "Revert BulletS region crossing fix"
    ) else (
        call :print_error "✗ Patch revert failed"
        echo.
        call :print_error "Error details above"
        goto error_exit
    )
)

goto end_function

REM ============================================================================
REM Function: Print Help
REM ============================================================================
:show_help
echo.
echo BulletS Region Crossing Patch Applicator for Windows
echo =====================================================
echo.
echo Usage:
echo   insert_patch.bat [OPTIONS] [PATCH_FILE]
echo.
echo Options:
echo   -h, --help          Display this help message
echo   -d, --dry-run       Test patch without making changes
echo   -r, --revert        Revert the patch from the repository
echo   -v, --verbose       Show detailed output
echo.
echo Arguments:
echo   PATCH_FILE          Path to the patch file (default: BulletS-crossing.patch)
echo                       Can be in any directory or in the patch/ subdirectory
echo.
echo Examples:
echo   insert_patch.bat BulletS-crossing.patch
echo       Apply the patch from default location or current directory
echo.
echo   insert_patch.bat --dry-run BulletS-crossing.patch
echo       Test if the patch can be applied without making changes
echo.
echo   insert_patch.bat --revert BulletS-crossing.patch
echo       Remove the patch from the repository
echo.
echo   insert_patch.bat -v -d BulletS-crossing.patch
echo       Test with verbose output
echo.
echo Features:
echo   - Automatic patch file location detection
echo   - Git-based patch application
echo   - Dry-run mode for safe testing
echo   - Revert capability to undo patches
echo   - Verbose mode for troubleshooting
echo   - Color-coded output messages
echo   - Comprehensive error checking
echo.
echo Requirements:
echo   - Git must be installed and available in PATH
echo   - Script must be run from OpenSimulator root directory or adjacent to 'opensim' folder
echo.
echo Exit Codes:
echo   0 = Success
echo   1 = Error
echo.
exit /b 0

REM ============================================================================
REM Function: Print Info Message
REM ============================================================================
:print_info
setlocal
set "MSG=%~1"
color %COLOR_WHITE%
echo [INFO] !MSG!
color %COLOR_RESET%
endlocal
goto end_function

REM ============================================================================
REM Function: Print Warning Message
REM ============================================================================
:print_warning
setlocal
set "MSG=%~1"
color %COLOR_YELLOW%
echo [WARN] !MSG!
color %COLOR_RESET%
endlocal
goto end_function

REM ============================================================================
REM Function: Print Error Message
REM ============================================================================
:print_error
setlocal
set "MSG=%~1"
color %COLOR_RED%
echo [ERROR] !MSG!
color %COLOR_RESET%
endlocal
goto end_function

REM ============================================================================
REM Function: Print Header
REM ============================================================================
:print_header
setlocal
set "HEADER=%~1"
color %COLOR_GREEN%
echo.
echo ============================================================================
echo %HEADER%
echo ============================================================================
color %COLOR_RESET%
endlocal
goto end_function

REM ============================================================================
REM Success Exit
REM ============================================================================
:end_success
call :print_header "Operation Completed Successfully"
echo.
exit /b 0

REM ============================================================================
REM Error Exit
REM ============================================================================
:error_exit
echo.
call :print_error "Operation failed. Please review the errors above."
echo For help, run: insert_patch.bat --help
echo.
exit /b 1

REM ============================================================================
REM End Function
REM ============================================================================
:end_function

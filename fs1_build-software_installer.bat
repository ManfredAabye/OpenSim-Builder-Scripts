@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: OK Manfred Aabye 22.08.2025 Version 3.4
REM 1_build_software_installer.bat - Installiert die benötigten Software-Tools für den Firestorm Build-Prozess

:: Setzt ANSI-Farbcodes für farbige Statusmeldungen im Terminal (funktioniert nur in unterstützten Konsolen)
for /f %%a in ('echo prompt $E ^| cmd') do set ESC=%%a
set GREEN=%ESC%[32m
set RED=%ESC%[31m
set YELLOW=%ESC%[33m
set BLUE=%ESC%[34m
set CYAN=%ESC%[36m
set BRIGHT_CYAN=%ESC%[96m
set RESET=%ESC%[0m

:: Sprache ueber Datei fsx_language steuern (DE, EN, FR, ES)
set "SCRIPT_DIR=%~dp0"
set "LANG_FILE=%SCRIPT_DIR%fsx_language.bat"
set "FS_LANG=DE"

if not exist "%LANG_FILE%" (
    echo %RED%[ERROR] Sprachdatei nicht gefunden: %LANG_FILE%%RESET%
    goto :eof
)

call "%LANG_FILE%"


echo %GREEN%!TXT_HDR_INSTALL!%RESET%
echo %GREEN%!TXT_DESC_INSTALL!%RESET%
echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%

:: 0. Aktivieren von langen Pfaden in Windows 10/11
echo %GREEN%!TXT_STEP0!%RESET%
SETLOCAL ENABLEEXTENSIONS

:: Prüfen, ob LongPathsEnabled bereits gesetzt ist
REG QUERY "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v LongPathsEnabled >nul 2>&1
IF ERRORLEVEL 1 (
    echo !TXT_ERR_REGKEY!
    goto :set_flag
)

FOR /F "tokens=3" %%A IN ('REG QUERY "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v LongPathsEnabled ^| find "REG_DWORD"') DO (
    SET Flag=%%A
)

IF "%Flag%"=="0x1" (
    echo !TXT_OK_LONGPATH_ON!
    goto :end
)

:: Wenn nicht aktiviert, dann setzen
:set_flag
echo !TXT_INFO_ENABLE_LONGPATH!
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v LongPathsEnabled /t REG_DWORD /d 1 /f
IF ERRORLEVEL 1 (
    echo !TXT_ERR_SET_REGKEY!
    goto :end
)

echo !TXT_OK_LONGPATH_SET!
echo !TXT_INFO_REBOOT!

:end
@REM pause
ENDLOCAL

:: 1. Visual Studio 2022 Community mit BEIDEN Toolsets
echo %GREEN%!TXT_STEP1!%RESET%
echo %GREEN%!TXT_STEP1_W1!%RESET%
echo %GREEN%!TXT_STEP1_W2!%RESET%
echo %GREEN%     * MSVC v141 - VS 2017 C++ x64/x86-Buildtools%RESET%
echo %GREEN%     * MSVC v143 - VS 2022 C++ x64/x86-Buildtools%RESET%

choco install -y --no-progress visualstudio2022community --package-parameters="--add Microsoft.VisualStudio.Workload.NativeDesktop --add Microsoft.VisualStudio.Component.VC.14.16.x86.x64 --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64"

echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
:: Chocolatey
echo %GREEN%!TXT_STEP2!%RESET%
echo %GREEN%!TXT_STEP2_DESC!%RESET%

if not exist "%ProgramData%\Chocolatey\bin\choco.exe" (
    echo %GREEN%!TXT_INFO_INSTALL_CHOCO!%RESET%
    powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; iex (New-Object Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')"
    timeout /t 30
    call "%ProgramData%\Chocolatey\bin\refreshEnv.cmd"
)

echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%

:: Tools installieren
echo %GREEN%!TXT_STEP3!%RESET%
echo %GREEN%!TXT_STEP3_DESC!%RESET%

choco install -y --no-progress --stop-on-first-failure cmake git python nsis cygwin 7zip doxygen

echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%

:: Installiere Cygwin-Pakete
echo %GREEN%!TXT_STEP4!%RESET%
echo %GREEN%!TXT_STEP4_DESC!%RESET%

set "CYGWIN_SETUP="
set "CYGWIN_ROOT="
set "CYGWIN_INSTALLED_DB="

if exist "C:\cygwin64\setup-x86_64.exe" set "CYGWIN_SETUP=C:\cygwin64\setup-x86_64.exe"
if "%CYGWIN_SETUP%"=="" if exist "C:\cygwin64\cygwinsetup.exe" set "CYGWIN_SETUP=C:\cygwin64\cygwinsetup.exe"
if "%CYGWIN_SETUP%"=="" if exist "C:\tools\cygwin\setup-x86_64.exe" set "CYGWIN_SETUP=C:\tools\cygwin\setup-x86_64.exe"
if "%CYGWIN_SETUP%"=="" if exist "%ProgramData%\chocolatey\lib\cygwin\tools\setup-x86_64.exe" set "CYGWIN_SETUP=%ProgramData%\chocolatey\lib\cygwin\tools\setup-x86_64.exe"

if exist "C:\cygwin64\etc\setup\installed.db" set "CYGWIN_ROOT=C:\cygwin64"
if "%CYGWIN_ROOT%"=="" if exist "C:\tools\cygwin\etc\setup\installed.db" set "CYGWIN_ROOT=C:\tools\cygwin"
if "%CYGWIN_ROOT%"=="" if exist "%ProgramData%\chocolatey\lib\cygwin\tools\etc\setup\installed.db" set "CYGWIN_ROOT=%ProgramData%\chocolatey\lib\cygwin\tools"
if not "%CYGWIN_ROOT%"=="" set "CYGWIN_INSTALLED_DB=%CYGWIN_ROOT%\etc\setup\installed.db"

if "%CYGWIN_SETUP%"=="" (
    echo %RED%!TXT_ERR_CYGWIN_SETUP!%RESET%
    echo %RED%!TXT_ERR_CYGWIN_PATHS!%RESET%
) else (
    set "CYGWIN_PACKAGES=patch make gcc-core gcc-g++ cmake ninja git python3 perl rsync zip unzip pkg-config libtool autoconf automake dos2unix"
    set "CYGWIN_PACKAGES_TO_INSTALL="

    if exist "!CYGWIN_INSTALLED_DB!" (
        echo %GREEN%!TXT_INFO_CHECK_CYGWIN!%RESET%
        for %%P in (!CYGWIN_PACKAGES!) do (
            findstr /B /C:"%%P " "!CYGWIN_INSTALLED_DB!" >nul 2>&1
            if ERRORLEVEL 1 (
                if defined CYGWIN_PACKAGES_TO_INSTALL (
                    set "CYGWIN_PACKAGES_TO_INSTALL=!CYGWIN_PACKAGES_TO_INSTALL!,%%P"
                ) else (
                    set "CYGWIN_PACKAGES_TO_INSTALL=%%P"
                )
            )
        )
    ) else (
        echo %YELLOW%!TXT_WARN_NO_INSTALLED_DB!%RESET%
        for %%P in (!CYGWIN_PACKAGES!) do (
            if defined CYGWIN_PACKAGES_TO_INSTALL (
                set "CYGWIN_PACKAGES_TO_INSTALL=!CYGWIN_PACKAGES_TO_INSTALL!,%%P"
            ) else (
                set "CYGWIN_PACKAGES_TO_INSTALL=%%P"
            )
        )
    )

    if not defined CYGWIN_PACKAGES_TO_INSTALL (
        echo %GREEN%!TXT_OK_CYGWIN_ALL!%RESET%
    ) else (
        echo %GREEN%!TXT_INFO_INSTALL_MISSING! !CYGWIN_PACKAGES_TO_INSTALL!%RESET%
        "%CYGWIN_SETUP%" -q -P !CYGWIN_PACKAGES_TO_INSTALL!
        if ERRORLEVEL 1 (
            echo %RED%!TXT_ERR_CYGWIN_INSTALL!%RESET%
        ) else (
            echo %GREEN%!TXT_OK_CYGWIN_INSTALLED!%RESET%
        )
    )
)

echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
echo %GREEN%!TXT_DONE!%RESET%
echo %GREEN%!TXT_NEXT!%RESET%
pause

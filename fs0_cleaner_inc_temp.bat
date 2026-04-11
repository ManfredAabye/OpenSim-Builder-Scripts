@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: Sprache ueber Datei fsx_language.bat steuern (DE, EN, FR, ES)
set "SCRIPT_DIR=%~dp0"
set "LANG_FILE=%SCRIPT_DIR%fsx_language.bat"
set "FS_LANG=DE"

if not exist "%LANG_FILE%" (
	echo [ERROR] Sprachdatei nicht gefunden: %LANG_FILE%
	pause
	exit /b 1
)

call "%LANG_FILE%"

:: OK Manfred Aabye 25.06.2025 Version 3.3
REM 0cleaner.bat - Bereinigt das Firestorm Build-Verzeichnis

:: ANSI-Farben
for /f %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
set "RED=%ESC%[31m"
set "RESET=%ESC%[0m"

echo %RED%!FS0I_TXT_HDR_CLEAN!%RESET%
set "BUILD_DIR=%SCRIPT_DIR%Firestorm_Build"
set "TEMP_DIR=%SCRIPT_DIR%temp"


rmdir /s /q "%BUILD_DIR%"
echo %RED%!FS0I_TXT_OK_DELETED! "%BUILD_DIR%"%RESET%

rmdir /s /q "%TEMP_DIR%"
echo %RED%!FS0I_TXT_OK_DELETED! "%TEMP_DIR%"%RESET%

echo %RED%!FS0I_TXT_DONE!%RESET%
:: pause
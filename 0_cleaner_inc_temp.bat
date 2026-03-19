@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: OK Manfred Aabye 25.06.2025 Version 3.3
REM 0cleaner.bat - Bereinigt das Firestorm Build-Verzeichnis

:: ANSI-Farben
for /f %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
set "RED=%ESC%[31m"
set "RESET=%ESC%[0m"

echo %RED%=== Firestorm Build-Verzeichnis vollständig bereinigen ===%RESET%
set "BUILD_DIR=%~dp0Firestorm_Build"
set "TEMP_DIR=%~dp0temp"


rmdir /s /q "%BUILD_DIR%"
echo %RED%[ERFOLG] "%BUILD_DIR%" wurde gelöscht.%RESET%

rmdir /s /q "%TEMP_DIR%"
echo %RED%[ERFOLG] "%TEMP_DIR%" wurde gelöscht.%RESET%

echo %RED%=== Bereinigung abgeschlossen ===%RESET%
:: pause
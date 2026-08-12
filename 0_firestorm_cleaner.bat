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

echo %RED%Lösche Build-Verzeichnis...%RESET%
if exist "%BUILD_DIR%" (
    rmdir /s /q "%BUILD_DIR%"
    echo %RED%[ERFOLG] "%BUILD_DIR%" wurde gelöscht.%RESET%
) else (
    echo %RED%[INFO] "%BUILD_DIR%" existiert nicht.%RESET%
)

echo %RED%=== Bereinigung abgeschlossen ===%RESET%
:: pause
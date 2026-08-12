@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: OK Manfred Aabye 25.06.2025 Version 1.0
cd Firestorm_Build\phoenix-firestorm

git pull

pause
exit /b 0
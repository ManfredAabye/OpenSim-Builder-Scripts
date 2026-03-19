@echo off
setlocal EnableDelayedExpansion

echo ============================================================
echo  Janus Gateway Build via WSL2
echo ============================================================
echo Hinweis: Cygwin bleibt fuer opensim\phoenix-firestorm erhalten.
echo Dieser Starter gilt nur fuer den Janus-Build.
echo.

set "SCRIPT_DIR=%~dp0"
set "JANUS_DIR=%SCRIPT_DIR%opensim\janus-gateway"

:: Janus Arbeitsverzeichnis explizit auf opensim\janus-gateway festlegen
if not exist "%JANUS_DIR%\configure.ac" (
    echo FEHLER: Janus-Quellverzeichnis nicht gefunden: %JANUS_DIR%
    pause
    exit /b 1
)


where wsl.exe >nul 2>&1
if errorlevel 1 (
    echo FEHLER: wsl.exe wurde nicht gefunden.
    echo Installiere WSL2 mit: wsl --install -d Ubuntu
    pause
    exit /b 1
)

wsl --status >nul 2>&1
if errorlevel 1 (
    echo FEHLER: WSL ist noch nicht installiert oder noch nicht initialisiert.
    echo Fuehre zuerst als Administrator aus: wsl --install -d Ubuntu
    echo Danach Windows neu starten und die Ubuntu-Ersteinrichtung abschliessen.
    pause
    exit /b 1
)

set "HAS_WSL_DISTRO="
for /f "usebackq delims=" %%D in (`wsl -l -q 2^>nul`) do (
    if not "%%D"=="" set "HAS_WSL_DISTRO=1"
)
if "%HAS_WSL_DISTRO%"=="" (
    echo FEHLER: Es ist noch keine WSL-Distribution eingerichtet.
    echo Fuehre zuerst als Administrator aus: wsl --install -d Ubuntu
    echo Danach Windows neu starten und die Ubuntu-Ersteinrichtung abschliessen.
    pause
    exit /b 1
)

set "WSL_DISTRO_ARG="
if not "%JANUS_WSL_DISTRO%"=="" set "WSL_DISTRO_ARG=-d %JANUS_WSL_DISTRO%"

:: --- Begleitskript pruefen ---
set "SH_SCRIPT=%SCRIPT_DIR%Janus-Build-WSL.sh"
if not exist "%SH_SCRIPT%" (
    echo FEHLER: Janus-Build-WSL.sh nicht gefunden neben dieser Bat-Datei.
    pause
    exit /b 1
)

:: --- Windows-Pfad in WSL-Pfad umwandeln ---
for /f "tokens=1 delims=:" %%L in ("%SCRIPT_DIR%") do set "DRIVELETTER=%%L"
for %%l in (a b c d e f g h i j k l m n o p q r s t u v w x y z) do (
    if /i "!DRIVELETTER!"=="%%l" set "DRIVELETTER=%%l"
)
set "RESTPATH=%SCRIPT_DIR:~2%"
set "RESTPATH=%RESTPATH:\=/%"
if "!RESTPATH:~-1!"=="/" set "RESTPATH=!RESTPATH:~0,-1!"
set "WSL_SCRIPT=/mnt/!DRIVELETTER!!RESTPATH!/Janus-Build-WSL.sh"
set "WSL_LOGFILE=/mnt/!DRIVELETTER!!RESTPATH!/janus-build-wsl.log"

set "LOGFILE=%SCRIPT_DIR%janus-build-wsl.log"
echo Ausfuehren: wsl.exe %WSL_DISTRO_ARG% bash -lc "%WSL_SCRIPT%"
echo Janus-Quelle: %JANUS_DIR%
echo Log-Datei : %LOGFILE%
echo.

set "JANUS_BUILD_LOGFILE=%WSL_LOGFILE%"
set "JANUS_WSL_INSTALL_DEPS_ARG=%JANUS_WSL_INSTALL_DEPS%"
wsl.exe %WSL_DISTRO_ARG% bash -lc "chmod +x '%WSL_SCRIPT%' && JANUS_BUILD_LOGFILE='%JANUS_BUILD_LOGFILE%' JANUS_WSL_INSTALL_DEPS='!JANUS_WSL_INSTALL_DEPS_ARG!' '%WSL_SCRIPT%'"
set BUILD_EXIT=!ERRORLEVEL!

echo.
if !BUILD_EXIT!==0 (
    echo ============================================================
    echo  Janus Gateway unter WSL2 erfolgreich gebaut und installiert.
    echo ============================================================
) else (
    echo ============================================================
    echo  FEHLER: Build abgebrochen ^(Exit-Code: !BUILD_EXIT!^).
    echo  Vollstaendiges Log: %LOGFILE%
    echo ============================================================
)
pause
exit /b !BUILD_EXIT!
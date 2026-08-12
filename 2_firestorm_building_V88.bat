@echo off
:: Schaltet die Anzeige der Befehle im Konsolenfenster aus, damit die Ausgabe übersichtlich bleibt.

chcp 65001 >nul
:: Setzt die Codepage auf UTF-8, damit Sonderzeichen korrekt dargestellt werden.

setlocal enabledelayedexpansion
:: Aktiviert verzögerte Variablienerweiterung, nützlich für komplexere Batch-Operationen.

set "SCRIPT_DIR=%~dp0"  :: Pfad zu diesem Skript
echo %SCRIPT_DIR%

:: ##### 1. **Einleitung und Hinweise** #####
:: Diese Batchdatei automatisiert den Build-Prozess für den Firestorm Viewer.
:: Sie legt alle benötigten Variablen, Umgebungen und Verzeichnisse an und führt die einzelnen Build-Schritte aus.
:: Version 2025.09.30, Stand: 30.09.2025, by Manfred Aabye

:: ##### 2. **Farbdefinition für Konsolenausgabe**
:: Setzt ANSI-Farbcodes für farbige Statusmeldungen im Terminal (funktioniert nur in unterstützten Konsolen)
for /f %%a in ('echo prompt $E ^| cmd') do set ESC=%%a
set GREEN=%ESC%[32m
set RED=%ESC%[31m
set YELLOW=%ESC%[33m
set BLUE=%ESC%[34m
set CYAN=%ESC%[36m
set BRIGHT_CYAN=%ESC%[96m
set RESET=%ESC%[0m

set SKRIPT_VERSION="V88-20260729"
title %SKRIPT_VERSION%
echo Skript Version: %SKRIPT_VERSION%

set Release=ON
set Develop=OFF
set Debug=OFF

echo "Release: %Release% Develop: %Develop% Debug: %Debug%"

echo 1. Firestorm Build Vorbereitung >> %SCRIPT_DIR%fs-informationen\FirestormBuild.txt

:: Überschrift für die Build-Vorbereitung
echo %GREEN% Firestorm Build Vorbereitung %SKRIPT_VERSION% %RESET%
echo .
echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET% 
echo .

echo 3. Grundkonfiguration und Variablen >> %SCRIPT_DIR%fs-informationen\FirestormBuild.txt

:: ##### 3. **Grundkonfiguration und Variablen**
:: Definition von Skriptpfad, Zielordnern, Konfigurationsparametern
echo %GREEN%Konfiguration...%RESET%

:: Kein link.exe von Github nutzen (Git überschreibt manchmal Windows-Tools)


:: Stelle sicher, dass alle relativen Pfade auf dieses Skriptverzeichnis zeigen.
echo %GREEN%Pfade auf Skriptverzeichnis...%RESET%
cd /d "%SCRIPT_DIR%" || (
    echo %RED%[FEHLER] Konnte nicht in das Skriptverzeichnis wechseln: %SCRIPT_DIR%%RESET%
    pause
    exit /b 1
)

:: Git's Unix-Tools aus dem PATH entfernen
echo %GREEN%Unix-Tools...%RESET%
set "PATH=%PATH:C:\Program Files\Git\usr\bin;=%"

:: Cygwin-Bash fuer autobuild configure sicherstellen
echo %GREEN%Cygwin-Bash fuer autobuild configure sicherstellen...%RESET%
set "CYGWIN_BASH="
if exist "C:\cygwin64\bin\bash.exe" set "CYGWIN_BASH=C:\cygwin64\bin\bash.exe"
if "%CYGWIN_BASH%"=="" if exist "C:\tools\cygwin\bin\bash.exe" set "CYGWIN_BASH=C:\tools\cygwin\bin\bash.exe"
if "%CYGWIN_BASH%"=="" if exist "%ProgramData%\chocolatey\lib\cygwin\tools\bin\bash.exe" set "CYGWIN_BASH=%ProgramData%\chocolatey\lib\cygwin\tools\bin\bash.exe"

if "%CYGWIN_BASH%"=="" (
    echo %RED%[FEHLER] Cygwin bash.exe nicht gefunden. Bitte zuerst 1_build-software_installer.bat ausfuehren.%RESET%
    pause
    exit /b 1
)

for %%I in ("%CYGWIN_BASH%") do set "CYGWIN_BIN=%%~dpI"
set "PATH=%CYGWIN_BIN%;%PATH%"
set "BASH=%CYGWIN_BASH%"

:: Stelle sicher, dass du vcvarsall.bat aufrufst, bevor du irgendetwas baust
echo %GREEN%Stelle sicher, dass du vcvarsall.bat aufrufst...%RESET%
call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" x64

::set "PYTHON_VERSION=3.10.11"  :: Gewünschte Python-Version
echo %GREEN%Python-Version und Pfade festlegen...%RESET%
set "PYTHON_VERSION=3.13.3"  :: Neue Python-Version
:: todo: Python-Version ermitteln und verwenden ab Version 3.10.11 besser 3.13.3

set "BUILD_DIR=%SCRIPT_DIR%Firestorm_Build"  :: Zielverzeichnis für den Build

:: Ist das zielverzeichniss vorhanden warnen und abbrechen
if exist "%BUILD_DIR%" (
    echo WARNUNG: Verzeichnis %BUILD_DIR% existiert bereits!
    set /p choice="Möchten Sie trotzdem fortsetzen? (J/N): "
    if /i not "!choice!"=="J" (
        echo Abbruch durch Benutzer.
        exit /b 1
    )
    echo Fortfahren mit vorhandenem Verzeichnis...
)

REM Variablen definieren
echo %GREEN%Variablen definieren...%RESET%

set AUTOBUILD_CONFIG_FILE=autobuild.xml

set "VENV_DIR=%BUILD_DIR%\venv"  :: Virtuelle Python-Umgebung
set "ProgramFiles=C:\Program Files"  :: Standard-Programmpfad
set "AUTOBUILD_INSTALL_DIR=%BUILD_DIR%\packages"  :: Installationsverzeichnis für Autobuild-Pakete

set "ARCH=64"  :: Architektur
@REM set "CONFIG=ReleaseFS_open"  :: Build-Konfiguration
set "CONFIG=Release"  :: Build-Konfiguration
set "OUTPUT_DIR=%BUILD_DIR%\phoenix-firestorm\build-vc170-64\newview\Release"  :: Release-Ausgabeverzeichnis
set "AUTO_BUILD_CONFIG=%BUILD_DIR%\phoenix-firestorm\autobuild.xml"  :: Pfad zur Build-Konfigurationsdatei
set "AUTOBUILD_VARIABLES_FILE=%BUILD_DIR%\fs-build-variables\variables"  :: Build-Variablen

:: ##### TEMP-UMLEITUNG #####
echo %GREEN%TEMP-UMLEITUNG...%RESET%
set "AUTOBUILD_TEMP=%SCRIPT_DIR%temp"  :: Temporäres Arbeitsverzeichnis
if not exist "%AUTOBUILD_TEMP%" mkdir "%AUTOBUILD_TEMP%"
:: Erstellt das TEMP-Verzeichnis, falls nicht vorhanden
set "TMP=%AUTOBUILD_TEMP%"
set "TEMP=%AUTOBUILD_TEMP%"

:: 1. fs_include ins Build-Verzeichnis kopieren
set "FS_INCLUDE_SOURCE=%SCRIPT_DIR%\fs_include"
set "FS_INCLUDE_DEST=%BUILD_DIR%\fs_include"



echo .
echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
echo .

echo 4. Erstellung des Arbeitsverzeichnisses >> %SCRIPT_DIR%fs-informationen\FirestormBuild.txt

:: ##### 4. **Erstellung des Arbeitsverzeichnisses**
:: #####    - Legt den Build-Ordner an (sofern nicht vorhanden)
echo %GREEN%Erstelle Build-Verzeichnis%RESET%

mkdir "%BUILD_DIR%" 2>nul

echo .
echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
echo .

echo 5. Einrichtung der Python-Virtualenv >> %SCRIPT_DIR%fs-informationen\FirestormBuild.txt

:: ##### 5. **Einrichtung der Python-Virtualenv**
:: #####    - Erstellt virtuelle Umgebung und installiert benötigte Python-Module (`autobuild`, `llbase`, `llsd`)
echo %GREEN%[INFO] Erstelle virtuelle Umgebung...%RESET%

if not exist "%VENV_DIR%" (
    python -m venv "%VENV_DIR%"
    call "%VENV_DIR%\Scripts\activate.bat"
    python -m pip install --upgrade pip
    python -m pip install --force-reinstall --no-cache-dir llbase llsd autobuild
    echo %GREEN%[INFO] Virtualenv wurde erstellt.%RESET%
) else (
    call "%VENV_DIR%\Scripts\activate.bat"
    echo %GREEN%[INFO] Virtualenv existiert bereits.%RESET%
)


echo .
echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
echo .

echo 6. Klonen der Quellverzeichnisse >> %SCRIPT_DIR%fs-informationen\FirestormBuild.txt

:: ##### 6. **Klonen der Quellverzeichnisse**
:: #####    - Holt `phoenix-firestorm` und `fs-build-variables` über `git clone`
echo %GREEN%Klonen der Repositories direkt nach %BUILD_DIR%...%RESET%

:: 1. Phoenix-Firestorm direkt ins BUILD_DIR
if not exist "%BUILD_DIR%\phoenix-firestorm\.git" (
    git clone "https://github.com/FirestormViewer/phoenix-firestorm.git" "%BUILD_DIR%\phoenix-firestorm"
) else (
    echo %YELLOW%phoenix-firestorm existiert bereits. aktualisiere...%RESET%
    git -C "%BUILD_DIR%\phoenix-firestorm" pull
    echo %GREEN%[INFO] Phoenix-Firestorm wurde aktualisiert.%RESET%
)
:: 2. Build-Variablen direkt ins BUILD_DIR
if not exist "%BUILD_DIR%\fs-build-variables\.git" (
    git clone "https://github.com/FirestormViewer/fs-build-variables.git" "%BUILD_DIR%\fs-build-variables"
) else (
    echo %YELLOW%fs-build-variables existiert bereits. aktualisiere...%RESET%
    git -C "%BUILD_DIR%\fs-build-variables" pull
    echo %GREEN%[INFO] fs-build-variables wurde aktualisiert.%RESET%
)


echo .
echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
echo .
:: Weitere Source schritte...
echo %GREEN%Kopiere fs-build-variables...%RESET%

if not exist "%BUILD_DIR%\fs-build-variables" (
    xcopy /E /I /Y "%SCRIPT_DIR%\fs-build-variables" "%BUILD_DIR%\fs-build-variables" >nul 2>&1
)

if not exist "%BUILD_DIR%\autobuild" (
    git clone "https://github.com/FirestormViewer/autobuild.git" "%BUILD_DIR%\autobuild"
    @REM todo autobuild mit pip3 installieren trotz vorhandener version.
    @REM python -m pip install --force-reinstall --no-cache-dir autobuild
)

echo .
echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
echo .
:: Logos überschreiben aus dem fs_include Verzeichnis
echo %GREEN%Logos ueberschreiben %BUILD_DIR%...%RESET%

xcopy /Y "%SCRIPT_DIR%fs_include\vivox_logo.png" "%BUILD_DIR%\phoenix-firestorm\indra\newview\skins\default\textures\3p_icons\"

echo .
echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
echo .
:: Skin änderungen Kopieren
::echo %GREEN%Skin Kopieren %BUILD_DIR%...%RESET%

:: xcopy /E /I /Y "%SCRIPT_DIR%Skin\skins.xml" "%BUILD_DIR%\phoenix-firestorm\indra\newview\skins"
:: xcopy /E /I /Y "%SCRIPT_DIR%Skin\singularity" "%BUILD_DIR%\phoenix-firestorm\indra\newview\skins\singularity"

:: Das doc nach docs kopieren
::xcopy /Y "%SCRIPT_DIR%doc" "%SCRIPT_DIR%docs"
::xcopy /Y "%BUILD_DIR%\phoenix-firestorm\doc" "%BUILD_DIR%\phoenix-firestorm\docs"
xcopy /E /I /Y "%BUILD_DIR%\phoenix-firestorm\doc" "%BUILD_DIR%\phoenix-firestorm\docs\"

echo .
echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
echo .
:: cmake änderungen Kopieren
echo %GREEN%CMAKE Kopieren %BUILD_DIR%...%RESET%

xcopy /E /I /Y "%SCRIPT_DIR%fs_include\OPENAL.cmake" "%BUILD_DIR%\phoenix-firestorm\indra\cmake"
:: xcopy /E /I /Y "%SCRIPT_DIR%fs_include\Assimp.cmake" "%BUILD_DIR%\phoenix-firestorm\indra\cmake"

echo .
echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
echo .
:: Include Dateien in den Sourcecode einfügen.
echo %GREEN%Führe Dateikopierungen aus...%RESET%

:: 1. ZUERST das fs_include-Verzeichnis kopieren (falls noch nicht vorhanden)
if not exist "%FS_INCLUDE_DEST%\" (
    xcopy /E /I /Y "%FS_INCLUDE_SOURCE%" "%FS_INCLUDE_DEST%\" >nul
)

:: viewer_manifest.py kopieren mit den fehlenden dlls
set manifestcp=off
if %manifestcp% == on (
    echo %GREEN%viewer_manifest Kopieren %BUILD_DIR%...%RESET%
    copy /Y "%SCRIPT_DIR%\fs_include\viewer_manifest.py" "%BUILD_DIR%\phoenix-firestorm\indra\newview" >nul
)



echo .
echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
echo .
:: 2. OpenAL DLLs kopieren (NACH Erstellung der Verzeichnisse)
echo %GREEN%Kopiere OpenAL DLLs...%RESET%

if exist "%BUILD_DIR%\phoenix-firestorm\build-vc170-64\newview\Release\" (
    :: OpenAL
    copy /Y "%SCRIPT_DIR%\fs_include\OpenAL32.dll" "%BUILD_DIR%\phoenix-firestorm\build-vc170-64\newview\Release\" >nul
    :: alut
    copy /Y "%SCRIPT_DIR%\fs_include\alut.dll" "%BUILD_DIR%\phoenix-firestorm\build-vc170-64\newview\Release\" >nul
    :: featuretable.txt
    copy /Y "%SCRIPT_DIR%\fs_include\featuretable.txt" "%BUILD_DIR%\phoenix-firestorm\build-vc170-64\newview\Release\" >nul

    :: Neu Test fehlende DLLs
    @REM copy /Y "%SCRIPT_DIR%\fs_include\zlib1.dll" "%BUILD_DIR%\phoenix-firestorm\build-vc170-64\newview\Release\" >nul
    @REM copy /Y "%SCRIPT_DIR%\fs_include\freetype.dll" "%BUILD_DIR%\phoenix-firestorm\build-vc170-64\newview\Release\" >nul
    @REM copy /Y "%SCRIPT_DIR%\fs_include\bz2.dll" "%BUILD_DIR%\phoenix-firestorm\build-vc170-64\newview\Release\" >nul
    @REM copy /Y "%SCRIPT_DIR%\fs_include\libpng16.dll" "%BUILD_DIR%\phoenix-firestorm\build-vc170-64\newview\Release\" >nul
    @REM copy /Y "%SCRIPT_DIR%\fs_include\brotlidec.dll" "%BUILD_DIR%\phoenix-firestorm\build-vc170-64\newview\Release\" >nul
    @REM copy /Y "%SCRIPT_DIR%\fs_include\brotlicommon.dll" "%BUILD_DIR%\phoenix-firestorm\build-vc170-64\newview\Release\" >nul

    @REM copy /Y "%SCRIPT_DIR%\fs_include\zlib1.dll" "%BUILD_DIR%\phoenix-firestorm\build-vc170-64\packages\bin\Release\" >nul
    @REM copy /Y "%SCRIPT_DIR%\fs_include\freetype.dll" "%BUILD_DIR%\phoenix-firestorm\build-vc170-64\packages\bin\Release\" >nul
    @REM copy /Y "%SCRIPT_DIR%\fs_include\bz2.dll" "%BUILD_DIR%\phoenix-firestorm\build-vc170-64\packages\bin\Release\" >nul
    @REM copy /Y "%SCRIPT_DIR%\fs_include\libpng16.dll" "%BUILD_DIR%\phoenix-firestorm\build-vc170-64\packages\bin\Release\" >nul
    @REM copy /Y "%SCRIPT_DIR%\fs_include\brotlidec.dll" "%BUILD_DIR%\phoenix-firestorm\build-vc170-64\packages\bin\Release\" >nul
    @REM copy /Y "%SCRIPT_DIR%\fs_include\brotlicommon.dll" "%BUILD_DIR%\phoenix-firestorm\build-vc170-64\packages\bin\Release\" >nul

    @REM copy /Y "%SCRIPT_DIR%\fs_include\zlib1.dll" "%BUILD_DIR%\phoenix-firestorm\build-vc170-64\newview\" >nul
    @REM copy /Y "%SCRIPT_DIR%\fs_include\freetype.dll" "%BUILD_DIR%\phoenix-firestorm\build-vc170-64\newview\" >nul
    @REM copy /Y "%SCRIPT_DIR%\fs_include\bz2.dll" "%BUILD_DIR%\phoenix-firestorm\build-vc170-64\newview\" >nul
    @REM copy /Y "%SCRIPT_DIR%\fs_include\libpng16.dll" "%BUILD_DIR%\phoenix-firestorm\build-vc170-64\newview\" >nul
    @REM copy /Y "%SCRIPT_DIR%\fs_include\brotlidec.dll" "%BUILD_DIR%\phoenix-firestorm\build-vc170-64\newview\" >nul
    @REM copy /Y "%SCRIPT_DIR%\fs_include\brotlicommon.dll" "%BUILD_DIR%\phoenix-firestorm\build-vc170-64\newview\" >nul
)


echo .
echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
echo .

echo 7. Build-Variablen und Anforderungen installieren >> %SCRIPT_DIR%fs-informationen\FirestormBuild.txt

:: ##### 7. **Build-Variablen und Anforderungen installieren**
:: #####    - Setzt Version, Architektur, lädt `requirements.txt`
echo %GREEN%Anforderungen installieren...%RESET%

set "AUTOBUILD_VSVER=170"
python -m pip install -r "%BUILD_DIR%\phoenix-firestorm\requirements.txt"


@REM echo .
@REM echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
@REM echo .

echo 8. Anpassung von autobuild.xml >> %SCRIPT_DIR%fs-informationen\FirestormBuild.txt

@REM :: ##### 8. **Anpassung von autobuild.xml**
@REM :: #####    - Ersetzt Originaldatei durch `openal_autobuild.xml` zur Sound-Anpassung
@REM echo %GREEN%Anpassung von autobuild.xml durch kopieren...%RESET%

@REM ::xcopy /E /I /Y "%SCRIPT_DIR%\autobuild.xml" "%BUILD_DIR%\phoenix-firestorm"
@REM copy /Y "%SCRIPT_DIR%\fs_include\autobuild.xml" "%BUILD_DIR%\phoenix-firestorm\autobuild.xml"


echo .
echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
echo .

echo 9. Aktivierung der Visual-Studio-Umgebung >> %SCRIPT_DIR%fs-informationen\FirestormBuild.txt

@REM :: ##### 9. **Aktivierung der Visual-Studio-Umgebung**
@REM :: #####    - Lädt `vcvarsall.bat` für das 64-Bit-Toolset von Visual Studio 2022
@REM echo %GREEN%Aktivierung der Visual-Studio-Umgebung...%RESET%

@REM set "VS2022BAT="
@REM for %%D in ("C:\Program Files\Microsoft Visual Studio\2022\Community") do (
@REM     if exist "%%~D\VC\Auxiliary\Build\vcvarsall.bat" (
@REM         set "VS2022BAT=%%~D\VC\Auxiliary\Build\vcvarsall.bat"
@REM     )
@REM )

@REM if not defined VS2022BAT (
@REM     echo %RED%[FEHLER] Visual Studio 2022 Build Tools nicht gefunden!%RESET%
@REM     pause
@REM     exit /b 1
@REM )

echo %GREEN%!FS2_TXT_ACTIVATE_VS!%RESET%

set "VS2022BAT="
if exist "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" (
    set "VS2022BAT=C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat"
) else if exist "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" (
    set "VS2022BAT=C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat"
) else if exist "C:\Program Files\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" (
    set "VS2022BAT=C:\Program Files\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat"
)

if not defined VS2022BAT (
    echo %RED%!FS2_TXT_ERR_VS_TOOLS_NOT_FOUND!%RESET%
    echo %YELLOW}Bitte Visual Studio 2022 oder Build Tools installieren%RESET%
    pause
    exit /b 1
)

echo %CYAN%Verwende: %VS2022BAT%%RESET%
call "%VS2022BAT%" x64
if errorlevel 1 (
    echo %RED%Fehler beim Aktivieren der VS-Umgebung%RESET%
    pause
    exit /b 1
)

call "%VS2022BAT%" x64


echo .
echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
echo .

echo 10. Aktivierung der Python-Umgebung >> %SCRIPT_DIR%fs-informationen\FirestormBuild.txt

:: ##### 10. **Aktivierung der Python-Umgebung**
:: #####     - (Erneut) Aktiviert Virtualenv für Folgeaktionen
echo %GREEN%Aktivierung der Python-Umgebung...%RESET%

if exist "%VENV_DIR%\Scripts\activate.bat" (
    call "%VENV_DIR%\Scripts\activate.bat"
) else (
    echo %RED%[FEHLER] Python-Virtualenv fehlt: %VENV_DIR%%RESET%
    pause
    exit /b 1
)


echo .
echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
echo .

echo 11. Prüfung der Build-Konfigurationsdatei >> %SCRIPT_DIR%fs-informationen\FirestormBuild.txt

:: ##### 11. **Prüfung der Build-Konfigurationsdatei**
:: #####     - Validiert, ob `autobuild.xml` vorhanden ist
echo %GREEN%Prüfung der Build-Konfigurationsdatei...%RESET%

if not exist "%AUTO_BUILD_CONFIG%" (
    echo %RED%[FEHLER] autobuild.xml fehlt!%RESET%
    pause
    exit /b 1
)


echo .
echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
echo .

echo 12. Wechsel ins Quellverzeichnis >> %SCRIPT_DIR%fs-informationen\FirestormBuild.txt

:: ##### 12. **Wechsel ins Quellverzeichnis**
:: #####     - Setzt aktuelles Arbeitsverzeichnis auf `phoenix-firestorm`
echo %GREEN%Wechsel ins Quellverzeichnis...%RESET%

cd /d "%BUILD_DIR%\phoenix-firestorm" || (
    echo %RED%[FEHLER] Quellverzeichnis nicht gefunden!%RESET%
    pause
    exit /b 1
)


echo .
echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
echo .

echo 14. Einbau der 3p Bibliotheken >> %SCRIPT_DIR%fs-informationen\FirestormBuild.txt

:: ##### 14. **Einbau der 3p Bibliotheken**
echo %GREEN%Installation einer neueren 3p-openal Bibliothek...%RESET%

:: Entfernen von fmodstudio
autobuild installables remove fmodstudio

:: TEST: Entfernen von 3p Bibliotheken
@REM autobuild installables remove zlib1
@REM autobuild installables remove freetype
@REM autobuild installables remove bz2
@REM autobuild installables remove libpng16
@REM autobuild installables remove brotlidec
@REM autobuild installables remove brotlicommon

autobuild installables edit openal platform=windows64 url=https://github.com/secondlife/3p-openal-soft/releases/download/v1.24.2-r1/openal-1.24.2-r1-windows64-13245988487.tar.zst hash_algorithm=sha1 hash=8ad24fba1191c9cb0d2ab36e64b04b4648a99f43

@REM autobuild installables edit zlib1 platform=windows64
@REM autobuild installables edit freetype platform=windows64 url=https://github.com/secondlife/3p-freetype/releases/download/v2.13.3-r4/freetype-2.13.3-r4-windows64-20935810762.tar.zst hash_algorithm=sha1 hash=3c30052adcbfec572562bb1e7927d7a8f4d93f3d
@REM autobuild installables edit bz2 platform=windows64
@REM autobuild installables edit libpng16 platform=windows64
@REM autobuild installables edit brotlidec platform=windows64
@REM autobuild installables edit brotlicommon platform=windows64

@REM Folgende Pakete werden nicht paketiert:
@REM zlib1, freetype , bz2 , libpng16 , brotlidec , brotlicommon

echo .
echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
echo .

echo 15. Konfiguration des Builds >> %SCRIPT_DIR%fs-informationen\FirestormBuild.txt

:: ##### 15. **Konfiguration des Builds**
:: #####     - Führt `autobuild configure` mit Flags für Channel, Paketierung, Audiooptionen aus

if not defined AUTOBUILD_BUILD_ID (
    for /f %%I in ('powershell -NoProfile -Command "[int][double]::Parse((Get-Date -UFormat %%s))"') do set "AUTOBUILD_BUILD_ID=%%I"
)

:: Konfiguration mit AVX2
echo %GREEN%Konfiguration mit AVX2 openal WebRTC...%RESET%
::autobuild configure --config-file "%AUTO_BUILD_CONFIG%" -A 64 -c ReleaseFS_open -- --avx2 --openal --package --chan WebRTC

@REM --chan: Geben Sie direkt im Anschluss den gewünschten Kanalnamen an. Beispiel: `autobuild configure -c ReleaseFS_open -- --chan MyCustomViewer` legt „MyCustomViewer“ als Kanal- und Viewer-Namen fest.
::autobuild configure --config-file "%AUTO_BUILD_CONFIG%" -A 64 -c ReleaseFS_open -- --avx2 --openal --package --chan OpenSimulator

:: Tests
autobuild configure --config-file "%AUTO_BUILD_CONFIG%" -A 64 -c ReleaseFS_open -- --opensim --platform windows --btype Release --avx2 --openal --package --chan OpenSimulator -DLL_TESTS:BOOL=FALSE
:: --opensim --platform windows --btype Release


@REM Es fehlen:
@REM zlib1.dll
@REM freetype.dll
@REM bz2.dll
@REM libpng16.dll
@REM brotlidec.dll
@REM brotlicommon.dll

:: Fehlende Packagen kopieren
    @REM copy /Y "%BUILD_DIR%\phoenix-firestorm\build-vc170-64\newview\Release\zlib1.dll" "%BUILD_DIR%\phoenix-firestorm\build-vc170-64\packages\Release\" >nul
    @REM copy /Y "%BUILD_DIR%\phoenix-firestorm\build-vc170-64\newview\Release\freetype.dll" "%BUILD_DIR%\phoenix-firestorm\build-vc170-64\packages\Release\" >nul
    @REM copy /Y "%BUILD_DIR%\phoenix-firestorm\build-vc170-64\newview\Release\bz2.dll" "%BUILD_DIR%\phoenix-firestorm\build-vc170-64\packages\Release\" >nul
    @REM copy /Y "%BUILD_DIR%\phoenix-firestorm\build-vc170-64\newview\Release\libpng16.dll" "%BUILD_DIR%\phoenix-firestorm\build-vc170-64\packages\Release\" >nul
    @REM copy /Y "%BUILD_DIR%\phoenix-firestorm\build-vc170-64\newview\Release\brotlidec.dll" "%BUILD_DIR%\phoenix-firestorm\build-vc170-64\packages\Release\" >nul
    @REM copy /Y "%BUILD_DIR%\phoenix-firestorm\build-vc170-64\newview\Release\brotlicommon.dll" "%BUILD_DIR%\phoenix-firestorm\build-vc170-64\packages\Release\" >nul

if errorlevel 1 (
    echo %RED%[FEHLER] Konfiguration fehlgeschlagen!%RESET%
    pause
    exit /b 1
)


echo .
echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
echo .
:: ##### 16. Build

echo 16. Build >> %SCRIPT_DIR%fs-informationen\FirestormBuild.txt

echo %GREEN%Build mit den gesetzten AVX2 openal WebRTC...%RESET%
:: Hier wird anscheinend OpenAL und weitere nicht implementiert obwohl sie in autobuild configure bereits implementiert wurden.
::autobuild build --config-file "%AUTO_BUILD_CONFIG%" -A 64 -c ReleaseFS_open --no-configure
autobuild build --config-file "%AUTO_BUILD_CONFIG%" -A 64 -c ReleaseFS_open -- --opensim --platform windows --btype Release --avx2 --openal --package --chan OpenSimulator

:: Info: autobuild build -A 64 --all

:: --opensim --platform windows --btype Release
:: -A 64 -c ReleaseFS_open -- --opensim --platform windows --btype Release --avx2 --openal --package --chan OpenSimulator
:: --debug

if errorlevel 1 (
    echo %RED%[FEHLER] Build fehlgeschlagen!%RESET%
    pause
    exit /b 1
)


echo .
echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
echo .

echo 17. Informationen exportieren >> %SCRIPT_DIR%fs-informationen\FirestormBuild.txt

:: ##### 17. Informationen exportieren
:: #####     - Exportiert Manifest, Liste installierter Pakete, Install-URLs, Versions
echo %GREEN%Exportiere Informationen...%RESET%
:: Setze Zielverzeichnis
set "TARGET_DIR=%SCRIPT_DIR%fs-informationen"
if not exist "%TARGET_DIR%" (
    mkdir "%TARGET_DIR%"
)

:: Setze Manifest-Datei
set "MANIFEST_FILE=%TARGET_DIR%\%SKRIPT_VERSION%_installed_manifest.txt"
set "LIST_FILE=%TARGET_DIR%\%SKRIPT_VERSION%_installed_list.txt"
set "VERSIONS_FILE=%TARGET_DIR%\%SKRIPT_VERSION%_versions.txt"


:: Optional: Setze Installationsverzeichnis falls bekannt
set "INSTALL_DIR=build"

:: Manifest exportieren
echo Exportiere Installationsmanifest...
autobuild install --installed-manifest "%MANIFEST_FILE%" --install-dir "%INSTALL_DIR%"
:: --debug

:: Liste installierter Pakete
echo Liste installierter Pakete...
autobuild install --list-installed > "%LIST_FILE%"

:: Versionsinformationen
echo Versionsinformationen erfassen...
autobuild install --versions > "%VERSIONS_FILE%"

echo.
echo ✅ Alle Informationen wurden in "%TARGET_DIR%" gespeichert.


:: NSIS installer

echo .
echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
echo .

echo 18. NSIS-Installer Vorbereitung (VOR dem Package!) >> %SCRIPT_DIR%fs-informationen\FirestormBuild.txt

:: ##### 18. NSIS-Installer Vorbereitung (MUSS VOR autobuild package ausgeführt werden!)
:: #####     - Fügt fehlende DLLs in die NSIS-Installationsdatei ein
echo %GREEN%Bereite NSIS-Installer vor...%RESET%

:: Pfade definieren
set "NSI_FILE=%BUILD_DIR%\phoenix-firestorm\build-vc170-64\newview\Release\firestorm_setup_tmp.nsi"
set "PKG_RELEASE=%BUILD_DIR%\phoenix-firestorm\build-vc170-64\packages\lib\release"

:: Stelle sicher, dass das packages/lib/release Verzeichnis existiert
if not exist "%PKG_RELEASE%" (
    echo Erstelle Paketverzeichnis: %PKG_RELEASE%
    mkdir "%PKG_RELEASE%" 2>nul
)

:: DLLs in das packages-Verzeichnis kopieren (falls sie noch nicht dort sind)
echo %GREEN%Kopiere DLLs in das packages-Verzeichnis...%RESET%
if exist "%OUTPUT_DIR%\alut.dll" (
    xcopy /Y "%OUTPUT_DIR%\alut.dll" "%PKG_RELEASE%\" 2>nul
)
if exist "%OUTPUT_DIR%\OpenAL32.dll" (
    xcopy /Y "%OUTPUT_DIR%\OpenAL32.dll" "%PKG_RELEASE%\" 2>nul
)
if exist "%OUTPUT_DIR%\zlib1.dll" (
    xcopy /Y "%OUTPUT_DIR%\zlib1.dll" "%PKG_RELEASE%\" 2>nul
)
if exist "%OUTPUT_DIR%\freetype.dll" (
    xcopy /Y "%OUTPUT_DIR%\freetype.dll" "%PKG_RELEASE%\" 2>nul
)
if exist "%OUTPUT_DIR%\bz2.dll" (
    xcopy /Y "%OUTPUT_DIR%\bz2.dll" "%PKG_RELEASE%\" 2>nul
)
if exist "%OUTPUT_DIR%\libpng16.dll" (
    xcopy /Y "%OUTPUT_DIR%\libpng16.dll" "%PKG_RELEASE%\" 2>nul
)
if exist "%OUTPUT_DIR%\brotlidec.dll" (
    xcopy /Y "%OUTPUT_DIR%\brotlidec.dll" "%PKG_RELEASE%\" 2>nul
)
if exist "%OUTPUT_DIR%\brotlicommon.dll" (
    xcopy /Y "%OUTPUT_DIR%\brotlicommon.dll" "%PKG_RELEASE%\" 2>nul
)

echo DLLs wurden in %PKG_RELEASE% kopiert.

:: Jetzt die NSI-Datei bearbeiten - HIER MÜSSEN DIE FILE-ENTRIES EINGEFÜGT WERDEN
echo %GREEN%Füge DLL-Dateien in NSIS-Installer ein...%RESET%

if not exist "%NSI_FILE%" (
    echo %RED%FEHLER: NSI-Datei nicht gefunden: %NSI_FILE%%RESET%
    pause
    exit /b 1
)

:: Backup der NSI-Datei erstellen
copy "%NSI_FILE%" "%NSI_FILE%.backup" >nul
echo Backup erstellt: %NSI_FILE%.backup

:: Füge die File-Einträge nach "SetOutPath $INSTDIR" ein
echo Füge File-Einträge nach 'SetOutPath $INSTDIR' ein...

(
    for /f "delims=" %%a in ('type "%NSI_FILE%"') do (
        echo %%a
        if "%%a"=="SetOutPath $INSTDIR" (
            echo File D:\opensim-dev\Firestorm_Build\phoenix-firestorm\build-vc170-64\newview\Release\alut.dll
            echo File D:\opensim-dev\Firestorm_Build\phoenix-firestorm\build-vc170-64\newview\Release\brotlicommon.dll
            echo File D:\opensim-dev\Firestorm_Build\phoenix-firestorm\build-vc170-64\newview\Release\brotlidec.dll
            echo File D:\opensim-dev\Firestorm_Build\phoenix-firestorm\build-vc170-64\newview\Release\bz2.dll
            echo File D:\opensim-dev\Firestorm_Build\phoenix-firestorm\build-vc170-64\newview\Release\freetype.dll
            echo File D:\opensim-dev\Firestorm_Build\phoenix-firestorm\build-vc170-64\newview\Release\libpng16.dll
            echo File D:\opensim-dev\Firestorm_Build\phoenix-firestorm\build-vc170-64\newview\Release\zlib1.dll
        )
    )
) > "%NSI_FILE%.new"

:: Ersetze die alte Datei mit der neuen
move "%NSI_FILE%.new" "%NSI_FILE%" >nul

echo %GREEN%NSI-Datei wurde erfolgreich aktualisiert!%RESET%
echo Die folgenden DLLs wurden in den Installer eingefügt:
echo   - alut.dll
echo   - brotlicommon.dll
echo   - brotlidec.dll
echo   - bz2.dll
echo   - freetype.dll
echo   - libpng16.dll
echo   - zlib1.dll

echo .
echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
echo .

echo 19. Paketieren des Firestorm >> %SCRIPT_DIR%fs-informationen\FirestormBuild.txt

:: ##### 19. Paketieren des Firestorm (JETZT mit der aktualisierten NSI-Datei!)
:: #####     - Führt `autobuild package` aus, das jetzt die aktualisierte NSI-Datei verwendet
echo %GREEN%Erstelle Installer-Paket mit NSIS...%RESET%

:: Wichtig: autobuild package verwendet die NSI-Datei, die wir gerade aktualisiert haben
autobuild package --config-file "%SCRIPT_DIR%Firestorm_Build\phoenix-firestorm\autobuild.xml" -A 64 --results-file result.txt -c Release --build-dir="%SCRIPT_DIR%Firestorm_Build\phoenix-firestorm\build-vc170-64"

@REM if errorlevel 1 (
@REM     echo %RED%FEHLER: Package-Erstellung fehlgeschlagen!%RESET%
@REM     pause
@REM     exit /b 1
@REM )

echo %GREEN%Installer wurde erfolgreich erstellt!%RESET%

echo .
echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
echo .

echo 20. Kopieren des Firestorm Installer Paket nach release >> %SCRIPT_DIR%fs-informationen\FirestormBuild.txt

:: ##### 20. Kopieren des Installers
:: #####     - Kopiert die erstellte _Setup.exe in das release-Verzeichnis
echo %GREEN%Kopiere Installer in release-Verzeichnis...%RESET%
set "SOURCE=%SCRIPT_DIR%Firestorm_Build\phoenix-firestorm\build-vc170-64\newview\Release\"
set "TARGET=%SCRIPT_DIR%release\"

if not exist "%TARGET%" mkdir "%TARGET%"

for %%f in ("%SOURCE%*_Setup.exe") do (
    if exist "%%f" (
        if not exist "%TARGET%%%~nxf" (
            copy "%%f" "%TARGET%"
            echo Kopiert wurde: %%~nxf
        ) else (
            echo Übersprungen weil bereits existiert: %%~nxf
        )
    )
)

echo .
echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
echo .

echo 21. Der Firestorm Viewer wurde gebaut und kopiert! >> %SCRIPT_DIR%fs-informationen\FirestormBuild.txt

echo %GREEN%=== Build abgeschlossen! ===%RESET%
echo Der Firestorm Viewer wurde erfolgreich erstellt.
echo Die Installationsdatei befindet sich in: %TARGET%
echo Log-Dateien: %SCRIPT_DIR%Firestorm_Build\phoenix-firestorm\build-vc170-64\logs\

pause
exit /b 0

:: NSIS installer Ende
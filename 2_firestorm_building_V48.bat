@echo off
:: Schaltet die Anzeige der Befehle im Konsolenfenster aus, damit die Ausgabe übersichtlich bleibt.

chcp 65001 >nul
:: Setzt die Codepage auf UTF-8, damit Sonderzeichen korrekt dargestellt werden.

setlocal enabledelayedexpansion
:: Aktiviert verzögerte Variablienerweiterung, nützlich für komplexere Batch-Operationen.

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

set SKRIPT_VERSION="V47-20260319"

:: Überschrift für die Build-Vorbereitung
echo %GREEN% Firestorm Build Vorbereitung %SKRIPT_VERSION% %RESET%
echo .
echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
echo .
:: ##### 3. **Grundkonfiguration und Variablen**
:: Definition von Skriptpfad, Zielordnern, Konfigurationsparametern
echo %GREEN%Konfiguration...%RESET%

:: Kein link.exe von Github nutzen (Git überschreibt manchmal Windows-Tools)
set "SCRIPT_DIR=%~dp0"  :: Pfad zu diesem Skript

:: Stelle sicher, dass alle relativen Pfade auf dieses Skriptverzeichnis zeigen.
cd /d "%SCRIPT_DIR%" || (
    echo %RED%[FEHLER] Konnte nicht in das Skriptverzeichnis wechseln: %SCRIPT_DIR%%RESET%
    pause
    exit /b 1
)

:: Git's Unix-Tools aus dem PATH entfernen
set "PATH=%PATH:C:\Program Files\Git\usr\bin;=%"

:: Cygwin-Bash fuer autobuild configure sicherstellen
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
call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" x64

::set "PYTHON_VERSION=3.10.11"  :: Gewünschte Python-Version
set "PYTHON_VERSION=3.13.3"  :: Neue Python-Version? anscheinend keine Funktion.

set "BUILD_DIR=%SCRIPT_DIR%Firestorm_Build"  :: Zielverzeichnis für den Build
set "VENV_DIR=%BUILD_DIR%\venv"  :: Virtuelle Python-Umgebung
set "ProgramFiles=C:\Program Files"  :: Standard-Programmpfad
set "AUTOBUILD_INSTALL_DIR=%BUILD_DIR%\packages"  :: Installationsverzeichnis für Autobuild-Pakete

set "ARCH=64"  :: Architektur
set "CONFIG=ReleaseFS_open"  :: Build-Konfiguration
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
:: ##### 4. **Erstellung des Arbeitsverzeichnisses**
:: #####    - Legt den Build-Ordner an (sofern nicht vorhanden)
echo %GREEN%Erstelle Build-Verzeichnis%RESET%

mkdir "%BUILD_DIR%" 2>nul

echo .
echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
echo .
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

:: 1. fs_include ins Build-Verzeichnis kopieren
set "FS_INCLUDE_SOURCE=%SCRIPT_DIR%\fs_include"
set "FS_INCLUDE_DEST=%BUILD_DIR%\fs_include"

if exist "%FS_INCLUDE_SOURCE%" (
    echo %GREEN%Kopiere fs_include in das Build-Verzeichnis...%RESET%
    xcopy /E /I /Y "%FS_INCLUDE_SOURCE%" "%FS_INCLUDE_DEST%\" >nul
) else (
    echo %RED%[FEHLER] fs_include nicht gefunden in: %FS_INCLUDE_SOURCE%%RESET%
    exit /b 1
)

:: 2. Pfade für CMake setzen
set "ASSIMP_ROOT=%FS_INCLUDE_DEST%\assimp-windows64-5.2.5-r3"
set "OPENAL_ROOT=%FS_INCLUDE_DEST%\openal-1.24.2-r1-windows64-13245988487"


echo .
echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
echo .
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
echo %GREEN%Skin Kopieren %BUILD_DIR%...%RESET%

xcopy /E /I /Y "%SCRIPT_DIR%Skin\skins.xml" "%BUILD_DIR%\phoenix-firestorm\indra\newview\skins"
xcopy /E /I /Y "%SCRIPT_DIR%Skin\singularity" "%BUILD_DIR%\phoenix-firestorm\indra\newview\skins\singularity"

echo .
echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
echo .
:: cmake änderungen Kopieren
echo %GREEN%CMAKE Kopieren %BUILD_DIR%...%RESET%

xcopy /E /I /Y "%SCRIPT_DIR%fs_include\OPENAL.cmake" "%BUILD_DIR%\phoenix-firestorm\indra\cmake"
xcopy /E /I /Y "%SCRIPT_DIR%fs_include\Assimp.cmake" "%BUILD_DIR%\phoenix-firestorm\indra\cmake"

echo .
echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
echo .
:: Include Dateien in den Sourcecode einfügen.
echo %GREEN%Führe Dateikopierungen aus...%RESET%

:: 1. ZUERST das fs_include-Verzeichnis kopieren (falls noch nicht vorhanden)
if not exist "%FS_INCLUDE_DEST%\" (
    xcopy /E /I /Y "%FS_INCLUDE_SOURCE%" "%FS_INCLUDE_DEST%\" >nul
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
)


echo .
echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
echo .
:: ##### 7. **Build-Variablen und Anforderungen installieren**
:: #####    - Setzt Version, Architektur, lädt `requirements.txt`
echo %GREEN%Anforderungen installieren...%RESET%

set "AUTOBUILD_VSVER=170"
python -m pip install -r "%BUILD_DIR%\phoenix-firestorm\requirements.txt"


@REM echo .
@REM echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
@REM echo .
@REM :: ##### 8. **Anpassung von autobuild.xml**
@REM :: #####    - Ersetzt Originaldatei durch `openal_autobuild.xml` zur Sound-Anpassung
@REM echo %GREEN%Anpassung von autobuild.xml durch kopieren...%RESET%

@REM ::xcopy /E /I /Y "%SCRIPT_DIR%\autobuild.xml" "%BUILD_DIR%\phoenix-firestorm"
@REM copy /Y "%SCRIPT_DIR%\fs_include\autobuild.xml" "%BUILD_DIR%\phoenix-firestorm\autobuild.xml"


echo .
echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
echo .
:: ##### 9. **Aktivierung der Visual-Studio-Umgebung**
:: #####    - Lädt `vcvarsall.bat` für das 64-Bit-Toolset von Visual Studio 2022
echo %GREEN%Aktivierung der Visual-Studio-Umgebung...%RESET%

set "VS2022BAT="
for %%D in ("C:\Program Files\Microsoft Visual Studio\2022\Community") do (
    if exist "%%~D\VC\Auxiliary\Build\vcvarsall.bat" (
        set "VS2022BAT=%%~D\VC\Auxiliary\Build\vcvarsall.bat"
    )
)

if not defined VS2022BAT (
    echo %RED%[FEHLER] Visual Studio 2022 Build Tools nicht gefunden!%RESET%
    pause
    exit /b 1
)

call "%VS2022BAT%" x64


echo .
echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
echo .
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
:: ##### 14. **Einbau der 3p Bibliotheken**
echo %GREEN%Installation einer neueren 3p-openal Bibliothek...%RESET%

:: Entfernen von fmodstudio
autobuild installables remove fmodstudio

autobuild installables edit openal platform=windows64 url=https://github.com/secondlife/3p-openal-soft/releases/download/v1.24.2-r1/openal-1.24.2-r1-windows64-13245988487.tar.zst hash_algorithm=sha1 hash=8ad24fba1191c9cb0d2ab36e64b04b4648a99f43

@REM echo .
@REM echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
@REM echo .
@REM :: ##### Assimp hinzufügen
@REM echo %GREEN%Installation der 3p-assimp Bibliothek...%RESET%

@REM autobuild installables remove assimp
@REM autobuild installables add assimp platform=windows64 url=https://github.com/secondlife/3p-assimp/releases/download/v5.2.5-r3/assimp-windows64-5.2.5-r3.tar.bz2 hash=8b878487089380b43a8b2109dfc6ab8bbebd4009 hash_algorithm=sha1

@REM echo .
@REM echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
@REM echo .
:: WebRTC austausch gegen eine neuere Version
::echo %GREEN%Installation einer neueren 3p-webrtc Bibliothek...%RESET%

::autobuild installables remove webrtc
::autobuild installables add webrtc platform=windows64 url=https://github.com/secondlife/3p-webrtc-build/releases/download/m114.5735.08.73-alpha/webrtc-m114.5735.08.73-alpha.11958809572-windows64-11958809572.tar.zst hash_algorithm=sha1 hash=c7b329d6409576af6eb5b80655b007f52639c43b
::autobuild installables add webrtc platform=windows64 url=https://github.com/secondlife/3p-webrtc-build/releases/download/m137.7151.04.20-universal/webrtc-m137.7151.04.20-universal.17630578914-windows64-17630578914.tar.zst hash_algorithm=sha1 hash=1e36f100de32c7c71325497a672fb1659b3f206d
::autobuild installables add webrtc platform=windows64 url=https://github.com/secondlife/3p-webrtc-build/releases/download/m137.7151.04.20-universal/webrtc-m137.7151.04.20-universal.17630578914-windows64-17630578914.tar.zst hash_algorithm=sha1 hash=1e36f100de32c7c71325497a672fb1659b3f206d

:: NEUE TEST PAKETE

@REM echo .
@REM echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
@REM echo .
@REM :: ##### boost Suite aktualisieren
@REM autobuild installables remove boost
@REM echo %GREEN%Installation der boost Bibliothek...%RESET%
@REM autobuild installables add boost platform=darwin64 url=https://github.com/secondlife/3p-boost/releases/download/v1.86.0-be1a669/boost-1.86-darwin64-13246092114.tar.zst hash_algorithm=sha1 hash=a4553df5b8fde2e9cd54ebb94c6efb8eb5fe3c38

@REM :: Diverse Pakete die benötigt werden
@REM autobuild installables edit curl platform=windows64 url=https://github.com/secondlife/3p-curl/releases/download/v7.54.1-r3/curl-7.54.1-13259824618-windows64-13259824618.tar.zst hash_algorithm=sha1 hash=2522201692116cf0adb7203e169be9126885108c
@REM autobuild installables edit openssl platform=windows64 url=https://github.com/secondlife/3p-openssl/releases/download/v1.1.1w-r3/openssl-1.1.1w-r3-windows64-13246054022.tar.zst hash_algorithm=sha1 hash=ae9ced89051e03a99628c99b9ac78530fdea1e5a
@REM autobuild installables edit freetype platform=windows64 url=https://github.com/secondlife/3p-freetype/releases/download/v2.13.3-r3/freetype-2.13.3-r3-windows64-13259804885.tar.zst hash_algorithm=sha1 hash=ad7fbc4a01607ec43d86035a49dadd43d6f2a4e5

@REM echo .
@REM echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
@REM echo .
@REM :: ##### zlib-ng Suite aktualisieren
@REM ::autobuild installables remove zlib-ng
@REM echo %GREEN%Installation der 3p-zlib-ng Bibliothek...%RESET%

@REM autobuild installables edit zlib-ng platform=windows64 url=https://github.com/secondlife/3p-zlib-ng/releases/download/v2.2.3-r1/zlib_ng-2.2.3-dev0.g8aa13e3.d20250206-windows64-13183604450.tar.zst hash_algorithm=sha1 hash=e802a28139328bb2421ad39e13d996d350d8106d


@REM echo .
@REM echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
@REM echo .
@REM :: ##### APR Suite aktualisieren
@REM ::autobuild installables remove apr_suite
@REM echo %GREEN%Installation der 3p-apr_suite Bibliothek...%RESET%

@REM ::autobuild installables add apr_suite platform=windows64 url=https://github.com/secondlife/3p-apr_suite/releases/download/v1.7.5-r1/apr_suite-1.7.5-12259255574-windows64-12259255574.tar.zst hash_algorithm=sha1 hash=bdd35d3b9580d3cdcb98afae639936aaa40e24c4
@REM autobuild installables edit apr_suite platform=windows64 url=https://github.com/secondlife/3p-apr_suite/releases/download/v1.7.5-r1/apr_suite-1.7.5-12259255574-windows64-12259255574.tar.zst hash_algorithm=sha1 hash=bdd35d3b9580d3cdcb98afae639936aaa40e24c4

@REM echo .
@REM echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
@REM echo .
@REM :: ##### CEF-Bin aktualisieren
@REM ::autobuild installables remove cef-bin
@REM echo %GREEN%Installation der 3p-cef-bin Bibliothek...%RESET%

@REM ::autobuild installables add cef-bin platform=windows64 url=https://github.com/secondlife/dullahan/releases/download/v1.21.0-CEF_139.0.28/dullahan-1.21.0.202508272159_139.0.28_g55ab8a8_chromium-139.0.7258.139-windows64-17279703032.tar.zst hash_algorithm=sha1 hash=9d5af766a87052808e4062978504e9af124fb558
@REM autobuild installables edit dullahan platform=windows64 url=https://github.com/secondlife/dullahan/releases/download/v1.23.0-CEF_139.0.40/dullahan-1.23.0.202509121512_139.0.40_g465474a_chromium-139.0.7258.139-windows64-17678469374.tar.zst hash_algorithm=sha1 hash=fe4f9e9109bd5784a965cee9b33c89a080f3972f

@REM echo .
@REM echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
@REM echo .
@REM :: ##### ColladaDOM aktualisieren
@REM autobuild installables remove colladadom
@REM echo %GREEN%Installation der 3p-colladadom Bibliothek...%RESET%

@REM autobuild installables add colladadom platform=windows64 url=https://github.com/secondlife/3p-colladadom/releases/download/v2.3-r10/colladadom-2.3.0-r10-windows64-13259816660.tar.zst hash_algorithm=sha1 hash=d7aee1b2ec17bd88a2c27359281b58a11ec52d48

@REM echo .
@REM echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
@REM echo .
@REM :: ##### Dullahan aktualisieren
@REM autobuild installables remove dullahan
@REM echo %GREEN%Installation der 3p-dullahan Bibliothek...%RESET%

@REM autobuild installables add dullahan platform=windows64 url=https://github.com/secondlife/dullahan/releases/download/v1.21.0-CEF_139.0.28/dullahan-1.21.0.202508272159_139.0.28_g55ab8a8_chromium-139.0.7258.139-windows64-17279703032.tar.zst hash_algorithm=sha1 hash=9d5af766a87052808e4062978504e9af124fb558

@REM echo .
@REM echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
@REM echo .
@REM :: ##### Expat aktualisieren
@REM autobuild installables remove expat
@REM echo %GREEN%Installation der 3p-expat Bibliothek...%RESET%

@REM autobuild installables add expat platform=windows64 url=https://github.com/secondlife/3p-expat/releases/download/v2.6.4-r1/expat-2.6.4-r1-windows64-11943227858.tar.zst hash_algorithm=sha1 hash=542af7d8bb8de3297c80c23a771bbcb513a630b7

@REM echo .
@REM echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
@REM echo .
@REM :: ##### libjpeg-turbo aktualisieren
@REM autobuild installables remove libjpeg-turbo
@REM echo %GREEN%Installation der 3p-libjpeg-turbo Bibliothek...%RESET%

@REM autobuild installables add libjpeg-turbo platform=windows64 url=https://github.com/secondlife/3p-libjpeg-turbo/releases/download/v3.0.4-r1/libjpeg_turbo-3.0.4-r1-windows64-11968659895.tar.zst hash_algorithm=sha1 hash=10f14875ce5c7f5028217c8b7468733190fd333d

@REM echo .
@REM echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
@REM echo .
@REM :: ##### libpng aktualisieren
@REM autobuild installables remove libpng
@REM echo %GREEN%Installation der 3p-libpng Bibliothek...%RESET%

@REM autobuild installables add libpng platform=windows64 url=https://github.com/secondlife/3p-libpng/releases/download/v1.6.44-r2/libpng-1.6.44-r2-windows64-13246065198.tar.zst hash_algorithm=sha1 hash=09af51774c4ee7c03fe67a87dfc52e846aa625ea

@REM echo .
@REM echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
@REM echo .
@REM :: ##### libxml2 aktualisieren
@REM autobuild installables remove libxml2
@REM echo %GREEN%Installation der 3p-libxml2 Bibliothek...%RESET%

@REM autobuild installables add libxml2 platform=windows64 url=https://github.com/secondlife/3p-libxml2/releases/download/v2.13.5-r2/libxml2-2.13.5-r2-windows64-13246071272.tar.zst hash_algorithm=sha1 hash=71968c4b621636e8ae0c5680e631f4aa67561944

@REM echo .
@REM echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
@REM echo .
@REM :: ##### Meshoptimizer aktualisieren
@REM autobuild installables remove meshoptimizer
@REM echo %GREEN%Installation der 3p-meshoptimizer Bibliothek...%RESET%

@REM autobuild installables add meshoptimizer platform=windows64 url=https://github.com/secondlife/3p-meshoptimizer/releases/download/v220-r1/meshoptimizer-220.0.0-r1-windows64-11968851109.tar.zst hash_algorithm=sha1 hash=6fd727a9ccb3e7a6c6b4ffef8179e266c032eb3e

@REM echo .
@REM echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
@REM echo .
@REM :: ##### Mikktspace aktualisieren
@REM autobuild installables remove mikktspace
@REM echo %GREEN%Installation der 3p-mikktspace Bibliothek...%RESET%

@REM autobuild installables add mikktspace platform=windows64 url=https://github.com/secondlife/3p-mikktspace/releases/download/v2-e967e1b/mikktspace-1-windows64-8756084692.tar.zst hash_algorithm=sha1 hash=130b33a70bdb3a8a188376c6a91840bdb61380a8

@REM echo .
@REM echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
@REM echo .
@REM :: ##### Minizip-ng aktualisieren
@REM autobuild installables remove minizip-ng
@REM echo %GREEN%Installation der 3p-minizip-ng Bibliothek...%RESET%

@REM autobuild installables add minizip-ng platform=windows64 url=https://github.com/secondlife/3p-minizip-ng/releases/download/v4.0.7-r3/minizip_ng-4.0.7-r3-windows64-13246046977.tar.zst hash_algorithm=sha1 hash=58773e707ff3490822b7b8217d7729ade2186632

@REM echo .
@REM echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
@REM echo .
@REM :: ##### nghttp2 aktualisieren
@REM autobuild installables remove nghttp2
@REM echo %GREEN%Installation der 3p-nghttp2 Bibliothek...%RESET%

@REM autobuild installables add nghttp2 platform=windows64 url=https://github.com/secondlife/3p-nghttp2/releases/download/v1.64.0-r2/nghttp2-1.64.0-r1-windows64-13184359419.tar.zst hash_algorithm=sha1 hash=3bd92f892e155104740570fe244ea4dbb0b57d4b

@REM echo .
@REM echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
@REM echo .
@REM :: ##### OpenJPEG aktualisieren
@REM autobuild installables remove openjpeg
@REM echo %GREEN%Installation der 3p-openjpeg Bibliothek...%RESET%

@REM autobuild installables add openjpeg platform=windows64 url=https://github.com/secondlife/3p-openjpeg/releases/download/v2.5.3-r1/openjpeg-2.5.3.15590356935-windows64-15590356935.tar.zst hash_algorithm=sha1 hash=8aab9cf250dfee252386e1c79b5205e6d3b3e19e

@REM echo .
@REM echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
@REM echo .
@REM :: ##### Viewer-Fonts aktualisieren
@REM autobuild installables remove viewer-fonts
@REM echo %GREEN%Installation der 3p-viewer-fonts Bibliothek...%RESET%

@REM autobuild installables add viewer-fonts platform=windows64 url=https://github.com/secondlife/3p-viewer-fonts/releases/download/v1.1.0-r1/viewer_fonts-1.0.0.10204976553-common-10204976553.tar.zst hash_algorithm=sha1 hash=e88a7c97a6843d43e0093388f211299ec2892790

@REM echo .
@REM echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
@REM echo .
@REM :: ##### VLC-Bin aktualisieren
@REM autobuild installables remove vlc-bin
@REM echo %GREEN%Installation der 3p-vlc-bin Bibliothek...%RESET%

@REM ::autobuild installables add vlc-bin platform=windows64 url=https://github.com/secondlife/3p-vlc-bin/releases/download/v3.0.21.296d9f4/vlc_bin-3.0.21.11968962952-windows64-11968962952.tar.zst hash_algorithm=sha1 hash=f986e6e93acf8a32
@REM autobuild installables add vlc-bin platform=windows64 url=https://github.com/secondlife/3p-vlc-bin/releases/download/v3.0.21.296d9f4/vlc_bin-3.0.21.11968962952-windows64-11968962952.tar.zst hash_algorithm=sha1 hash=f986e6e93acf8a32a8be5b638f0bd0e2e07d7507

:: NEUE TEST PAKETE ENDE

:: NEUE TEST PAKETE Version 2025.09.30

:: FMOD Studio entfernen
::autobuild installables remove fmodstudio

:: Wahrscheinlich müssen die Pakete vorher entfrernt werden.
:: autobuild installables remove <paketname>

@REM autobuild installables remove apr_suite
@REM autobuild installables remove boost
@REM autobuild installables remove bugsplat
@REM autobuild installables remove colladadom
@REM autobuild installables remove cubemaptoequirectangular
@REM autobuild installables remove curl
@REM autobuild installables remove dullahan
@REM autobuild installables remove emoji_shortcodes
@REM autobuild installables remove expat
@REM autobuild installables remove freetype
@REM autobuild installables remove glext
@REM autobuild installables remove glh_linear
@REM autobuild installables remove glm
@REM autobuild installables remove jpegencoderbasic
@REM autobuild installables remove libjpeg-turbo
@REM autobuild installables remove libhunspell
@REM autobuild installables remove libndofdev
@REM autobuild installables remove libpng
@REM autobuild installables remove libxml2
@REM autobuild installables remove llca
@REM autobuild installables remove meshoptimizer
@REM autobuild installables remove mikktspace
@REM autobuild installables remove minizip-ng
@REM autobuild installables remove nghttp2
@REM autobuild installables remove nvapi
@REM autobuild installables remove ogg_vorbis
@REM autobuild installables remove openal
@REM autobuild installables remove openjpeg
@REM autobuild installables remove openssl
@REM autobuild installables remove openxr
@REM autobuild installables remove threejs
@REM autobuild installables remove tinygltf
@REM autobuild installables remove tracy
@REM autobuild installables remove tut
@REM autobuild installables remove viewer-manager
@REM autobuild installables remove vlc-bin
@REM autobuild installables remove vulkan_gltf
@REM autobuild installables remove xxhash
::autobuild installables remove zlib-ng
@REM autobuild installables remove tinyexr

@REM CMAKE Kopieren D:\01102025firestorm\Firestorm_Build...


::autobuild installables remove webrtc
:: Alpha Version:
::autobuild installables add webrtc platform=windows64 url=https://github.com/secondlife/3p-webrtc-build/releases/download/m114.5735.08.73-alpha/webrtc-m114.5735.08.73-alpha.11958809572-windows64-11958809572.tar.zst hash_algorithm=sha1 hash=c7b329d6409576af6eb5b80655b007f52639c43b
:: Debug Version:
::autobuild installables edit webrtc platform=windows64 url=https://github.com/secondlife/3p-webrtc-build/releases/download/m114.5735.08.72-debug/webrtc-m114.5735.08.72-debug.10438479298-windows64-10438479298.tar.zst hash_algorithm=sha1 hash=379e29faa67a826729179f7228146e2812a6088a
:: Universal Version:
::autobuild installables add webrtc platform=windows64 url=https://github.com/secondlife/3p-webrtc-build/releases/download/m137.7151.04.20-universal/webrtc-m137.7151.04.20-universal.17630578914-windows64-17630578914.tar.zst hash_algorithm=sha1 hash=1e36f100de32c7c71325497a672fb1659b3f206d

::autobuild installables edit apr_suite platform=windows64 url=https://github.com/secondlife/3p-apr_suite/releases/download/v1.7.5-r1/apr_suite-1.7.5-12259255574-windows64-12259255574.tar.zst hash_algorithm=sha1 hash=bdd35d3b9580d3cdcb98afae639936aaa40e24c4
::autobuild installables edit boost platform=windows64 url=https://github.com/secondlife/3p-boost/releases/download/v1.86.0-be1a669/boost-1.86-windows64-13246092114.tar.zst hash_algorithm=sha1 hash=8a1fa9366bfe49009286e4805d7aaedb7c3df82e
::autobuild installables edit bugsplat platform=windows64 url=https://github.com/secondlife/3p-bugsplat/releases/download/v1.1.5-93386f3/bugsplat-5.0.1.0-10062036993-windows64-10062036993.tar.zst hash_algorithm=sha1 hash=c41c6d6d889808d714f0aca8d563fa171956c61a

:: Fehler
::autobuild installables edit colladadom platform=windows64 url=https://github.com/secondlife/3p-colladadom/releases/download/v2.3-r10/colladadom-2.3.0-r10-windows64-13259816660.tar.zst hash_algorithm=sha1 hash=d7aee1b2ec17bd88a2c27359281b58a11ec52d48
@REM autobuild installables add cubemaptoequirectangular platform=windows64 url=https://github.com/secondlife/3p-cubemap_to_eqr_js/releases/download/v1.1.0-cb8785a/cubemaptoequirectangular-1.1.0-windows64-cb8785a.tar.zst hash_algorithm=sha1 hash=eabc3b0c9d9084f49b8a4dc5d3834d77f668c27a
@REM autobuild installables add curl platform=windows64 url=https://github.com/secondlife/3p-curl/releases/download/v7.54.1-r3/curl-7.54.1-13259824618-windows64-13259824618.tar.zst hash_algorithm=sha1 hash=2522201692116cf0adb7203e169be9126885108c

@REM autobuild installables add dullahan platform=windows64 url=https://github.com/secondlife/dullahan/releases/download/v1.23.0-CEF_139.0.40/dullahan-1.23.0.202509121512_139.0.40_g465474a_chromium-139.0.7258.139-windows64-17678469374.tar.zst hash_algorithm=sha1 hash=fe4f9e9109bd5784a965cee9b33c89a080f3972f
@REM autobuild installables add emoji_shortcodes platform=common url=https://github.com/secondlife/3p-emoji-shortcodes/releases/download/v15.3.2-r1/emoji_shortcodes-15.3.2.10207138275-common-10207138275.tar.zst hash_algorithm=sha1 hash=9c58108270fbad15a321f75501cdfb9c6b78a6f2
@REM autobuild installables add expat platform=windows64 url=https://github.com/secondlife/3p-expat/releases/download/v2.6.4-r1/expat-2.6.4-r1-windows64-11943227858.tar.zst hash_algorithm=sha1 hash=542af7d8bb8de3297c80c23a771bbcb513a630b7

@REM autobuild installables add freetype platform=windows64 url=https://github.com/secondlife/3p-freetype/releases/download/v2.13.3-r3/freetype-2.13.3-r3-windows64-13259804885.tar.zst hash_algorithm=sha1 hash=ad7fbc4a01607ec43d86035a49dadd43d6f2a4e5
@REM autobuild installables add glext platform=common url=https://github.com/secondlife/3p-glext/releases/download/v68-af397ee/glext-68-common-af397ee.tar.zst hash_algorithm=sha1 hash=34af0a90a3015b7e7ec2486090bc4ce6ee5be758
@REM autobuild installables add glh_linear platform=common url=https://github.com/secondlife/3p-glh_linear/releases/download/v1.0.1-dev4-984c397/glh_linear-1.0.1-dev4-common-984c397.tar.zst hash_algorithm=sha1 hash=066625e7aa7f697a4b6cd461aad960c57181011f

@REM autobuild installables add glm platform=common url=https://github.com/secondlife/3p-glm/releases/download/v1.0.1-r1/glm-v1.0.1-common-9066386153.tar.zst hash_algorithm=sha1 hash=353ae3a560143732503a8e14499ae12db1e66056
@REM autobuild installables add jpegencoderbasic platform=windows64 url=https://github.com/secondlife/3p-jpeg_encoder_js/releases/download/v1.0-790015a/jpegencoderbasic-1.0-windows64-790015a.tar.zst hash_algorithm=sha1 hash=23e8ba22aadf88d249a21844bfcdd01138c05937
@REM autobuild installables add libjpeg-turbo platform=windows64 url=https://github.com/secondlife/3p-libjpeg-turbo/releases/download/v3.0.4-r1/libjpeg_turbo-3.0.4-r1-windows64-11968659895.tar.zst hash_algorithm=sha1 hash=10f14875ce5c7f5028217c8b7468733190fd333d

@REM autobuild installables add libhunspell platform=windows64 url=https://github.com/secondlife/3p-libhunspell/releases/download/v1.7.2-r2/libhunspell-1.7.2.11968900321-windows64-11968900321.tar.zst hash_algorithm=sha1 hash=0f7b9c46dc4e81a6296e4836467f5fe52aa5761d
@REM autobuild installables add libndofdev platform=windows64 url=https://github.com/secondlife/3p-libndofdev/releases/download/v0.1.a0b7d99/libndofdev-0.1.11968678219-windows64-11968678219.tar.zst hash_algorithm=sha1 hash=7b3e504885c4c0cc75db298e682f408c4f2e95f7
::autobuild installables add libpng platform=windows64 url=https://github.com/secondlife/3p-libpng/releases/download/v1.6.44-r2/libpng-1.6.44-r2-windows64-13246065198.tar.zst hash_algorithm=sha1 hash=09af51774c4ee7c03fe67a87dfc52e846aa625ea

::autobuild installables edit libxml2 platform=windows64 url=https://github.com/secondlife/3p-libxml2/releases/download/v2.13.5-r2/libxml2-2.13.5-r2-windows64-13246071272.tar.zst hash_algorithm=sha1 hash=71968c4b621636e8ae0c5680e631f4aa67561944
@REM autobuild installables add llca platform=common url=https://github.com/secondlife/llca/releases/download/v202407221723.0-a0fd5b9/llca-202407221423.0-common-10042698865.tar.zst hash_algorithm=sha1 hash=6d6771706a5b70caa24893ff62afc925f8d035f6
@REM autobuild installables add meshoptimizer platform=windows64 url=https://github.com/secondlife/3p-meshoptimizer/releases/download/v220-r1/meshoptimizer-220.0.0-r1-windows64-11968851109.tar.zst hash_algorithm=sha1 hash=6fd727a9ccb3e7a6c6b4ffef8179e266c032eb3e

@REM autobuild installables add mikktspace platform=windows64 url=https://github.com/secondlife/3p-mikktspace/releases/download/v2-e967e1b/mikktspace-1-windows64-8756084692.tar.zst hash_algorithm=sha1 hash=130b33a70bdb3a8a188376c6a91840bdb61380a8
::autobuild installables edit minizip-ng platform=windows64 url=https://github.com/secondlife/3p-minizip-ng/releases/download/v4.0.7-r3/minizip_ng-4.0.7-r3-windows64-13246046977.tar.zst hash_algorithm=sha1 hash=58773e707ff3490822b7b8217d7729ade2186632

@REM autobuild installables add nghttp2 platform=windows64 url=https://github.com/secondlife/3p-nghttp2/releases/download/v1.64.0-r2/nghttp2-1.64.0-r1-windows64-13184359419.tar.zst hash_algorithm=sha1 hash=3bd92f892e155104740570fe244ea4dbb0b57d4b
@REM autobuild installables add nvapi platform=windows64 url=https://github.com/secondlife/3p-nvapi/releases/download/v560-r1/nvapi-560.0.0-r1-windows64-10390321492.tar.zst hash_algorithm=sha1 hash=bc574ea89164387a6c12bb49e1bac091c1d4da27
@REM autobuild installables add ogg_vorbis platform=windows64 url=https://github.com/secondlife/3p-ogg_vorbis/releases/download/v1.3.5-1.3.7-r2/ogg_vorbis-1.3.5-1.3.7.11968798109-windows64-11968798109.tar.zst hash_algorithm=sha1 hash=5f4cbb928ebfe774a9c07d3f2c255fd38bd6b4d6

@REM autobuild installables add openal platform=windows64 url=https://github.com/secondlife/3p-openal-soft/releases/download/v1.24.2-r1/openal-1.24.2-r1-windows64-13245988487.tar.zst hash_algorithm=sha1 hash=8ad24fba1191c9cb0d2ab36e64b04b4648a99f43
@REM autobuild installables add openjpeg platform=windows64 url=https://github.com/secondlife/3p-openjpeg/releases/download/v2.5.3-r1/openjpeg-2.5.3.15590356935-windows64-15590356935.tar.zst hash_algorithm=sha1 hash=8aab9cf250dfee252386e1c79b5205e6d3b3e19e
@REM autobuild installables add openssl platform=darwin64 url=https://github.com/secondlife/3p-openssl/releases/download/v1.1.1w-r3/openssl-1.1.1w-r3-darwin64-13246054022.tar.zst hash_algorithm=sha1 hash=157193699127ac5056c5fc1a410f9c98d39731e2

@REM autobuild installables add openxr platform=windows64 url=https://github.com/secondlife/3p-openxr/releases/download/v1.1.40-r1/openxr-1.1.40-r1-windows64-10710818432.tar.zst hash_algorithm=sha1 hash=3cccc3e3f3137066c286270b35abc00ee0c0bb0c
@REM autobuild installables add threejs platform=common url=https://github.com/secondlife/3p-three_js/releases/download/v0.132.2-5da28d9/threejs-0.132.2-common-8454371083.tar.zst hash_algorithm=sha1 hash=982c0fa427458082ea9e3cb9603904210732b64e
@REM autobuild installables add tinygltf platform=common url=https://github.com/secondlife/3p-tinygltf/releases/download/v2.9.3-r1/tinygltf-2.9.3-r1-common-10341018043.tar.zst hash_algorithm=sha1 hash=005d23bb2606ae2cc9e844adc1a0edf112c69812

@REM autobuild installables add tracy platform=windows64 url=https://github.com/secondlife/3p-tracy/releases/download/v0.11.1-r1/tracy-v0.11.1.11706699176-windows64-11706699176.tar.zst hash_algorithm=sha1 hash=b46cef5646a8d0471ab6256fe5119220fa238772
@REM autobuild installables add tut platform=common url=https://github.com/secondlife/3p-tut/releases/download/v2008.11.30-409bce5/tut-2008.11.30-common-409bce5.tar.zst hash_algorithm=sha1 hash=9f0bf4545f08df5381e0f39ccce3a57c6ec4b0f4
@REM autobuild installables add viewer-manager platform=windows64 url=https://github.com/secondlife/viewer-manager/releases/download/v3.0-2c4be99/viewer_manager-3.0-2c4be99-windows64-2c4be99.tar.zst hash_algorithm=sha1 hash=ac592053df08e8651797a492630ba5660910f793

@REM autobuild installables add vlc-bin platform=windows64 url=https://github.com/secondlife/3p-vlc-bin/releases/download/v3.0.21.296d9f4/vlc_bin-3.0.21.11968962952-windows64-11968962952.tar.zst hash_algorithm=sha1 hash=f986e6e93acf8a32a8be5b638f0bd0e2e07d7507
@REM autobuild installables add vulkan_gltf platform=common url=https://github.com/secondlife/3p-vulkan-gltf-pbr/releases/download/v1.0.0-d7c372f/vulkan_gltf-1.0.0-common-d7c372f.tar.zst hash_algorithm=sha1 hash=8e365eff8dcace48d91e2530f8b13e420849aefc

@REM autobuild installables add xxhash platform=common url=https://github.com/secondlife/3p-xxhash/releases/download/v0.8.2-r1/xxhash-0.8.2-10285735820-common-10285735820.tar.zst hash_algorithm=sha1 hash=fc9362865e33391d55c64d6101726da0a25d924e
::autobuild installables add zlib-ng platform=windows64 url=https://github.com/secondlife/3p-zlib-ng/releases/download/v2.2.3-r1/zlib_ng-2.2.3-dev0.g8aa13e3.d20250206-windows64-13183604450.tar.zst hash_algorithm=sha1 hash=e802a28139328bb2421ad39e13d996d350d8106d
@REM autobuild installables add tinyexr platform=common url=https://github.com/secondlife/3p-tinyexr/releases/download/v1.0.9-5e8947c/tinyexr-1.0.9-5e8947c-common-10475846787.tar.zst hash_algorithm=sha1 hash=a9649f85e20c0b83acfd7b02ca19c1dcdd15f01e


:: NEUE TEST PAKETE ENDE

echo .
echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
echo .
:: ##### 15. **Konfiguration des Builds**
:: #####     - Führt `autobuild configure` mit Flags für Channel, Paketierung, Audiooptionen aus

if not defined AUTOBUILD_BUILD_ID (
    for /f %%I in ('powershell -NoProfile -Command "[int][double]::Parse((Get-Date -UFormat %%s))"') do set "AUTOBUILD_BUILD_ID=%%I"
)

:: Konfiguration mit AVX2
echo %GREEN%Konfiguration mit AVX2 openal WebRTC...%RESET%
@REM echo  %YELLOW%Die  Warnung - Warning: no --id argument - ist überflüssig und verwirrend da das UTC Datum und Zeit eh gesetzt wird.%RESET%
@REM autobuild configure --config-file "%AUTO_BUILD_CONFIG%" -A 64 -c ReleaseFS_open -- --avx2 --openal --package --chan WebRTC -DLL_TESTS:BOOL=FALSE -DFMOD:BOOL=OFF -DUSE_OPENAL=ON
:: Ausgabe: PASSTHRU:  -DLL_TESTS:BOOL=FALSE -DFMOD:BOOL=OFF -DUSE_OPENAL=ON
autobuild configure --config-file "%AUTO_BUILD_CONFIG%" -A 64 -c ReleaseFS_open -- --avx2 --openal --package --chan WebRTC

if errorlevel 1 (
    echo %RED%[FEHLER] Konfiguration fehlgeschlagen!%RESET%
    pause
    exit /b 1
)


echo .
echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
echo .
:: ##### 16. Build
echo %GREEN%Build mit den gesetzten AVX2 openal WebRTC...%RESET%
:: Hier wird anscheinend OpenAL und weitere nicht implementiert obwohl sie in autobuild configure bereits implementiert wurden.
autobuild build --config-file "%AUTO_BUILD_CONFIG%" -A 64 -c ReleaseFS_open --no-configure --verbose

if errorlevel 1 (
    echo %RED%[FEHLER] Build fehlgeschlagen!%RESET%
    pause
    exit /b 1
)


echo .
echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
echo .
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
set "URL_FILE=%TARGET_DIR%\%SKRIPT_VERSION%_install_urls.txt"
set "VERSIONS_FILE=%TARGET_DIR%\%SKRIPT_VERSION%_versions.txt"
set "COPYRIGHTS_FILE=%TARGET_DIR%\%SKRIPT_VERSION%_copyrights.txt"

:: Optional: Setze Installationsverzeichnis falls bekannt
set "INSTALL_DIR=build"

:: Manifest exportieren
echo Exportiere Installationsmanifest...
autobuild install --installed-manifest "%MANIFEST_FILE%" --install-dir "%INSTALL_DIR%"

:: Liste installierter Pakete
echo Liste installierter Pakete...
autobuild install --list-installed > "%LIST_FILE%"

:: Install-URLs
@REM echo Install-URLs extrahieren...
@REM autobuild install --list-install-urls > "%URL_FILE%"

:: Versionsinformationen
echo Versionsinformationen erfassen...
autobuild install --versions > "%VERSIONS_FILE%"

:: Copyrights
@REM echo Copyrights erfassen...
@REM autobuild install --copyrights > "%COPYRIGHTS_FILE%"

echo.
echo ✅ Alle Informationen wurden in "%TARGET_DIR%" gespeichert.


echo .
echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
echo .
:: ##### 18. NSIS-Installer
:: #####     - Führt `makensis.exe` mit der `.nsi`-Installerskriptdatei aus
echo %GREEN%Erstelle mit NSIS-Installer...%RESET%
echo DLLs werden in die Package kopiert.

if exist "%BUILD_DIR%\phoenix-firestorm\build-vc170-64\newview\Release" (
    echo %GREEN%Kopiere DLLs in das Release-Verzeichnis...%RESET%
    xcopy /Y "%SCRIPT_DIR%fs_include\alut.dll" "%BUILD_DIR%\phoenix-firestorm\build-vc170-64\newview\Release\"
    xcopy /Y "%SCRIPT_DIR%fs_include\OpenAL32.dll" "%BUILD_DIR%\phoenix-firestorm\build-vc170-64\newview\Release\"
    autobuild package -A 64 --config-file "%AUTO_BUILD_CONFIG%"
) 

:: Starte kopieren mit 3_firestorm_Release.bat
call "%SCRIPT_DIR%3_firestorm_Release.bat"

echo .
echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
echo .
pause
exit /b 0

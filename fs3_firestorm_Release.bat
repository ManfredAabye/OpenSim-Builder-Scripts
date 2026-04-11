@echo off
:: Schaltet die Anzeige der Befehle im Konsolenfenster aus, damit die Ausgabe übersichtlich bleibt.

chcp 65001 >nul
:: Setzt die Codepage auf UTF-8, damit Sonderzeichen korrekt dargestellt werden.

setlocal enabledelayedexpansion
:: Aktiviert verzögerte Variablienerweiterung, nützlich für komplexere Batch-Operationen.

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

echo .
echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
echo .
:: ##### 19. **Zusammenfassung und Ergebnisanzeige**
:: #####     - Zeigt den Inhalt des Release-Verzeichnisses im Terminal und beendet das Skript

echo %GREEN%!FS3_TXT_PACKAGING_DONE!%RESET%
echo %BLUE%!FS3_TXT_RELEASE_CONTENT!%RESET%
dir /b "%SCRIPT_DIR%Firestorm_Build\phoenix-firestorm\build-vc170-64\newview\Release"

echo .
echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
echo .

:: Kopiere die Dateien die mit _Setup.exe ins Hauptverzeichnis/release
echo %GREEN%!FS3_TXT_COPY_RELEASE_START!%RESET%
set "SOURCE=%SCRIPT_DIR%Firestorm_Build\phoenix-firestorm\build-vc170-64\newview\Release\"
set "TARGET=%SCRIPT_DIR%release\"

if not exist "%TARGET%" mkdir "%TARGET%"

for %%f in ("%SOURCE%*_Setup.exe") do (
    if exist "%%f" (
        if not exist "%TARGET%%%~nxf" (
            copy "%%f" "%TARGET%"
            echo !FS3_TXT_COPIED!: %%~nxf
        ) else (
            echo !FS3_TXT_SKIPPED!: %%~nxf
        )
    )
)

echo %GREEN%!FS3_TXT_RELEASE_COPIED_TO! %SCRIPT_DIR%release%RESET%
@echo off
:: Schaltet die Anzeige der Befehle im Konsolenfenster aus, damit die Ausgabe übersichtlich bleibt.

chcp 65001 >nul
:: Setzt die Codepage auf UTF-8, damit Sonderzeichen korrekt dargestellt werden.

setlocal enabledelayedexpansion
:: Aktiviert verzögerte Variablienerweiterung, nützlich für komplexere Batch-Operationen.

echo .
echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
echo .
:: ##### 19. **Zusammenfassung und Ergebnisanzeige**
:: #####     - Zeigt den Inhalt des Release-Verzeichnisses im Terminal und beendet das Skript

echo %GREEN%✔ Paketierung abgeschlossen%RESET%
echo %BLUE%   Inhalt des Release-Verzeichnisses:%RESET%
dir /b "%SCRIPT_DIR%Firestorm_Build\phoenix-firestorm\build-vc170-64\newview\Release"

echo .
echo %CYAN%──────────────────────────────────────────────────────────────────────────────────%RESET%
echo .

:: Kopiere die Dateien die mit _Setup.exe ins Hauptverzeichnis/release
echo %GREEN%Kopiere die Release ins Hauptverzeichnis/release...%RESET%
set "SOURCE=%SCRIPT_DIR%Firestorm_Build\phoenix-firestorm\build-vc170-64\newview\Release\"
set "TARGET=%SCRIPT_DIR%release\"

if not exist "%TARGET%" mkdir "%TARGET%"

for %%f in ("%SOURCE%*_Setup.exe") do (
    if exist "%%f" (
        if not exist "%TARGET%%%~nxf" (
            copy "%%f" "%TARGET%"
            echo Kopiert: %%~nxf
        ) else (
            echo Übersprungen: %%~nxf
        )
    )
)

echo %GREEN%✔ Release Setup wurde kopiert nach: %SCRIPT_DIR%release%RESET%
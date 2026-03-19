@echo off

echo alten OpenSimulator Ordner loeschen...
rd /s /q opensim || echo Kein opensim Ordner gefunden, ueberspringen...

echo OpenSimulator holen...

git clone https://github.com/opensim/opensim.git

echo Verzeichnis wechseln...

cd opensim

echo Abhaengigkeiten holen...

git clone https://github.com/ManfredAabye/opensim-tsassets.git

git clone https://github.com/ManfredAabye/opensimcurrencyserver-dotnet.git

git clone https://github.com/ManfredAabye/opensim-webrtc-janus.git

git clone https://github.com/ManfredAabye/os-data-backup.git

git clone https://github.com/FirestormViewer/phoenix-firestorm.git

git clone https://github.com/ManfredAabye/fs-build-firestorm-viewer-german.git

git clone https://github.com/meetecho/janus-gateway.git

git clone https://github.com/ManfredAabye/janus-opensim-audiobridge.git

git clone https://github.com/opensim/libopenmetaverse.git

echo Alle Abhaengigkeiten wurden geholt.

echo kopieren von tsassets nach OpenSim...
xcopy "opensim-tsassets\bin\*" "bin\" /E /I /Y /H
xcopy "opensim-tsassets\OpenSim\*" "OpenSim\" /E /I /Y /H

echo Copying currency server modules into opensim...
xcopy "opensimcurrencyserver-dotnet\addon-modules\*" "addon-modules\" /E /I /Y /H
xcopy "opensimcurrencyserver-dotnet\bin\*" "bin\" /E /I /Y /H

echo kopieren von webrtc nach OpenSim...
xcopy "opensim-webrtc-janus\OpenSim\*" "OpenSim\" /E /I /Y /H

echo kopieren von os-data-backup nach OpenSim...
xcopy "os-data-backup\*" "addon-modules\os-data-backup\" /E /I /Y /H

echo Alle Abhaengigkeiten wurden kopiert.

echo WebRTC-3p-Firestorm Abhaengigkeiten holen...

md WebRTC-3p-Firestorm
cd WebRTC-3p-Firestorm

curl -L -o webrtc-m114.5735.08.72.10447328796-darwin64-10447328796.tar.zst https://github.com/secondlife/3p-webrtc-build/releases/download/m114.5735.08.72/webrtc-m114.5735.08.72.10447328796-darwin64-10447328796.tar.zst

curl -L -o webrtc-m114.5735.08.72.10447328796-linux64-10447328796.tar.zst https://github.com/secondlife/3p-webrtc-build/releases/download/m114.5735.08.72/webrtc-m114.5735.08.72.10447328796-linux64-10447328796.tar.zst

curl -L -o webrtc-m114.5735.08.72.10447328796-windows64-10447328796.tar.zst https://github.com/secondlife/3p-webrtc-build/releases/download/m114.5735.08.72/webrtc-m114.5735.08.72.10447328796-windows64-10447328796.tar.zst

git clone https://github.com/secondlife/3p-webrtc-build

cd ..

echo Alle WebRTC-3p-Firestorm Dateien wurden geholt.

echo Konfigurationen umbenennen...
for /R "bin" %%f in (*.ini.example) do ren "%%f" "%%~nf"

pause
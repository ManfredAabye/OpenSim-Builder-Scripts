@echo off

cd opensim || exit

echo Prebuild erstellen...

copy bin\System.Drawing.Common.dll.win bin\System.Drawing.Common.dll

dotnet bin\prebuild.dll /target vs2022 /targetframework net8_0 /excludedir = "obj | bin" /file prebuild.xml

if exist "bin\addin-db-002" (
	del /F/Q/S bin\addin-db-002 > NUL
	rmdir /Q/S bin\addin-db-002
	)
if exist "bin\addin-db-004" (
	del /F/Q/S bin\addin-db-004 > NUL
	rmdir /Q/S bin\addin-db-004
	)

echo kompilieren...

if exist "opensim_build.log" del opensim_build.log
dotnet build --configuration Release OpenSim.sln /flp:v=diag;logfile=opensim_build.log

pause
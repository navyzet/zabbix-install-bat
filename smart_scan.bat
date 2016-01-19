@echo off
SET result_string={"data":[
REM Find Disks
:FindDisks
FOR /F  %%a in ('smartctl.exe --scan') DO CALL :AddDisk %%~a

REM Out result
SET out_string=%result_string:~0,-1%]}
ECHO %out_string%
EXIT /b 0

:AddDisk
REM IF NOT %1=="" SET result_string=%result_string%{"{#DISKNAME}":"%1"},
IF NOT %1=="" (
	SET disk_name=%1
	FOR /F "tokens=3*" %%a IN ('smartctl.exe -i %1 ^| find "Device Model"') DO SET disk_model=%%a %%b
	FOR /F "tokens=3" %%a IN ('smartctl.exe -i %1 ^| find "Serial Number"') DO  SET disk_snum=%%a
)
IF NOT %1=="" (
	FOR /F "tokens=4" %%a IN ('smartctl.exe -i %disk_name% ^| find "SMART support is: Unavailable"') DO SET smart_status=unavailable
)
IF NOT %1=="" (
	FOR /F "tokens=4" %%a IN ('smartctl.exe -i %disk_name% ^| find "SMART support is: Enabled"') DO SET smart_status=enabled
)
IF NOT %1=="" (
	FOR /F "tokens=4" %%a IN ('smartctl.exe -i %disk_name% ^| find "SMART support is: Disabled"') DO SET smart_status=disabled
)
IF NOT %1=="" (
	SET result_string=%result_string%{"{#DISKNAME}":"%disk_name%","{#DISKMODEL}":"%disk_model%","{#DISKSNUM}":"%disk_snum%","{#SMARTSTATUS}":"%smart_status%"},
)
GOTO :eof
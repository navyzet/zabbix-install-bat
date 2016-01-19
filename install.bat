setlocal
@echo off
echo ########################################
echo Welcome to Zabbix Installation 
echo ########################################
REM Set english code page
CALL chcp 437 > NUL
date /t 
time /t
ECHO.
REM Init variables
REM ############ IP ZABBIX SERVER ########################
SET serverip=10.10.10.171
REM ###################################################### 
SET listenport=10050
SET srcbindir=%~dp0
SET config_name=zabbix_agentd.conf
SET log_name=zabbix_agentd.log
SET zabbix_agent=zabbix_agentd.exe
SET smartmon_exe=smartctl.exe
if %PROCESSOR_ARCHITECTURE%==x86 (
  SET zabbix_architecture=win32
) ELSE (
  SET zabbix_architecture=win64
)
SET def_install_dir=%PROGRAMFILES%\zabbix
SET def_config_dir=%def_install_dir%
SET Configfile=%def_config_dir%\%config_name%
SET logfile=%def_config_dir%\%log_name%
SET hostname=%computername%
REM Check Windows version.
ECHO Windows version:
CALL :CheckVerWin
IF NOT %VersionWin%==Unknown (ECHO %VersionWin% %PROCESSOR_ARCHITECTURE%) ELSE GOTO Err_win_ver
REM Chek status service
:CheckZabbixStatus
ECHO Check running status:
CALL :CheckService "Zabbix Agent"
IF /I %service_state%==running (
    ECHO Zabbix agent is running.
	ECHO.
	ECHO Sopping service
	ECHO.
	CALL sc stop "Zabbix Agent" > NUL
	REM Return check
	GOTO CheckZabbixStatus
)
IF /I %service_state%==stopped (
    ECHO Zabbix agent service is stopped.
	ECHO.
)
if /I %service_state%=="Not Install" (
	ECHO Zabbix agent service is not install.
	ECHO.
)
REM create folder for install
ECHO Create folder for install
IF NOT EXIST "%def_install_dir%" MKDIR "%def_install_dir%" > NUL
IF ERRORLEVEL 1 GOTO Err_install_dir
ECHO.
ECHO Delete old files
DEL /q "%def_install_dir%"
REM DEL /q "%addon_conf_folder%"

ECHO Creating ZABBIX Agent configuration file "%Configfile%"
REM =============================================================================
REM =================== START OF CONFIGURATION FILE =============================
REM =============================================================================
ECHO ############ GENERAL PARAMETERS ################# >> "%Configfile%"
ECHO ### Option: LogFile >> "%Configfile%"
ECHO #	Name of log file. >> "%Configfile%"
ECHO #	If not set, Windows Event Log is used. >> "%Configfile%"
ECHO # >> "%Configfile%"
ECHO # Mandatory: no >> "%Configfile%"
ECHO # Default: >> "%Configfile%"
ECHO # LogFile= >> "%Configfile%"
ECHO LogFile=%logfile% >> "%Configfile%"

ECHO ### Option: DebugLevel >> "%Configfile%"
ECHO #	Specifies debug level >> "%Configfile%"
ECHO #	0 - basic information about starting and stopping of Zabbix processes >> "%Configfile%"
ECHO #	1 - critical information >> "%Configfile%"
ECHO #	2 - error information >> "%Configfile%"
ECHO #	3 - warnings >> "%Configfile%"
ECHO #	4 - for debugging (produces lots of information) >> "%Configfile%"
ECHO # >> "%Configfile%"
ECHO # Mandatory: no >> "%Configfile%"
ECHO # Range: 0-4 >> "%Configfile%"
ECHO # Default: >> "%Configfile%"
ECHO # DebugLevel=3 >> "%Configfile%"

ECHO ### Option: Server >> "%Configfile%"
ECHO #	List of comma delimited IP addresses (or hostnames) of Zabbix servers. >> "%Configfile%"
ECHO #	Incoming connections will be accepted only from the hosts listed here. >> "%Configfile%"
ECHO #	If IPv6 support is enabled then '127.0.0.1', '::127.0.0.1', '::ffff:127.0.0.1' are treated equally. >> "%Configfile%"
ECHO # >> "%Configfile%"
ECHO # Mandatory: no >> "%Configfile%"
ECHO # Default: >> "%Configfile%"
ECHO # Server= >> "%Configfile%"
ECHO Server=%serverip% >> "%Configfile%"

ECHO ### Option: ListenPort >> "%Configfile%"
ECHO #	Agent will listen on this port for connections from the server. >> "%Configfile%"
ECHO # >> "%Configfile%"
ECHO # Mandatory: no >> "%Configfile%"
ECHO # Range: 1024-32767 >> "%Configfile%"
ECHO # Default: >> "%Configfile%"
ECHO # ListenPort=10050 >> "%Configfile%"
ECHO ListenPort=%listenport% >> "%Configfile%"
ECHO.
ECHO ### Option: Hostname >> "%Configfile%"
ECHO #	Unique, case sensitive hostname. >> "%Configfile%"
ECHO #	Required for active checks and must match hostname as configured on the server. >> "%Configfile%"
ECHO #	Value is acquired from HostnameItem if undefined. >> "%Configfile%"
ECHO # >> "%Configfile%"
ECHO # Mandatory: no >> "%Configfile%"
ECHO # Default: >> "%Configfile%"
ECHO # Hostname= >> "%Configfile%"
ECHO Hostname=%hostname% >> "%Configfile%"

ECHO ### Option: Include >> "%Configfile%"
ECHO #	You may include individual files in the configuration file. >> "%Configfile%"
ECHO # >> "%Configfile%"
ECHO # Mandatory: no >> "%Configfile%"
ECHO # Default: >> "%Configfile%"
ECHO # Include= >> "%Configfile%"
ECHO # Include=%def_config_dir%\zabbix_agentd.conf.d\*.conf >> "%Configfile%"

ECHO ### Option: UnsafeUserParameters >> "%Configfile%"
ECHO #	Allow all characters to be passed in arguments to user-defined parameters. >> "%Configfile%"
ECHO #	0 - do not allow >> "%Configfile%"
ECHO #	1 - allow >> "%Configfile%"
ECHO # >> "%Configfile%"
ECHO # Mandatory: no >> "%Configfile%"
ECHO # Range: 0-1 >> "%Configfile%"
ECHO # Default: >> "%Configfile%"
ECHO # UnsafeUserParameters=0 >> "%Configfile%"

ECHO ### Option: UserParameter >> "%Configfile%"
ECHO #	User-defined parameter to monitor. There can be several user-defined parameters. >> "%Configfile%"
ECHO #	Format: UserParameter=^<key^>,^<shell command^> >> "%Configfile%"
ECHO # >> "%Configfile%"
ECHO # Mandatory: no >> "%Configfile%"
ECHO # Default: >> "%Configfile%"
ECHO # UserParameter= >> "%Configfile%"
ECHO UserParameter=HDD_find,"%def_install_dir%\smart_scan.bat" >> "%Configfile%"
ECHO UserParameter=HDD[*],FOR /F "tokens=10" %%a IN ^('smartctl.exe -A "$1" ^^^| find "$2"'^) do @echo %%a >> "%Configfile%"
ECHO UserParameter=CPU_temp[*],FOR /F "tokens=8"  %%a IN ^('OpenHardwareMonitorReport.exe ^^^| findstr CPU.*lpc.*temperature'^) DO @ECHO %%a >> "%Configfile%"

ECHO ##### Active checks related >> "%Configfile%"
ECHO # >> "%Configfile%"
ECHO # >> "%Configfile%"

ECHO ### Option: ServerActive >> "%Configfile%"
ECHO #	List of comma delimited IP:port (or hostname:port) pairs of Zabbix servers for active checks. >> "%Configfile%"
ECHO #	If port is not specified, default port is used. >> "%Configfile%"
ECHO #	IPv6 addresses must be enclosed in square brackets if port for that host is specified. >> "%Configfile%"
ECHO #	If port is not specified, square brackets for IPv6 addresses are optional. >> "%Configfile%"
ECHO #	If this parameter is not specified, active checks are disabled. >> "%Configfile%"
ECHO #	Example: ServerActive=127.0.0.1:20051,zabbix.domain,[::1]:30051,::1,[12fc::1] >> "%Configfile%"
ECHO #  >> "%Configfile%"
ECHO # Mandatory: no  >> "%Configfile%"
ECHO # Default: >> "%Configfile%"
ECHO # ServerActive= >> "%Configfile%"
ECHO ServerActive=%serverip%  >> "%Configfile%"

ECHO # >> "%Configfile%"
ECHO # >> "%Configfile%"

REM =============================================================================
REM ==================== END OF CONFIGURATION FILE ==============================
REM =============================================================================

REM copy file zabbix agent
ECHO Installing ZABBIX Agent files...
COPY "%srcbindir%\%zabbix_architecture%\%zabbix_agent%" "%def_install_dir%\%zabbix_agent%"
IF ERRORLEVEL 1 GOTO Err_copy

REM check status service
IF /I %service_state%==stopped (
    ECHO Run zabbix service.
	CALL sc start "Zabbix Agent" > NUL
)	
if /I %service_state%=="Not Install" (
	ECHO Zabbix agent service run install process.
	CALL "%def_install_dir%\%zabbix_agent%" --config "%Configfile%" --install
	IF ERRORLEVEL 1 GOTO Err_install
	ECHO Run zabbix service.
    CALL sc start "Zabbix Agent" > NUL	
)

REM Open port 
IF %VersionWin%=="Windows XP" (
	ECHO Open port %listenport%
	CALL netsh  firewall add portopening TCP %listenport% "Zabbix agent %listenport% TCP"
	IF ERRORLEVEL 1 GOTO Err_open_port
	ECHO Open port %listenport% success!
) ELSE (
	REM CALL :CheckFirewalRuleState "Zabbix Agent TCP port %listenport%"
)
CALL :CheckFirewalRuleState "Zabbix Agent TCP port %listenport%"
IF NOT %VersionWin%=="Windows XP" (
	IF %wirewal_rule_state%==disable CALL netsh advfirewall firewall set rule name="Zabbix Agent TCP port %listenport%" new enable=Yes
	IF %wirewal_rule_state%==not_exist CALL netsh advfirewall firewall add rule name="Zabbix Agent TCP port %listenport%" dir=in action=allow protocol=TCP localport=%listenport%
)

REM Install smartmononitor
ECHO Install "SmartMonTools"
IF NOT EXIST "%WINDIR%\system32\%smartmon_exe%" COPY "%srcbindir%\%smartmon_exe%" "%WINDIR%\system32\%smartmon_exe%"
IF ERRORLEVEL 1 GOTO Err_copy_smart
IF NOT EXIST "%def_install_dir%\smart_scan.bat" COPY "%srcbindir%\smart_scan.bat" "%def_install_dir%\smart_scan.bat"
IF ERRORLEVEL 1 GOTO Err_copy_smart_scan
ECHO "Smartmononitor" installed sucsess!

REM Install "Open Hardware Monitor"
ECHO Install "Open Hardware Monitor"
IF NOT EXIST "%WINDIR%\system32\OpenHardwareMonitorReport.exe" COPY "%srcbindir%\OpenHardwareMonitorReport.exe" "%WINDIR%\system32\OpenHardwareMonitorReport.exe"
IF ERRORLEVEL 1 GOTO Err_copy_hv_mon_exe
IF NOT EXIST "%WINDIR%\system32\OpenHardwareMonitorLib.dll" COPY "%srcbindir%\OpenHardwareMonitorLib.dll" "%WINDIR%\system32\OpenHardwareMonitorLib.dll"
IF ERRORLEVEL 1 GOTO Err_copy_hv_mon_dll

ECHO ""Open Hardware Monitor"" installed sucsess!
ECHO.
ECHO #############################################################
ECHO                     Congratulations! 
ECHO   ZABBIX agent for Windows successfuly instaled on Your PC!
ECHO.
ECHO     Installation directory: %def_install_dir%
ECHO     Configureation file: %Configfile%
ECHO.
ECHO   ZABBIX agent have next configuration:
ECHO     Agent hostname for ZABBIX Server: %Hostname%
ECHO     ZABBIX Server IP: %serverip%
ECHO     ZABBIX Agent listen port: %listenport%
ECHO     Log file: %logfile%
ECHO.
ECHO   Now You can configure ZABBIX Server to monitore this PC.
ECHO.
ECHO            Thank You for using ZABBIX software.
ECHO                  http://www.zabbix.com
ECHO #############################################################
ECHO.

GOTO End
 

:Err_start
ECHO INSTALL ERROR: Can't start ZABBIX Agent service!
GOTO Syntax 

:Err_install
ECHO INSTALL ERROR: Can't install ZABBIX Agent as service!
GOTO Syntax 

:Err_copy
ECHO INSTALL ERROR: Can't copy file "%srcbindir%\%zabbix_agent%" in to "%def_install_dir%"!
GOTO Syntax 

:Err_copy_smart
ECHO INSTALL ERROR: Can't copy file "%srcbindir%\%smartmon_exe%" in to "%WINDIR%\system32\%smartmon_exe%"!
GOTO Syntax 

:Err_copy_smart_scan
ECHO INSTALL ERROR: Can't copy file "%srcbindir%\smart_scan.bat" in to "%def_install_dir%\smart_scan.bat"
GOTO Syntax

:Err_copy_hv_mon_exe
ECHO INSTALL ERROR: Can't copy file "%srcbindir%\OpenHardwareMonitorReport.exe" to in "%WINDIR%\system32\OpenHardwareMonitorReport.exe"
GOTO Syntax

:Err_copy_hv_mon_dll
ECHO INSTALL ERROR: Can't copy file "%srcbindir%\OpenHardwareMonitorReport.exe" to in "%WINDIR%\system32\OpenHardwareMonitorReport.exe"
GOTO Syntax

:Err_install_dir
ECHO INSTALL ERROR: Can't create installation directory "%def_install_dir%"!
GOTO Syntax 

:Err_config_dir
ECHO INSTALL ERROR: Can't create directory "%config_dir%" for configuretion file!
GOTO Syntax 

:Err_win_ver
ECHO Windows version unsupported.
GOTO Syntax 

:Err_open_port
ECHO Can't open port.
GOTO Syntax

:CheckService
SET service_state="Not Install"
for /F "tokens=1,4" %%a in ('sc query %1') do if /I %%a==state (SET service_state=%%b)
GOTO :eof

:CheckFirewalRuleState
SET wirewal_rule_state=not_exist
FOR /F "tokens=1*" %%a IN ('netsh advfirewall firewall show rule name^=%1 ^| findstr Enabled:' ) DO (
	IF %%b==Yes SET wirewal_rule_state=enable
	IF %%b==No SET wirewal_rule_state=disable
)
GOTO :eof

:CheckVerWin
SET VersionWin=Unknown
VER | FINDSTR /IL "5.1." > NUL
IF %ERRORLEVEL% EQU 0 SET VersionWin="Windows XP"
VER | FINDSTR /IL "5.2." > NUL
IF %ERRORLEVEL% EQU 0 SET VersionWin="Windows 2003"
VER | FINDSTR /IL "6.0." > NUL
IF %ERRORLEVEL% EQU 0 SET VersionWin="Windows Vista"
VER | FINDSTR /IL "6.1." > NUL
IF %ERRORLEVEL% EQU 0 SET VersionWin="Windows 7"
VER | FINDSTR /IL "6.2." > NUL
IF %ERRORLEVEL% EQU 0 SET VersionWin="Windows 8"
VER | FINDSTR /IL "6.3." > NUL
IF %ERRORLEVEL% EQU 0 SET VersionWin="Windows 8.1"
VER | FINDSTR /IL "10.0." > NUL
IF %ERRORLEVEL% EQU 0 SET VersionWin="Windows 10"
GOTO :eof

:Syntax
ECHO.
ECHO -------------------------------------------------------------  
ECHO Fallen installation.
ECHO -------------------------------------------------------------
GOTO End

:End
@echo on
endlocal
@pause
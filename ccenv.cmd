@echo off

rem Defaults
set "CCSDK_BOARD=sim"
set "CCSDK_DBG_PORT="
set "CCSDK_UART_PORT="

rem Override defaults using last used values
if exist "%LOCALAPPDATA%/ccenv.cmd" (
  "%LOCALAPPDATA%/ccenv.cmd"
)

set "CCSDK_HOME=%CD%"

echo Available boards:
dir /b "%CCSDK_HOME%\boards"

set /p CCSDK_BOARD="Board [%CCSDK_BOARD%]: "

echo Available ports:
chgport

set /p CCSDK_DBG_PORT="Debug Port (e.g. COMn) [%CCSDK_DBG_PORT%]: "
set /p CCSDK_UART_PORT="UART Port (e.g. COMn) [%CCSDK_UART_PORT%]: "

rem Save settings
echo "set CCSDK_BOARD=%CCSDK_BOARD%" >"%LOCALAPPDATA%/ccenv.cmd"
echo "set CCSDK_DBG_PORT=%CCSDK_DBG_PORT%" >>"%LOCALAPPDATA%/ccenv.cmd"
echo "set CCSDK_UART_PORT=%CCSDK_UART_PORT%" >>"%LOCALAPPDATA%/ccenv.cmd"

set PATH=%PATH%;%CCSDK_TOOLCHAIN_PATH%;%CCSDK_HOME%/tools/windows/srecord
cmd

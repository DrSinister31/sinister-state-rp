@echo off
REM ============================================================================
REM Sinister H-Town RP — SFTP Upload Script (Worker D QoL + MLO Deployment)
REM Requires: psftp.exe (PuTTY) in same folder or PATH
REM Download: https://the.earth.li/~sgtatham/putty/latest/w64/psftp.exe
REM ============================================================================
set HOST=nyc15.xgamingserver.com
set PORT=2022
set USER=nhxija4f.69162937
set PASS=Familia1!
set SRC_ROOT=%~dp0resources\[standalone]

echo Connecting to %HOST%:%PORT% ...
echo If this is your first connection, accept the host key by typing "y"
echo.

REM Upload npc_afk
echo put -r "%SRC_ROOT%\npc_afk" /resources/[standalone]/ > "%TEMP%\psftp_cmd.txt"
REM Upload ship_channel_storage
echo put -r "%SRC_ROOT%\ship_channel_storage" /resources/[standalone]/ >> "%TEMP%\psftp_cmd.txt"
REM Upload texas_brewstop
echo put -r "%SRC_ROOT%\texas_brewstop" /resources/[standalone]/ >> "%TEMP%\psftp_cmd.txt"
REM Upload _cfg
echo put -r "%SRC_ROOT%\_cfg" /resources/[standalone]/ >> "%TEMP%\psftp_cmd.txt"
echo bye >> "%TEMP%\psftp_cmd.txt"

psftp -P %PORT% -l %USER% -pw %PASS% -b "%TEMP%\psftp_cmd.txt" %HOST%
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo SFTP upload failed. Try manually with WinSCP or FileZilla:
    echo   Host: %HOST%  Port: %PORT%
    echo   User: %USER%  Pass: %PASS%
    echo   Upload contents of resources\[standalone]\ to /resources/[standalone]/
)
del "%TEMP%\psftp_cmd.txt" 2>nul
pause

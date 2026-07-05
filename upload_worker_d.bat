@echo off
REM ====================================================================
REM Sinister H-Town RP — Worker D SFTP Upload (7 resources + cfg)
REM Requirements: PuTTY psftp.exe in same folder or PATH
REM Download: https://the.earth.li/~sgtatham/putty/latest/w64/psftp.exe
REM ====================================================================
set HOST=nyc15.xgamingserver.com
set PORT=2022
set USER=nhxija4f.69162937
set PASS=Familia1!
set SRC_ROOT=%~dp0resources\[standalone]

echo ================================================================
echo  Sinister H-Town RP — Worker D Deployment Upload
echo  Target: %HOST%:%PORT%
echo  Resources: 7 + _cfg
echo ================================================================
echo.
echo NOTE: If prompted to accept host key, type "y" then press Enter.
echo.

REM Write psftp batch commands
(
echo mkdir "/resources"
echo mkdir "/resources/[standalone]"
echo put -r "%SRC_ROOT%\sinister_sit" "/resources/[standalone]/"
echo put -r "%SRC_ROOT%\sinister_chess" "/resources/[standalone]/"
echo put -r "%SRC_ROOT%\spoody_itemcreator" "/resources/[standalone]/"
echo put -r "%SRC_ROOT%\npc_afk" "/resources/[standalone]/"
echo put -r "%SRC_ROOT%\texas_brewstop" "/resources/[standalone]/"
echo put -r "%SRC_ROOT%\ship_channel_storage" "/resources/[standalone]/"
echo put -r "%SRC_ROOT%\htown_customs" "/resources/[standalone]/"
echo put -r "%SRC_ROOT%\_cfg" "/resources/[standalone]/"
echo bye
) > "%TEMP%\psftp_upload.txt"

REM Run psftp (interactive — accept host key manually)
psftp -P %PORT% -l %USER% -pw %PASS% -b "%TEMP%\psftp_upload.txt" %HOST%

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [FAIL] SFTP upload failed (error code %ERRORLEVEL%)
    echo.
    echo Manual upload via WinSCP or FileZilla:
    echo   Host: %HOST%  Port: %PORT%
    echo   User: %USER%  Pass: %PASS%
    echo   Upload ALL folders from resources\[standalone]\ to /resources/[standalone]/
    echo.
) else (
    echo.
    echo [OK] All 7 resources + cfg uploaded successfully.
)

del "%TEMP%\psftp_upload.txt" 2>nul
pause

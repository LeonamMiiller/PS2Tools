@echo off
SetLocal EnableDelayedExpansion

set hdl_dump=%~dp0hdl_dump\hdl_dump.exe
set log=%~dp0insertedGameList.txt
set ICONDB=%~dp0Files\icons.ini
set ICONFOLDER=%~dp0Files\ICNS\
set GAMENAMEDB=%~dp0Files\gamename.csv
set PS2_DEFAULT_GAMEICON=%~dp0Files\ICNS\PS2_GAME_DEFAULT.ico

call :split_file_and_path !hdl_dump! hdl_dump_path hdl_dump_exec
cd !hdl_dump_path!

if not exist system.cnf call :makesystemcnf
type nul > !log!

call :setPS2HDD

for /f "tokens=5 delims= " %%d in ('!hdl_dump! toc %PS2HDD% ^| findstr "PP."') do (
set GAMEHDLTOC=%%d
	
	for /f "tokens=2 delims=." %%e in ("%%d") do (
		set PS2CODE=%%e
		set PS2CODE=!PS2CODE:~0,4!_!PS2CODE:~5,3!.!PS2CODE:~8,2!
	)

	for /f "delims=; tokens=1,2" %%f in ('findstr !PS2CODE! !GAMENAMEDB!') do (
		set GAMENAME=%%g
		call :removetmpfiles

		for /f "delims== tokens=1,2" %%x in ('findstr !PS2CODE! !ICONDB!') do ( 
			set GAMEDBID=%%x
			set GAMEICON=%%y
		)
		
		if "!GAMEDBID!"=="!PS2CODE!" (
			copy /Y /V !ICONFOLDER!!GAMEICON! list.ico >nul				
		) else (
			copy /Y /V !PS2_DEFAULT_GAMEICON! list.ico >nul
		)

		
		call :makeiconsys "!GAMENAME!" "!PS2CODE!" 
		
		echo !date! !time:~0,-3! !PS2CODE! !GAMENAME!>> !log!
		echo Inserting: !PS2CODE! - !GAMENAME!
		
		!hdl_dump! modify_header %PS2HDD% !GAMEHDLTOC! > nul
		
		echo Done
		
	)		
	
)
call :removetmpfiles
pause
goto :EOF

:setPS2HDD
for /f "tokens=1 delims= " %%a in ('!hdl_dump! query ^| findstr "formatted Playstation"') do set PS2HDD=%%a
::trim tab and trim spaces
set PS2HDD=!PS2HDD: =!
if "%PS2HDD%"==" =" (
echo.
echo. 		Local Hard Drive not Found, Please insert your PS2 IP
echo.
	set /p "PS2HDD=Insert PS2 IP: "
)
goto :EOF

:removetmpfiles
del /q icon.sys list.ico 2>nul
goto :EOF

:split_file_and_path <file_path> <path> <file>
(
    set "%~2=%~dp1"
	set "%~3=%~nx1"
    exit /b
)

:makeiconsys 
(
echo PS2X
echo title0=%~1
echo title1=%~2
echo bgcola=0
echo bgcol0=0,0,0
echo bgcol1=0,0,0
echo bgcol2=0,0,0
echo bgcol3=0,0,0
echo lightdir0=1.0,-1.0,1.0
echo lightdir1=-1.0,1.0,-1.0
echo lightdir2=0.0,0.0,0.0
echo lightcolamb=64,64,64
echo lightcol0=64,64,64
echo lightcol1=16,16,16
echo lightcol2=0,0,0
echo uninstallmes0=Are you sure you want to delete %~1 ?
echo uninstallmes1=It was nice to play with you.
echo uninstallmes2=Goodbye...
) > icon.sys
goto :EOF

:makesystemcnf
(
echo BOOT2 = PATINFO
echo VER = 1.00
echo VMODE = NTSC
echo HDDUNITPOWER = NICHDD
) > system.cnf
goto :EOF
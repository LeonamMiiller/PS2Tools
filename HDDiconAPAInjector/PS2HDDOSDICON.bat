@echo off
SetLocal EnableDelayedExpansion
set hdl_dump=hdl_dump\hdl_dump.exe

if not exist hdl_dump\system.cnf call :makesystemcnf
echo. > insertedGameList.txt

for /f "tokens=1 delims= " %%a in ('!hdl_dump! query ^| findstr "formatted Playstation"') do set PS2HDD=%%a
set PS2HDD=%PS2HDD:	=%


for /f "tokens=5 delims= " %%d in ('!hdl_dump! toc %PS2HDD% ^| findstr "PP."') do (
set GAMEHDLTOC=%%d

	for /f "tokens=2 delims=." %%e in ("%%d") do (
		set PS2CODE=%%e

		for /f "delims== tokens=1,2" %%x in (Files\icons.ini) do (
			set GAMEDBID=%%x
			set GAMEDBID=!GAMEDBID:_=-!
			set GAMEDBID=!GAMEDBID:.=!

			if "!GAMEDBID!"=="!PS2CODE!" (
				set GAMEICON=%%y 
				set GAMENAME=!GAMEICON:_= !
				set GAMENAME=!GAMENAME:~0,-5!

				copy /Y /V Files\ICNS\!GAMEICON! hdl_dump\list.ico > nul
				call :makeiconsys "!GAMENAME!" "!GAMEDBID!" 
				
				echo !GAMENAME! !date! !time:~0,-3! >> insertedGameList.txt
				echo Inserting !GAMENAME!...
				!hdl_dump! modify_header %PS2HDD% "!GAMEHDLTOC!" > nul
				echo Done!
				
			)
		)	
	)
)
goto :EOF

:removetmpfiles
del /q hdl_dump\icon.sys hdl_dump\list.ico hdl_dump\system.cnf 

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
echo uninstallmes0=
echo uninstallmes1=
echo uninstallmes2=
) > hdl_dump\icon.sys

:makesystemcnf
(
echo BOOT2 = PATINFO
echo VER = 1.00
echo VMODE = NTSC
echo HDDUNITPOWER = NICHDD
) > hdl_dump\system.cnf

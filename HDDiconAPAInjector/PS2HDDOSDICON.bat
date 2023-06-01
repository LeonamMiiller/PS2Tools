@ECHO OFF
SETLOCAL EnableDelayedExpansion

SET hdl_dump_exec="%~dp0hdl_dump\hdl_dump.exe"
SET log="%~dp0insertedGameList.txt"
SET ICONDB="%~dp0Files\icons.ini"
SET ICONFOLDER="%~dp0Files\ICNS\"
SET GAMENAMEDB="%~dp0Files\gamename.csv"
SET PS2_DEFAULT_GAMEICON="%~dp0Files\ICNS\PS2_GAME_DEFAULT.ico"

CALL :SPLIT_FILE_AND_PATH !hdl_dump_exec! hdl_dump_path hdl_dump
CD !hdl_dump_path!

CALL :MAKESYSTEMCNF
TYPE nul > !log!

SET debug=false

IF "%debug%"=="true" (

	SET HDLTOC=type PS2HDDMOCK.PS2

) ELSE (

	CALL :SET_PS2_HDD
	SET HDLTOC=!hdl_dump! toc %PS2HDD%
)



IF	"%~1"=="list"				GOTO :LIST_HDL_TOC_GAMES

IF	"%~1"=="" 				GOTO :INSERT_ICONS
IF NOT	"%~1"==""	IF	"%~2"=="" 	GOTO :INSERT_SINGLE_GAME_ICON_BY_USER_INPUT
IF NOT	"%~1"==""	IF NOT	"%~2"=="" 	GOTO :INSERT_SINGLE_GAME_ICON_BY_USER_INPUT

GOTO :EOF

:INSERT_SINGLE_GAME_ICON_BY_USER_INPUT
CALL :SET_PS2CODE_FORMAT %~1 PS2CODE_TO_INJECT
ECHO.
CALL :FIND_HDL_TOC_GAMES %PS2CODE_TO_INJECT% GAME_FOUND
ECHO.

IF "%GAME_FOUND%"=="FOUND" (

	CALL :INSERT_ICONS %PS2CODE_TO_INJECT% "%~2"

) ELSE (

	CLS
	ECHO.
	ECHO.	GAME%PS2CODE_TO_INJECT% NOT FOUND, TRY AGAIN
	ECHO.
	ECHO.	How to
	ECHO.	PS2HDDOSDICON.bat XXXX-00000 "My Favorite Game"
	CALL :LIST_HDL_TOC_GAMES
)

GOTO :EOF


:INSERT_ICONS <PS2CODE_INPUT> <PS2GAME_NAME_INPUT>
SET PS2GAMECODE_BY_USER_INPUT=%~1
SET PS2GAMENAME_BY_USER_INPUT=%~2

FOR /f "tokens=5 delims= " %%X IN ('%HDLTOC% ^| findstr "PP.!PS2GAMECODE_BY_USER_INPUT!"') DO (
SET GAMEHDLTOC=%%X
SET GAMENAME=""

	CALL :SET_PS2CODE_FROM_GAMEHDLTOC !GAMEHDLTOC! PS2CODE

	IF "%PS2GAMENAME_BY_USER_INPUT%"=="" (

		CALL :FIND_INFO_FROM_DATABASE !GAMENAMEDB! !PS2CODE! DUMMY_PS2CODE GAMENAME		
		
	) ELSE (	
	
		SET GAMENAME=!PS2GAMENAME_BY_USER_INPUT!
		
	)
	
	
	IF NOT !GAMENAME!=="" (
	
		CALL :REMOVETMPFILES
		
		CALL :MAKEICONSYS "!GAMENAME!" "!PS2CODE!" 
		
		CALL :FIND_AND_SET_GAMEICON !PS2CODE!
		
		CALL :LOG "!PS2CODE!" "!GAMENAME!"
		
		CALL :INSERT_GAME_ICON !GAMEHDLTOC!
		
		ECHO Done		
	
	)
	
)
CALL :REMOVETMPFILES
ECHO.
ECHO.
pause
GOTO :EOF

::-----------------------------------------------------------------------------------------------------------------

:INSERT_GAME_ICON <GAMEHDLTOC>
IF "%debug%"=="true" (
ECHO	!hdl_dump! modify_header %PS2HDD% %~1
) ELSE (
		!hdl_dump! modify_header %PS2HDD% %~1 > nul
)
GOTO :EOF

::-----------------------------------------------------------------------------------------------------------------

:LIST_HDL_TOC_GAMES
ECHO.
ECHO.	LIST OF ALL GAMES IN HDD
ECHO.

	CALL :FIND_HDL_TOC_GAMES "" DUMMY

GOTO :EOF

::-----------------------------------------------------------------------------------------------------------------

:FIND_HDL_TOC_GAMES <PS2CODE_TO_INJECT> <GAME_FOUND>
FOR /f "tokens=5 delims= " %%X IN ('%HDLTOC% ^| findstr "PP.%~1"') DO (
	SET %~2=FOUND
	ECHO.	FOUND: %%X
)
exit /b

::-----------------------------------------------------------------------------------------------------------------


:SET_PS2CODE_FORMAT <PS2CODE_INPUT> <PS2CODE_TO_INJECT> <NUMBER_FORMAT>
FOR /F "tokens=1-20 delims=-._=[]{}/?,\|´`" %%a IN ("%1") DO SET CODE=%%a%%b%%c%%d%%f%%g%%h%%i%%j%%k%%l%%m%%n
FOR /F "tokens=2 delims=-" %%A IN ('FIND "" "%CODE:~0,4%" 2^>^&1') DO SET REGION=%%A

	IF "%~3"=="" (
		SET %~2=%REGION%-%CODE:~4,5%
	)
	
	IF "%~3"=="1" (
		SET %~2=%REGION%_%CODE:~4,3%.%CODE:~7,2%
	)
	
exit /b	
::-----------------------------------------------------------------------------------------------------------------

:SET_PS2CODE_FROM_GAMEHDLTOC <HDLGAMETOC> <PS2CODE> 
FOR /f "tokens=2 delims=." %%e IN ("%~1") DO SET CODE=%%e
	
	SET %~2=%CODE:~0,4%_%CODE:~5,3%.%CODE:~8,2%

exit /b

::-----------------------------------------------------------------------------------------------------------------

:FIND_AND_SET_GAMEICON <PS2CODE>
CALL :FIND_INFO_FROM_DATABASE !ICONDB! %~1 GAMEDBID GAMEICON
		
if "!GAMEDBID!"=="%~1" (
	copy /Y /V !ICONFOLDER!!GAMEICON! list.ico >nul				
) else (
	copy /Y /V !PS2_DEFAULT_GAMEICON! list.ico >nul
)

GOTO :EOF

::-----------------------------------------------------------------------------------------------------------------

:FIND_INFO_FROM_DATABASE <DATABASE> <VALUE_TO_FIND> <RETURN_1> <RETURN_2>
FOR /f "delims=;= tokens=1,2" %%x IN ('findstr %~2 %~1') DO ( 
	SET %~3=%%x
	SET %~4=%%y
)

exit /b


::-----------------------------------------------------------------------------------------------------------------

:LOG <PS2CODE> <GAMENAME>
	
	echo !date! !time:~0,-3! %~1 %~2>> !log!
	echo Inserting: %~1 %~2

GOTO :EOF

::-----------------------------------------------------------------------------------------------------------------

:SET_PS2_HDD
FOR /f "tokens=1 delims= " %%a IN ('!hdl_dump! query ^| findstr "formatted Playstation"') DO SET PS2HDD=%%a
::trim tab and trim spaces
SET PS2HDD=!PS2HDD: =!
IF "%PS2HDD%"==" =" (
echo.
echo. 		Local Hard Drive not Found, Please insert your PS2 IP
echo.
	SET /p "PS2HDD=Insert PS2 IP: "
)
GOTO :EOF

::-----------------------------------------------------------------------------------------------------------------

:REMOVETMPFILES
DEL /q icon.sys list.ico 2>nul
GOTO :EOF

::-----------------------------------------------------------------------------------------------------------------

:SPLIT_FILE_AND_PATH <FILE_PATH> <PATH> <FILE>
(
    SET "%~2=%~dp1"
    SET "%~3=%~nx1"
    exit /b
)

::-----------------------------------------------------------------------------------------------------------------

:MAKEICONSYS 
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
GOTO :EOF

::-----------------------------------------------------------------------------------------------------------------

:MAKESYSTEMCNF
(
echo BOOT2 = PATINFO
echo VER = 1.00
echo VMODE = NTSC
echo HDDUNITPOWER = NICHDD
) > system.cnf
GOTO :EOF

::-----------------------------------------------------------------------------------------------------------------

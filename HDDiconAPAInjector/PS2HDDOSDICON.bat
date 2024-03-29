@ECHO OFF
SETLOCAL EnableDelayedExpansion

SET hdl_dump="%~dp0hdl_dump\hdl_dump.exe"
SET log="%~dp0insertedGameList.txt"
SET ICONDB="%~dp0Files\icons.ini"
SET ICONFOLDER="%~dp0Files\ICNS\"
SET GAMENAMEDB="%~dp0Files\gamename.csv"
SET PS2_DEFAULT_GAMEICON="%~dp0Files\ICNS\PS2_GAME_DEFAULT.ico"

CALL :SPLIT_FILE_AND_PATH !hdl_dump! hdl_dump_path hdl_dump_exec

::-----------------------------------------------------------------------------------------------------------------

SET debug=false
IF "%debug%"=="true" (

	SET PS2HDD=fake_HDD1
	SET HDLTOC=type %~dp0hdl_dump\PS2HDDMOCK.PS2
	
) ELSE (

	CALL :SET_PS2_HDD
	SET "HDLTOC=!hdl_dump! toc %PS2HDD%"
)

::-----------------------------------------------------------------------------------------------------------------

IF	"%~1"==""			GOTO :INSERT_ICONS
IF	"%~1"=="list"			GOTO :LIST_HDL_TOC_GAMES
IF	"%~1"=="app"			IF NOT "%~2"==""		CALL :INSERT_SINGLE_APP_ICON_BY_USER_INPUT %~2 %~3 && GOTO :EOF
IF  NOT "%~1"==""			IF NOT "%~1"=="app"		GOTO :INSERT_SINGLE_GAME_ICON_BY_USER_INPUT

GOTO :EOF

::-----------------------------------------------------------------------------------------------------------------

:INSERT_SINGLE_APP_ICON_BY_USER_INPUT <APP_CODE> <APP_NAME>
CALL :FIND_HDL_TOC_GAMES %~1 PS2APP_FOUND

IF NOT "%PS2APP_FOUND%"=="" (	

	CALL :SET_PS2CODE_FROM_GAMEHDLTOC %PS2APP_FOUND% PS2APP

	SET APPFOLDER="%hdl_dump_path%APPS\!PS2APP!\"
	
	CALL :FIND_FILE !APPFOLDER! .KELF KELF_FILE

	IF "!KELF_FILE!"=="" (

		ECHO	Kelf file not found
		ECHO	Please put it into !APPFOLDER!
		ECHO	And try again
		ECHO	PS2HDDOSDICON.bat app !PS2APP! "!PS2APP! is My Favorite PS2 APP"
		GOTO :EOF

	)

	IF NOT "!KELF_FILE!"=="" IF "%~2"=="" (

		ECHO	App Name not SET
		ECHO	Please insert a name like this
		ECHO	PS2HDDOSDICON.bat app !PS2APP! "!PS2APP! is My Favorite PS2 APP"
		GOTO :EOF

	)
	
	CALL :INSERT_ICONS !PS2APP! %~2

) ELSE (

	CALL :LOG_CODE_NOT_FOUND %~1

)	
GOTO :EOF

::-----------------------------------------------------------------------------------------------------------------

:INSERT_SINGLE_GAME_ICON_BY_USER_INPUT

	CALL :FIND_HDL_TOC_GAMES %~1 GAME_FOUND 

	IF NOT "%GAME_FOUND%"=="" (

		CALL :INSERT_ICONS %~1 %~2

	) ELSE (

		CALL :LOG_CODE_NOT_FOUND %~1
	
	)

GOTO :EOF

::-----------------------------------------------------------------------------------------------------------------

:INSERT_ICONS <PS2CODE_INPUT> <PS2GAME_NAME_INPUT>
SET PS2GAMECODE_BY_USER_INPUT=%~1
SET PS2GAMENAME_BY_USER_INPUT=%~2

CD !hdl_dump_path!
TYPE nul > !log!

FOR /f "tokens=5 delims= " %%X IN ('%HDLTOC% ^| findstr /i "PP.!PS2GAMECODE_BY_USER_INPUT!"') DO (
SET GAMEHDLTOC=%%X
SET GAMENAME=""

	CALL :SET_PS2CODE_FROM_GAMEHDLTOC !GAMEHDLTOC! PS2CODE

	IF "!KELF_FILE!"=="" CALL :FORMAT_PS2CODE !PS2CODE! PS2CODE 1
	

	IF "%PS2GAMENAME_BY_USER_INPUT%"=="" (		

		CALL :FIND_INFO_FROM_DATABASE !GAMENAMEDB! !PS2CODE! DUMMY_PS2CODE GAMENAME		
		
	) ELSE (	
	
		SET GAMENAME=!PS2GAMENAME_BY_USER_INPUT!
		
	)
	

	IF NOT !GAMENAME!=="" (
	
		CALL :REMOVETMPFILES
		
		CALL :MAKESYSTEMCNF "!KELF_FILE!"
		
		CALL :MAKEICONSYS "!GAMENAME!" "!PS2CODE!" 
		
		CALL :FIND_AND_SET_GAMEICON !PS2CODE!
		
		CALL :LOG "!PS2CODE!" "!GAMENAME!"
		
		CALL :INSERT_GAME_ICON !GAMEHDLTOC!
		
		ECHO Done
		ECHO.
	
	)
	
)
CALL :REMOVETMPFILES
GOTO :EOF

::-----------------------------------------------------------------------------------------------------------------

:INSERT_GAME_ICON <GAMEHDLTOC>
IF "%debug%"=="true" (
ECHO	!hdl_dump_exec! modify_header %PS2HDD% %~1
) ELSE (
	!hdl_dump! modify_header %PS2HDD% %~1 > nul
)
GOTO :EOF

::-----------------------------------------------------------------------------------------------------------------

:LIST_HDL_TOC_GAMES	
ECHO	LIST OF ALL GAMES IN HDD

	CALL :FIND_HDL_TOC_GAMES "" DUMMY

GOTO :EOF

::-----------------------------------------------------------------------------------------------------------------

:FIND_HDL_TOC_GAMES <PS2CODE_TO_INJECT> <GAME_FOUND> <RETURN_CODE>
FOR /f "tokens=5 delims= " %%X IN ('%HDLTOC% ^| findstr /i "PP.%~1"') DO (
	SET "%~2=%%X"
	ECHO	FOUND: %%X
)
exit /b

::-----------------------------------------------------------------------------------------------------------------

:SET_PS2CODE_FORMAT <PS2CODE_INPUT> <PS2CODE_TO_INJECT> <NUMBER_FORMAT>
FOR /F "tokens=1-20 delims=-._=[]{}/?,\|´`" %%a IN ("%1") DO SET CODE=%%a%%b%%c%%d%%e%%f%%g%%h%%i%%j%%k%%l%%m%%n
FOR /F "tokens=2 delims=-" %%A IN ('FIND "" "%CODE:~0,4%" 2^>^&1') DO SET REGION=%%A
	CALL :FORMAT_PS2CODE %REGION%%CODE:~4,9% %~2 %~3

exit /b
	
::-----------------------------------------------------------------------------------------------------------------

:SET_PS2CODE_FROM_GAMEHDLTOC <HDLGAMETOC> <PS2CODE> <NUMBER_FORMAT>
FOR /F "tokens=2 delims=." %%e IN ("%~1") DO (

	IF "%~3"=="" (
		SET "%~2=%%e" 
	) ELSE (
		CALL :FORMAT_PS2CODE %%e %~2 %~3
	)

)

exit /b

::-----------------------------------------------------------------------------------------------------------------

:FORMAT_PS2CODE <INPUT_PS2CODE> <RETURN_PS2CODE> <NUMBER_FORMAT>
FOR /F "tokens=1-20 delims=-._=[]{}/?,\|´`" %%a IN ("%1") DO SET CODE=%%a%%b%%c%%d%%e%%f%%g%%h%%i%%j%%k%%l%%m%%n

	IF "%~3"=="" (
		SET "%~2=%CODE:~0,4%-%CODE:~4,5%"
	)
	
	IF "%~3"=="1" (
		SET "%~2=%CODE:~0,4%_%CODE:~4,3%.%CODE:~7,2%"
	)
	
	IF "%~3"=="2" (
		SET "%~2=%CODE%"
	)	

exit /b

::-----------------------------------------------------------------------------------------------------------------

:FIND_AND_SET_GAMEICON <PS2CODE>
SET GAMEICON=''
SET GAMEDBID=''

CALL :FIND_INFO_FROM_DATABASE !ICONDB! %~1 GAMEDBID GAMEICON	

IF EXIST !APPFOLDER! (
	
	CALL :FIND_FILE !APPFOLDER! .ICO GAMEICON
	
	IF NOT !GAMEICON!=='' (
		
		COPY /Y /V !APPFOLDER!!GAMEICON! list.ico >nul		

	) ELSE (

		ECHO Icon not found in !APPFOLDER! 
		ECHO Using PS2 DEFAULT GAMEICON !PS2_DEFAULT_GAMEICON!

		COPY /Y /V !PS2_DEFAULT_GAMEICON! list.ico >nul
	)

) ELSE (

	IF "!GAMEDBID!"=="%~1" (
		COPY /Y /V !ICONFOLDER!!GAMEICON! list.ico >nul				
	) ELSE (
		COPY /Y /V !PS2_DEFAULT_GAMEICON! list.ico >nul
	)
)
GOTO :EOF

::-----------------------------------------------------------------------------------------------------------------

:FIND_INFO_FROM_DATABASE <DATABASE> <VALUE_TO_FIND> <RETURN_1> <RETURN_2>
FOR /f "delims=;= tokens=1,2" %%x IN ('findstr %~2 %~1') DO ( 
	SET "%~3=%%x"
	SET "%~4=%%y"
)

exit /b

::-----------------------------------------------------------------------------------------------------------------

:FIND_FILE <INPUT_PATH> <FILE_TYPE> <RETURN_FILE>
FOR /f "tokens=*" %%a in ('dir /b /s /a-d "%~1\*%~2" 2^>nul') do SET "%~3=%%~nxa"

exit /b

::-----------------------------------------------------------------------------------------------------------------

:LOG <PS2CODE> <GAMENAME>
	
	echo !date! !time:~0,-3! %~1 %~2>> !log!

	echo Inserting...
	echo NAME: %~2
	echo CODE: %~1 	

GOTO :EOF

::-----------------------------------------------------------------------------------------------------------------

:LOG_CODE_NOT_FOUND <INPUT_PS2CODE>
	
	CLS
	ECHO	GAME %~1 NOT FOUND, TRY AGAIN
	ECHO	How to
	ECHO	PS2HDDOSDICON.bat XXXX-00000
	ECHO	Or
	ECHO	PS2HDDOSDICON.bat XXXX-00000 "My Favorite PS2 Game"
	CALL :LIST_HDL_TOC_GAMES

GOTO :EOF

::-----------------------------------------------------------------------------------------------------------------

:SET_PS2_HDD
FOR /f "tokens=1 delims= " %%a IN ('!hdl_dump_path!!hdl_dump_exec! query ^| findstr "formatted Playstation"') DO SET PS2HDD=%%a
::trim tab and trim spaces
SET PS2HDD=!PS2HDD: =!
IF "%PS2HDD%"==" =" (
ECHO 		Local Hard Drive not Found, Please insert your PS2 IP
	SET /p "PS2HDD=Insert PS2 IP: "
)
GOTO :EOF

::-----------------------------------------------------------------------------------------------------------------

:REMOVETMPFILES
DEL /q icon.sys list.ico system.cnf 2>nul
GOTO :EOF

::-----------------------------------------------------------------------------------------------------------------

:SPLIT_FILE_AND_PATH <PATH_FILE> <RETURN_PATH> <RETURN_FILE>
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

:MAKESYSTEMCNF <SYSBOOT>
IF "%~1"=="" ( 
	SET BOOT=PATINFO 
) ELSE (
	SET BOOT=pfs:/%~1
)
(
echo BOOT2 = %BOOT%
echo VER = 1.00
echo VMODE = NTSC
echo HDDUNITPOWER = NICHDD
) > system.cnf
GOTO :EOF

::-----------------------------------------------------------------------------------------------------------------

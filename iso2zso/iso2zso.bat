@echo off
SetLocal EnableDelayedExpansion
::https://github.com/unknownbrackets/maxcso

for /F "tokens=2 delims=-" %%A in ('FIND "" "%~x1" 2^>^&1') do set ext=%%~xA

if %ext%==.ISO (		
	maxcso --block=2048 --format=zso "%~1"
)

if %ext%==.ZSO (		
	maxcso --decompress "%~1"
)
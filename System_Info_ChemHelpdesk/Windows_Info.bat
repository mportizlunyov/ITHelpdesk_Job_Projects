@REM UW-Madison Department of Chemistry Helpdesk (C) 2024
@REM Written by Mikhail Ortiz-Lunyov (https://chemconnect.wisc.edu/staff/ortiz-lunyov-mikhail/)

:: Set echo to off
@ECHO off

:: Main Body
:: :: Set variables
:: :: :: Version
SET ShortVer="0.0.4"
SET LongVer="v%ShortVer% (June 17th 2024)"
:: :: Check for help options
IF "%~1" == "/v" (
  CALL:PrintVersion "%ShortVer%"
  EXIT /B 0
) ELSE IF "%~1" == "/h" (
  CALL:PrintHelp "%ShortVer%"
  EXIT /B 0
)
:: :: Print divisors
CALL:PrintDivisor "start"
:: :: Print system information
CALL:SysInfoRun
:: :: Completion message
ECHO ==DONE!==
ECHO == Don't forget ethernet Jack ID, Room number, and Owner! ==
CALL:PrintDivisor "end"
PAUSE
EXIT /B 0


:: Prints Divisors
:PrintDivisor
IF "%~1" == "start" (
  ECHO.
  ECHO.
  ECHO ##############################################################
  ECHO #                                                            #
  ECHO == System Information, by UW-Madison Chem. Dept. IT Helpdesk =
) ELSE IF "%~1" == "end" (
  ECHO #                                                            #
  ECHO ##############################################################
  ECHO.
)
EXIT /B 0

:: Prints System information
:SysInfoRun
hostname.exe
winver.exe # Opens GUI
ipconfig.exe /all
wmic.exe bios get serialnumber
EXIT /B 0

:: Prints Version statement
:PrintVersion
ECHO Windows Information extractor [Windows_Info.sh] %~1
ECHO UW-Madison Department of Chemistry IT Helpdesk (C) 2024
ECHO Written by Mikhail Ortiz-Lunyov (mportizlunyov)
ECHO.
EXIT /B 0

:: Prints Help statement
:PrintHelp
CALL:PrintVersion "%~1"
ECHO Arguments
ECHO.
ECHO /h : Prints this help message (overrides all other arguments)
ECHO /v : Prints the version number (overrides all non-informational arguments)
ECHO.
EXIT /B 0
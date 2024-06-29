@REM UW-Madison Department of Chemistry Helpdesk (C) 2024
@REM Written by: 
@REM     Mikhail Ortiz-Lunyov (https://chemconnect.wisc.edu/staff/ortiz-lunyov-mikhail/)

:: Turn ECHO off for less verbosity
@ECHO off

:: List volumes
ECHO list volume > ListVolScript.txt
DISKPART /S ListVolScript.txt

ECHO Approve? [y/else]
set /p ApproveVar=

IF "%ApproveVar%" == "y" (
	DISKPART /s D:\ToLocalBoot\diskpartScript.txt
	bcdboot E:\Windows /s C:\EFI /v
	ECHO "NEW volumes"
	DISKPART /S ListVolScript.txt
	ECHO "DONE. MAKE SURE TO CHECK BIOS"
) ELSE (
	ECHO "DOING IT MANUALLY"
)

:: Version 0.0.1.0-prealpha
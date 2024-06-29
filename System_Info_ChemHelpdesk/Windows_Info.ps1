# UW-Madison Department of Chemistry Helpdesk (C) 2024
# Written by Mikhail Ortiz-Lunyov (https://chemconnect.wisc.edu/staff/ortiz-lunyov-mikhail/)

# Execution of this script may require requesting script execution premissions
# Check them via: Get-ExecutionPolicy
# Set it via:             Set-ExecutionPolicy Bypass
# Close via:            Set-ExecutionPolicy *Whatever was before*

# Print the beginning and ending divisors for readability
function Divisor-Print {
    param (
        [String]$Position
    )

    switch ($Position) {
        "start" {
            Write-Host ""
            Write-Host ""
            Write-Host "##############################################################"
            Write-Host "#                                                            #"
            Write-Host "== System Information, by UW-Madison Chem. Dept. IT Helpdesk ="
        }
        "end" {
            Write-Host "#                                                            #"
            Write-Host "##############################################################"
            Write-Host ""
        }
    }
}

# Argument version method
function Version-Help {
    Write-Host "Windows Information extractor [Windows_Info.sh] $LongVersion"
    Write-Host "UW-Madison Department of Chemistry IT Helpdesk (C) 2024"
    Write-Host "Written by Mikhail Ortiz-Lunyov (mportizlunyov)"
    Write-Host ""
}

# Argument help method
function About-Help {
    Version-Help
    Write-Host "Arguments:"
    Write-Host ""
    Write-Host "-h | --help      : Prints this help message (overrides all other arguments)"
    Write-Host "-v | --version : Prints the version number (overrides all non-informational arguments)"
}


## Main
# Print script divisor
# Write-Host "##############################################################"
# Write-Host "#                                                            #"
Divisor-Print "start"

# Version number
$LongVersion = "v0.0.2 (June 3rd 2024)"
$ShortVersion = "0.0.2"

# Check arguments
switch ($args)  {
    # Help
    {@("/h","/help") -contains $_} {
        About-Help
        Divisor-Print "end"
        exit 2
    }
    # Version
    { @("/v","/version") -contains $_} {
        Version-Help
        Divisor-Print "end"
        exit 2
    }
}

# Begin giving system information
# Assume that these are running on Windows NT
# Some of these commands might not work on other OSs
hostname.exe
winver.exe # Opens GUI
ipconfig.exe /all
wmic.exe bios get serialnumber

# Completion message
Write-Host "== Done! =="
Write-Host "== Don't forget ethernet jack ID, room number, and owner! =="
# Write-Host "#                                                            #"
# Write-Host "##############################################################"
Divisor-Print "end"

exit 0

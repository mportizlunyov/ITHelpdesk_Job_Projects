# UW-Madison Department of Chemistry Helpdesk (C) 2024
# Written by: 
#     Mikhail Ortiz-Lunyov (https://chemconnect.wisc.edu/staff/ortiz-lunyov-mikhail/)

# Get parameters
param (
  [Alias("h","help")]
  [Switch]$HelpWanted,

  [Alias("v","version")]
  [Switch]$VersionWanted,

  [Alias("l")]
  [Parameter(Mandatory)]
  [String]$Login,

  [Alias("p","usb","portable","portable-usb")]
  [String]$PortablePath = "N/A", # Default

  [Alias("cp","copy-path")]
  [String]$CopyPath = "DEFAULT_CopyPath",     # [Redacted] <====

  [Alias("cs","custom-server")]
  [String]$Fileserver = "DEFAULT_Fileserver", # [Redacted] <====

  [Alias("li","lab","lab-instrument")]
  [Switch]$IsLab,

  [Alias("do","download-only")]
  [Switch]$DownloadOnly,

  [Alias("smo","security-management-only")]
  [Switch]$SecManOnly,

  [Alias("qo","qualys","qualys-only")]
  [Switch]$QualysOnly,

  [Alias("bo","bigfix","bigfix-only")]
  [Switch]$BigFixOnly,

  [Alias("po","productivity-only")]
  [Switch]$ProdOnly,

  [Alias("fi","full-install")]
  [Switch]$FullInstall
)

# Usage disclaimer
Write-Host "This script is best run in a terminal as Administrator"
Write-Host "Some applications, such as Qualys, do not install without admin"

# Version method
function Version-Print () {
  Write-Host "Windows Endpoint Installer [EndpointInstallation-Windows.ps1] $LongVersion"
  Write-Host "UW-Madison Department of Chemistry IT Helpdesk (C) 2024"
  Write-Host "Written by Mikhail Ortiz-Lunyov (mportizlunyov)"
  Write-Host ""
}

# Help method
function Help-Print () {
  Version-Print
  Write-Host "Arguments"
  Write-Host ""
  Write-Host "-h    | -help      : Prints this help message (overrides all other arguments)"
  Write-Host "-v    | -version   : Prints the version number (overrides all non-informational arguments)"
  Write-Host "-l *  | -login *   : Pre-loads username for login (without it, manual entering will be needed)"
  Write-Host "-cs * | -custom-server * : Pre-loads a custom SERVER to extract files (default [chemfiles.chem.wisc.edu])"
  Write-Host "-cp * | -custom-path *   : Pre-loads a cusom PATH to extract files (default [/srv/CCC/Installers/Windows])"
  Write-Host "-sv * | -specific-version * : Pre-loads specific version of package BigFix Package to install"
  Write-Host "-do   | -download-only : Downloads the directory with the installation files without running them (overrides [-li])"
  Write-Host "-li   | -lab | -lab-instrument : Installs a Lab-Instrument specific version of BigFix (Standard client by default)" 
  Write-Host "-smo  | -security-management-only : Only installs Security/management related tools"
  Write-Host "-po   | -productivity-only : Only installs productuvity software, such as the Microsoft(r) Office Suite"
  Write-Host "-fi   | -full-install : Installs everything that can be installed, including both Sec/Man and Prod tools"
  Write-Host "-p *  | -usb * | -portable * | -portable-usb * : Installs software using local repositories instead (use relative PATH)"
  Write-Host "-qo   | -qualys | -qualys-only : Only installs Qualys Cloud Agent"
  Write-Host "-bo   | -bigfix | -bigfix-only : Only Installs BigFix"
  Write-Host ""
  Write-Host "Exit codes:"
  Write-Host "0 : Successfull operation"
  Write-Host "1 : Error, by user"
  Write-Host "2 : Informational argument [-h] or [-v]"
  Write-Host "3 : Error, by program"
  Write-Host ""
}

# Print break message
function Cant-Continue () {
  Write-Host "Unable to continue, QUITting..."
}

# Prints error messages based on type
function Error-All ($ArgType, $SpecificError, $Detail1, $Detail2, $Detail3) {
  # Argument-related errors
  switch ($ArgType) {
    "argument" {
      switch ($SpecificError) {
        "TooMany" {
          Write-Host "Too many arguments detected [$Detail1]"
          Write-Host "This can indicate duplicates or spam arguments"
          Cant-Continue
          exit 1
        }
        "DoesNotExist" {
          Write-Host "Invalid argument [$Detail1], see HELP here:"
          Write-Host ""
          Help-Print
          exit 1
        }
        "MissingLogin" {
          Write-Host "-l or --login requires another argument [username]"
          Cant-Continue
          exit 1
        }
        "MissingPath" {
          Write-Host "-sv or --specific-version requires another argument [VERSION Number]"
          Cant-Continue
          exit 1
        }
        "IncompatibleArgs" {
          Write-Host "Incompatible arguments detected"
          Write-Host "Bad argument # = $Detail1"
          Write-Host "Security-only: $SecManOnly"
          Write-Host "Product-only: $ProdOnly"
          Write-Host "Full-Install : $FullInstall"
          Write-Host "If two or more of these are true, then use different arguments!"
          Cant-Continue
          exit 1
        }
        "BadPATH" {
          Write-Host "Bad local PATH set"
          Write-Host "PATH [./$PortablePath] does NOT exist"
          Cant-Continue
          exit 1
        }
        Default {
          Write-Host "Internal Error: Line 52"
          Write-Host "Error type[$Detail1]"
          exit 1
        }
      }
    }
    "tool" {
      switch ($SpecificError) {
        "DoesNotExist"{
          switch ($Detail1) {
            # "-scp" { Write-Host "SCP is MISSING, but was forced." }
            Default { Write-Host "Dependencies do not exist [$Detail1]" }
          }
          Cant-Continue
          exit 1
        }
        "ToolBroke" {
          Write-Host "$Detail1 BROKE!"
          Write-Host "CHECK its error message"
          Write-Host "Exit code $Detail2"
          Write-Host "Check information below"
          Write-Host "     username  : $User"
          Write-Host "     fileserver: $Fileserver"
          Write-Host "     PATH      : $PresentWorkingDirectory"
        }
        "Incompatible" {
          Write-Host "OS architecture is incompatible with applications to install"
          wmic os get osarchitucture
          Write-Host "Needs: 64-bit or arm64"
          Cant-Continue
          exit 1
        }
        "VersionNotFound" {
          Write-Host "Specific version  of requested software not found."
          Write-Host "Version requested: $Detail1"
          Write-Host "Actual version available: $Detail2"
          Write-Host "Files are saved in $Detail3."
          Write-Host "You will need to manually select and install them"
          Cant-Continue
          exit 1
        }
        "Cancelled" {
          Write-Host "Canceled by USER $User"
          switch ($Detail1) {
            "Connection" {
              Write-Host "$Detail1"
              switch ($Detail2) {
                "true" { Write-Host "No files downloaded, local directory intact" }
                "false" { Write-Host "Some files downloaded, check ./Windows directory" ; Get-ChildItem }
              }
            } 
            "Installation" { Write-Host "$Detail1 : Installation inturrupted" }
          }
          exit 1
        }
        Default {
          Write-Host "Internal Error: Line 148"
          Write-Host "Error type [$SpecificError]"
          exit 1
        }
      }
    }
    Default {
      Write-Host "INTERNAL ERROR: Line 154"
      Write-Host "ERROR TYPE [$ArgType] NOT DEFINED"
      Write-Host "QUITTING"
      exit 1
    }
  }
}

# Check dependencies
function Dependency-Check () {
  # Get parameters
  param (
    $CmdToTest
  )

  [void](Get-Command $CmdToTest -ErrorAction SilentlyContinue)
  switch ($?) {
    $False {
      Write-Host "$CmdToTest not found"
      $ToolExists = $False
    }
    $True {
      Write-Host "$CmdToTest found"
      $ToolExists = $True
    }
  }
}

# Command to use SCP
function SCP-Use () {
  scp -rp "$Login@${Fileserver}:$CopyPath" ./
  switch ($?) { # This does not yet seem to work...
    $True { Write-Host "FILES SUCCESSFULLY DOWNLOADED" }
    $False {
      switch (Get-ChildItem .) {
        $InitialLs { Error-All "tool" "Cancelled" "Connection" "true" }
        Default { Error-All "tool" "Cancelled" "Connection" "false" }
      }
    }
  }
}

# Install Qualys Cloud Agent
function Install-Qualys () {
  Write-Host "Installer [Qualys] running..."
  # Install Qualys Cloud Agent
  ## Extract MSI file (assume 64-bit)
  Start-Process .\$InstallPATH\QualysCloudAgent.exe -ArgumentList ExtractMSI=64 -Wait
  ## Install with parameters based off of install instructions
  $QualysInstallInstructions = Get-Content .\$InstallPATH\'Qualys Install Command.txt'
  ## Split output to String array, based off of " "
  $QualysInstallerExecute = $QualysInstallInstructions -split " "
  ## Set $InstallerExecute correctly
  $InstallerExecute = $QualysInstallerExecute[0]
  $InstallerExecute = ".\$InstallPATH\$InstallerExecute"
  ## Filter out valid arguments for Start-Process, remove
  $QualysInstallerExecuteArguments = @($QualysInstallerExecute[1], $QualysInstallerExecute[2], $QualysInstallerExecute[3])
  # Execute installer with arguments
  Start-Process $InstallerExecute -ArgumentList $QualysInstallerExecuteArguments  -Wait
  Write-Host "Qualys Installer completed"
}

# Install BigFix, depending on the version rquested
function Install-BigFix () {
  Write-Host "Installer #0 [BigFix] running..."
  switch ($IsLab) {
    $True {
      Write-Host "Installing to LAB INSTRUMENT (option -l / --lab)"
      # $InstallerExecute = ".\Windows\ChemInstrument-BigFixAgent.msi"
      $InstallerExecute = ".\$InstallPATH\ChemInstrument-BigFixAgent.msi"
      Start-Process $InstallerExecute -Wait
    }
    $False {
      Write-Host "Installing to STANDARD client"
      # $InstallerExecute = ".\Windows\Chemistry-BigFixAgent.msi"
      $InstallerExecute =  ".\$InstallPATH\Chemistry-BigFixAgent.msi"
      Start-Process $InstallerExecute -Wait
    }
  }
  Write-Host "BigFix Installer completed"
}

# Installs Security and Endpoint Management software
function Install-Security-Management () {
  # Security & Endpoint Management
  ## Set variables
  $InstallerExecute
  $LoopVar = 0

  for ($LoopVar = 1 ; $LoopVar -le 2 ; $LoopVar++) {
    switch ($LoopVar) {
      ## Install GlobalProtect VPN
      1 { $InstallerExecute = ".\$InstallPATH\GlobalProtect64.msi" }
      ## Install Cisco Secure Endpoint
      2 { $InstallerExecute = ".\$InstallPATH\amp_A4815-Chemistry-Client-Protect.exe" }
    }

    # try/catch running applications
    Write-Host "Installer #$LoopVar running..."
    try {
      Start-Process $InstallerExecute -Wait
      # Will run if completed without critical errors
      Write-Host "Installer #$LoopVar completed"
    }
    catch {
      Write-Host "Installer #$LoopVar terminated with ERROR"
      Write-Host "Execute cmd: $InstallerExecute"
    }
  }
}

# Installs productuvity and office tools
function Install-Productivity () {
  # Productivity
  ## Set variables
  $InstallerExecute
  $LoopVar = 0
  ## Iterate, each time changing the target installer
  for ($LoopVar = 4 ; $LoopVar -le 8 ; $LoopVar++) {
    switch ($LoopVar) {
      ## Install Microsoft Teams
      4 { $InstallerExecute = ".\$InstallPATH\TeamsSetup_c_w_.exe" }
      ## Install Microsoft Office
      5 { $InstallerExecute = ".\$InstallPATH\OfficeSetup.exe" }
      ## Install Zoom
      6 { $InstallerExecute = ".\$InstallPATH\ZoomInstallerFull.msi" }
      {7 -or 8} {
        Set-Location .\$InstallPATH
        # Check the architecture of the current device, then install
        switch ($Architecture) {
          "AMD64" {
            switch ($LoopVar) {
              7 {
                Expand-Archive Chemistry-SelfServe-AdobeCC-Win64_en_US_WIN_64.zip
                Set-Location ./..
                $InstallerExecute = ".\$InstallPATH\Chemistry-SelfServe-AdobeCC-Win64_en_US_WIN_64\Chemistry-SelfServe-AdobeCC-Win64\Build\Chemistry-SelfServe-AdobeCC-Win64.msi"
              }
              8 { $InstallerExecute = ".\$InstallPATH\Chemistry-SelfServe-AdobeCC-Win64_en_US_WIN_64\Chemistry-SelfServe-AdobeCC-Win64\Build\setup.exe" }
            }
          }
          "ARM64" {
            switch ($LoopVar) {
              7 {
                Expand-Archive Chemistry-SelfServe-AdobeCC-WinArm_en_US_WINARM_64.zip.zip
                Set-Location ./..
                $InstallerExecute = ".\$InstallPATH\Chemistry-SelfServe-AdobeCC-WinArm_en_US_WINARM_64\Chemistry-SelfServe-AdobeCC-WinArm\Build\Chemistry-SelfServe-AdobeCC-WinArm.msi"
              }
              8 { $InstallerExecute = ".\$InstallPATH\Chemistry-SelfServe-AdobeCC-WinArm_en_US_WINARM_64\Chemistry-SelfServe-AdobeCC-WinArm\Build\setup.exe" }
            }
          }
          Default { Error-All "tool" "Incompatible" }
        }
      }
    }

    # try/catch running applications
    Write-Host "Installer #$LoopVar running..."
    try {
      # Written in this form for easier development/updating in the future
      switch ($LoopVar) {
        Default { Start-Process $InstallerExecute -Wait }
      }

      # Will run if completed without critical errors
      Write-Host "Installer #$LoopVar completed"
    }
    catch {
      Write-Host "Installer #$LoopVar terminated with ERROR"
      Write-Host "Execute cmd: $InstallerExecute"
    }
  }
}

# Checks that incompatible arguments are not set
function Filer-Bad-Args () {
  # Initialise variable for 1st section
  $BadArgCounter = 0
  # Check if script parameters are true or not
  switch ($SecManOnly) { $True { $BadArgCounter++ } }
  switch ($ProdOnly) { $True { $BadArgCounter++ } }
  switch ($FullInstall) { $True { $BadArgCounter++ } }
  # Take resulting action based on score
  switch ($BadArgCounter) {
    2 { continue }
    3 { Error-All "argument" "IncompatibleArgs" $BadArgCounter }
  }

  # 2nd section
  $BadArgCounter = 0
  switch ($BigFixOnly) {$True { $BadArgCounter++ } }
  switch ($QualysOnly) {$True { $BadArgCounter++ } }
  switch ($BadArgCounter) { 2 { Error-All "argument" "IncompatibleArgs" $BadArgCounter }}
}


# Main
## Versions
$DevCycle = "-release-PUBLIC"
$ShortVersion = "v0.1.2"
$LongVersion = "$ShortVersion$DevCycle (June 28th 2024)"
# Begin initial actions
switch ($HelpWanted) {
  $True { Help-Print ; exit 2 }
}
switch ($VersionWanted) {
  $True { Version-Print ; exit 2 }
}
# Filter incompatible arguments | 
Filer-Bad-Args
## Initial variables and their defaults
$User = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$PresentWorkingDirectory = Get-Location
# Define other variables
## Tool-related
$ToolExists = $True
$InitialLs = Get-ChildItem .\
$Architecture = $env:PROCESSOR_ARCHITECTURE # Not ideal, but works for now
$InstallPATH = "Windows" # Default install path, changes with -p/-usb/-portable-portable-usb
# Check if Local install will be used, or if network download will be done
switch ($PortablePath) {
  "N/A" {

    # THIS SECTION IS SPECIALLY-MADE FOR THE PUBLIC EDITION.
    # IF THE DEFAULTS ARE USED, A TURORIAL METHOD WILL EXECUTE AND QUIT THE SCRIPT
    if ($CopyPath -eq "DEFAULT_CopyPath" -or $Fileserver -eq "DEFAULT_Fileserver") {
      Write-Host "A Critical default value has not been set by the user."
      Write-Host "COPYPATH  = $CopyPath"
      Write-Host "FILESERVER = $Fileserver"
      Write-Host "This is the public [Redacted] version, with sensitive names and directories redacted."
      Write-Host "  https://git.doit.wisc.edu/ortizlunyov/endpointinstallation_chemhelpdesk_internal ."
      Write-Host "Otherwise, access Help via the -h or--help file argument."
      exit 2
    }
    #
    # END OF SECTION

    # Portable option not used, therefore standard download and install
    ## Check is SCP tool exists, then use it
    Dependency-Check "scp"
    switch ($ToolExists) {
      $False { Error-All "tool" "DoesNotExist" "-scp" }
    }
    SCP-Use
  }
  Default {
    # Portable path does exist, check if PATH exists
    switch (Test-Path .\$PortablePath) {
      $True {
        # PATH exists, setting variables as needed
        $InstallPATH = ".\$PortablePath"
      }
      $False { Error-All "argument" "BadPATH" }
    }
  }
}
# Install software, if permitted
switch ($DownloadOnly) {
  $False {
    # Check if install only Qualys Cloud Agent
    switch ($QualysOnly) { $True { Install-Qualys } }
    # Check if install only BigFix
    switch ($BigFixOnly) { $True { Install-BigFix } }

    # Otherwise, install basic packages
    if (!$QualysOnly -and !$BigFixOnly) {
      Install-BigFix
      Install-Qualys
    }
    
    # Define what other software to install
    switch ($FullInstall) {
      $True {
        Install-Security-Management
        Install-Productivity
      }
      $False {
        switch ($SecManOnly) {
          $True { Install-Security-Management }
        }
        switch ($ProdOnly) {
          $True { Install-Productivity }
        }
        # If neither are $True, continue without installing
      }
    }
  }
  $True {
    Write-Host "Download-Only option detected"
    Write-Host "All installation files located under ./Windows directory"
  }
}

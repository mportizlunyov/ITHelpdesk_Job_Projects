# System Information, by UW-Madison Chemistry Dept. IT Helpdesk

This repository contains a series of scripts written by the UW-Madison Department of Chemistry IT Helpdesk to more easily retreive relevent system information.
https://chemconnect.wisc.edu/comphelp/get-help/

v0.0.3

This information includes:
 - Network Hostname
 - Network interface information (for internal IP address and MAC address)
 - Serial number
 - OS version and release name/brand

 Run UNIX_Info.sh for Linux and MacOS (any other varient is not supported, at least as of this first release)

 Run Windows_Info.ps1 for Windows (check system execution policy and set it as needed)

 Ask the supervisor on where to find relevent software in the shared volumes, or download from this repository.
 
 UNIX_Info.sh can be run without installation by using: `curl https://git.doit.wisc.edu/ortizlunyov/System_Info_ChemHelpDesk/-/raw/main/UNIX_Info.sh | $SHELL` in the terminal.
# UW-Madison Department of Chemistry Helpdesk (C) 2024
# Written by Mikhail Ortiz-Lunyov (https://chemconnect.wisc.edu/staff/ortiz-lunyov-mikhail/)

# Print the beginning and ending divisors for readability
DivisorPrint () {
    case "$1" in
        "start")
            echo ""
            echo ""
            echo "##############################################################"
            echo "#                                                            #"
            echo "== System Information, by UW-Madison Chem. Dept. IT Helpdesk ="
            ;;
        "end")
            echo "#                                                            #"
            echo "##############################################################"
            echo ""
            ;;
    esac
}

# Argument version method
VersionHelp () {
    echo "UNIX Information extractor [UNIX_Info.sh] $LONG_VERSION"
    echo "UW-Madison Department of Chemistry IT Helpdesk (C) 2024"
    echo "Written by Mikhail Ortiz-Lunyov (mportizlunyov)"
    echo ""
}

# Argument help method
PrintHelp () {
    VersionHelp
    echo "Arguments:"
    echo ""
    echo "-h | --help          : Prints this help message (overrides all other arguments)"
    echo "-v | --version     : Prints the version number (overrides all non-informational arguments)"
    echo "-ipa | --ip-a-full : Prints the full result of [ip a] (only if [ip] command exists, overrides all other ip-related arguments)"
    echo "-ip-6                  : Prints IPv6 addresses in shortened version (only if [ip] command exists)"
}

# Argument ip-related method
ipARGs () {
    echo " == Network Info =="
    case "$1" in
        *"-ipa")
            echo " == Running full [ip a] command =="
            ip a
            echo " =="
            ;;
        *"-ip-6")
            echo " == Giving IPv6 addresses as well"
            echo " * Network instructions:"
            echo " * Identify network device within the 'inet' section,"
            echo " * then count the devices in the 'link' section."
            ip a | grep "inet "
            ip a | grep "link/"
            echo " =="
            ;;
        *)
            # Ignoring non-ip related arguments
            echo " * Network instructions:"
            echo " * Identify network device within the 'inet' section,"
            echo " * then count the devices in the 'link' section."
            ip a | grep "inet "
            ip a | grep "link/"
            echo " =="
            ;;
    esac
}


## Main
# Print script divisor
DivisorPrint "start"

# Version number
LONG_VERSION="v0.0.3 (June 3rd 2024)"
SHORT_VERSION="0.0.3"

# Check arguments
case "$@" in
    *"-h"|*"--help")
        PrintHelp
        DivisorPrint "end"
        exit 2
        ;;
    *"-v"|*"--version")
        VersionHelp
        DivisorPrint "end"
        exit 2
        ;;
esac

# Get type of UNIX
UNAME_RESULT=$(uname)
ip_EXISTS=false

# Begin giving system information
echo "Network Hostname: $(hostname)"
# Define specific actions based on $UNAME_RESULT
case $UNAME_RESULT in
    # Linux
    "Linux")
        echo " === Getting info ==="
        echo "UNIX type: $UNAME_RESULT"
        echo "Kernel   : $(uname -r)"
        if [ -f /etc/os-release ] ; then
            cat /etc/os-release | grep PRETTY_NAME
            cat /etc/os-release | grep VERSION_ID
        else
            echo "[/etc/os-release] file NOT found"
        fi
        # Check network information
        ip > /dev/null 2>&1
        case "$?" in
            127)
                echo "[ip a] not found, continueing..."
                ;;
            *)
                ip_EXISTS=true
                ipARGs $@
                ;;
        esac
        sudo dmidecode -s system-serial-number
        ;;
    # MacOS
    "Darwin")
        # Get Serial number: system_profiler SPHardwareDataType
        echo " === Getting info ==="
        echo "UNIX type: MacOS"
        echo "Kernel   : $(uname -r)"
        #uname -a
        sw_vers
        system_profiler SPHardwareDataType
        ;;
    *)
        printf "Unknown UNIX, refer to documentation"
        ;;
esac
# Run legacy ipconfig application if running on MacOS,
#  or running on linux that does not support 'ip'.
case $ip_EXISTS in
    false)
    ifconfig
    # If somehow ifconfig does not work, run error message
    case $? in
        127)
            echo "! Neither IP nor IFCONFIG found!"
            echo "! Check GUI"
            DivisorPrint "end"
            exit 1
            ;;
    esac
    ;;
esac

# Completion message
echo "== Done! =="
echo "== Don't forget ethernet jack ID, room number, and owner! =="
DivisorPrint "end"

exit 0
#! /bin/bash
# UW-Madison Department of Chemistry Helpdesk (C) 2024
# Written by: 
#   Mikhail Ortiz-Lunyov (https://chemconnect.wisc.edu/staff/ortiz-lunyov-mikhail/)

# Version method
VersionPrint () {
  echo "Linux Endpoint Installer [$0] $LONG_VERSION"
  echo "UW-Madison Department of Chemistry IT Helpdesk (C) 2024"
  echo "Written by Mikhail Ortiz-Lunyov (mportizlunyov)"
  echo ""
}

# Help method
HelpPrint () {
  VersionPrint
  echo "About:"
  echo "This is a public, [REDACTED] edition of the original INTERNAL Linux Endpoint Installer tool."
  echo "This version has different defaults than the original, in order to not expose any"
  echo "  sensitive fileserver or PATH names to the public."
  echo "If you want to fork or otherwise use this project for your own needs, search for any in-line comments"
  echo "  labelled as [REDACTED], and change the defaults as needed."
  echo "Most likely, you will also need to change the Installation methods based on your Linux distribution."
  echo ""
  echo "Arguments:"
  echo ""
  echo "-h    | --help      : Prints this help message (overrides all other arguments)"
  echo "-v    | --version   : Prints the version number (overrides all non-informational arguments)"
  echo "-scp  | --force-scp : Forces the use of SCP over SFTP"
  echo "-l *  | --login *   : Pre-loads username for login (without it, manual entering will be needed)"
  echo "-cs * | --custom-server * : Pre-loads a custom FILESERVER to extract files (default [DEFAULT_FILESERVER])"
  echo "-cp * | --custom-path *   : Pre-loads a cusom PATH to extract files (default [DEFAULT_COPYPATH])"
  echo "-sv * | --specific-version * : Pre-loads specific version of package Qualys Package to install"
  echo "     Only available on Debian/Ubuntu."
  echo "-po * | --usb * | --portable * | --portable-usb * : Installs software using LOCAL repositories (use RELATIVE PATH)"
  echo ""
  echo "Exit codes:"
  echo "0 : Successfull operation"
  echo "1 : Error, by user"
  echo "2 : Informational argument [-h] or [-v]"
  echo "3 : Error, by program"
  echo ""
}

# Print break message
CantContinue () {
  echo "Unable to continue, QUITting..."
}

# Prints error messages based on type
ErrorAll () {
  # Argument-related errors
  case "$1" in
    "argument")
      case "$2" in
        "TooMany")
          echo "Too many arguments detected [$3]"
          echo "This can indicate duplicates or spam arguments"
          CantContinue
          exit 1
          ;;
        "DoesNotExist")
          echo "Invalid argument [$3], see HELP here:"
          echo ""
          HelpPrint
          exit 1
          ;;
        "MissingLogin")
          echo "-l/--login requires another argument [username]"
          CantContinue
          exit 1
          ;;
        "MissingPath")
          echo "-cp/--custom-path requires another argument [PATH]"
          CantContinue
          exit 1
          ;;
        "MissingFileserver")
          echo "-cs/--custom-server requires another argument [FILESERVER]"
          CantContinue
          exit 1
          ;;
        "MissingVersion")
          echo "-sv/--specific-version requires another argument [VERSION Number]"
          CantContinue
          exit 1
          ;;
        "LocalRepo")
          case "$3" in
            "NoArg")
              echo "-po/--usb/--portable/--portable-usb requires another argument [RELATIVE PATH]"
              ;;
            "NoExist")
              echo "PATH [./$4] does NOT EXIST"
              echo "Please enter an existing one next time!"
              ;;
          esac
          CantContinue
          exit 1
          ;;
        *)
          echo "Internal Error: Line 52"
          echo "Error type [$1]"
          exit 1
          ;;
      esac
      ;;
    # Tool-related errors
    "tool")
      case "$2" in
        "DoesNotExist")
          case "$3" in
          "-scp")
            echo "SCP is MISSING, but was forced."
            CantContinue
            exit 1
            ;;
          "PackageManagers")
            echo "Neither RPM nor DEB found, needed to install packages"
            CantContinue
            exit 1
            ;;
          *)
            echo "Dependencies do not exist"
            CantContinue
            exit 1
            ;;
          esac
          ;;
        "ToolBroke")
          echo "$3" BROKE!
          echo "CHECK its error message"
          echo "Exit code $4"
          echo "Check information below"
          echo "   username: $USER_LOGIN"
          echo "   fileserver:  $FILESERVER"
          echo "   PATH    : $COPY_PATH"
          CantContinue
          exit 1
          ;;
        "Incompatible")
          echo "OS architecture is incompatible with applications to install"
          echo "Current architecture: $(uname -m)"
          echo "Needs: x86_64/amd64 or aarch64/arm64"
          CantContinue
          exit 1
          ;;
        "VersionNotFound")
          echo "Specific version  of requested software not found."
          echo "Version requested: $3"
          echo "Actual versions available: $4"
          echo "Files are saved in $5."
          echo "You will need to manually select and install them"
          CantContinue
          exit 1
          ;;
        "Cancelled")
          echo "Canceled by USER $USER"
          case "$3" in
            "Connection")
              printf "$3: "
              case "$4" in
                "true")
                  echo "No files downloaded, local directory intact"
                  ;;
                "false")
                  echo "Some files downloaded, check ./Linux directory"
                  ls -l
                  ;;
              esac
              ;;
            "Installation")
              echo "$3: Installation inturrupted"
              ;;
          esac
          exit 1
          ;;
        *)
          echo "Internal Error: Line 102"
          echo "Error type [$1]"
          exit 1
          ;;
      esac
      ;;
    *)
      echo "INTERNAL ERROR: Line 109"
      echo "ERROR TYPE [$1] NOT DEFINED"
      echo "QUITTING"
      exit 1
      ;;
  esac
}

# Check dependencies
DependencyCheck () {
  $1 > /dev/null 2>&1
  case "$?" in
    "127") echo "$1 not found" ; TOOL_EXISTS=false ;;
    *) echo "$1 found" ; TOOL_EXISTS=true ;;
  esac
}

# Defines the tools to be used, depending on arguments.
ToolDefine () { 
  # "$1" = FORCE_SSH
  case "$1" in
    # If -scp / --force-scp is true
    "true")
      DependencyCheck scp
      case "$TOOL_EXISTS" in
        "false")
          ErrorAll "tool" "DoesNotExist" "-scp"
          ;;
        "true")
          echo "SCP FOUND, continueing..."
          SPECIFIC_COMMAND="scp"
          ;;
      esac
      ;;

    # If -scp / --force-scp is false
    "false"|*)
      DependencyCheck sftp
      case "$TOOL_EXISTS" in
        "false")
          echo "SFTP missing, checking SCP..."

          # Check SCP
          DependencyCheck scp
          case "$TOOL_EXISTS" in
            "false")
              echo "SCP missing"
              CantContinue
              exit 1
              ;;
            "true")
              echo "SCP FOUND, continuing..."
              SPECIFIC_COMMAND="scp"
              ;;
          esac
          ;;
        "true")
          echo "SFTP FOUND, continuing"
          SPECIFIC_COMMAND="sftp"
          ;;
      esac
      ;;
  esac
  # Reset TOOL_EXISTS variable for next section
  TOOL_EXISTS=false

  # Check package installers
  DependencyCheck "rpm --version"
  case "$TOOL_EXISTS" in
    "true") USE_PKG="rpm" ; return ;;
  esac
  DependencyCheck "dpkg --version"
  case "$TOOL_EXISTS" in
    "true") USE_PKG="dpkg" ; return ;;
  esac
  # Check if neither exist
  case "$USE_PKG" in
    "N/A") ErrorAll "tool" "DoesNotExist" "PackageManagers" ;;
  esac
}

# Command to run to use SFTP
SFTP_Use () {
  # echo "put $localpath/* $remotepath" | sftp username@fileserver
  echo "get -r $COPY_PATH" | sftp -r $USER_LOGIN@$FILESERVER
  case "$?" in
    "0") echo "FILES SUCCESSFULLY EXTRACTED, INSTALLING" ;;
    "1")
      # Check if the local directory is intact
      case "$(ls .)" in
        "$INITIAL_LS") ErrorAll "tool" "Cancelled" "Connection" "true" ;;
        *) ErrorAll "tool" "Cancelled" "Connection" "false" ;;
      esac
      ;;
    "255")
      echo "ACCESS FAILED!"
      ErrorAll "tool" "ToolBroke" $SPECIFIC_COMMAND "255"
      ;;
    *)
      echo "OTHER ERROR"
      ErrorAll "tool" "ToolBroke" $SPECIFIC_COMMAND *
      ;;
  esac
}

# Command to use SCP
SCP_Use () {
  scp -rp $USER_LOGIN@$FILESERVER:$COPY_PATH ./
  case "$?" in
    "0") echo "FILES SUCCESSFULLY EXTRACTED, INSTALLING" ;;
    "1")
      # Check if the local directory is intact
      case "$(ls .)" in
        "$INITIAL_LS") ErrorAll "tool" "Cancelled" "Connection" "true" ;;
        *) ErrorAll "tool" "Cancelled" "Connection" "false" ;;
      esac
      ;;
    "255")
      echo "ACCESS FAILED!"
      ErrorAll "tool" "ToolBroke" $SPECIFIC_COMMAND "255"
      ;;
    *)
      echo "OTHER ERROR"
      ErrorAll "tool" "ToolBroke" $SPECIFIC_COMMAND *
      ;;
  esac
}

# Method to run RPM package
RPM_Install () {
  sudo rpm -i ./$INSTALL_PATH/RHEL/QualysCloudAgent*
  bash ./$INSTALL_PATH/RHEL/config-command.sh
}

# Method to run DEB package
DEB_Install () {
  # Define process for installing Qualys Cloud Agent
  case $(uname -m) in
    "x86_64"|"amd64")
      echo "AMD64 found"
      echo "INSTALL_VERSION = $INSTALL_VERSION"
      # Decide which package to install
      case "$INSTALL_VERSION" in
        "latest"|"Latest")
          # ls Linux/Debian-Ubuntu/ | grep "QualysCloudAgent" | tail -2 | head -1
          sudo dpkg -i "./$INSTALL_PATH/Debian-Ubuntu/$(ls ./Linux/Debian-Ubuntu/ | grep "QualysCloudAgent" | tail -2 | head -1)"
          ;;
        *)
          if [ -f "./$INSTALL_PATH/Debian-Ubuntu/QualysCloudAgent-$INSTALL_VERSION.deb" ] ; then
            sudo dpkg -i "./$INSTALL_PATH/Debian-Ubuntu/QualysCloudAgent-$INSTALL_VERSION.deb"
          else
            ErrorAll "tool" "VersionNotFound" $INSTALL_VERSION "$(ls ./$INSTALL_PATH/Debian-Ubuntu/ | grep "QualysCloudAgent")" "$(cd ./Linux/Debian-Ubuntu && pwd)"
          fi
          ;;
      esac
      ;;
    "aarch64"|"arm64")
      echo "ARM64 found"
      sudo dpkg -i QualysCloudAgent-arm64.deb
      ;;
    *)
      # 32-bit OS not compatible with our packages
      ErrorAll "tool" "Incompatible"
      ;;
  esac
  ## Run config script for Qualys Cloud Agent
  bash ./Linux/Debian-Ubuntu/config-command.sh
  # Install Cisco Secure endpoint
  sudo dpkg -i ./Linux/Debian-Ubuntu/amp_A4815-Chemistry-Server-Linux-Protect_ubuntu-20-04-amd64.deb
}

# Assists with script arguments
OptionsLeft () { # LOGIN_FLAG CUSTOM_PATH_OPTION CUSTOM_FILESERVER_OPTION INSTALL_VERISON_OPTION INSTALL_FROM_LOCAL_BOOLEAN
  # See LOGIN_FLAG argument
  case "$1" in
    "true")
      ARGS_AVAILABLE=true
      return
      ;;
  esac
  # See CUSTOM_PATH_OPTION arguments
  case "$2" in
    "true")
      ARGS_AVAILABLE=true
      return
      ;;
  esac
  # See CUSTOM_FILESERVER_OPTION argument
  case "$3" in
    "true")
      ARGS_AVAILABLE=true
      return
      ;;
  esac
  # See INSTALL_VERISON_OPTION argument
  case "$4" in
    "true")
      ARGS_AVAILABLE=true
      return
      ;;
  esac
  # See INSTALL_FROM_LOCAL_BOOLEAN argument
  case "$5" in
    "true")
      ARGS_AVAILABLE=true
      return
      ;;
  esac
  # By this point all arguments are false
  ARGS_AVAILABLE=false
}


# Main
## Versions
DEV_CYCLE="-release-PUBLIC"
SHORT_VERSION="0.0.2"
LONG_VERSION="v$SHORT_VERSION$DEV_CYCLE (June 20th 2024)"
# Find arguments
## Overriding arguments
case "$@" in
  *"-h"|"*--help")
    HelpPrint
    exit 2
    ;;
  *"-v"|"*--version")
    VersionPrint
    exit 2
    ;;
esac
## Initial variables and their defaults
### Related to parameters with arguments
ARGS_AVAILABLE=true
### Related to -scp/--force-scp
FORCE_SSH=false
### Related to -l/--login
LOGIN_FLAG=false
USER_LOGIN=""
### Related to -cp/--copy-path
CUSTOM_PATH_OPTION=false
COPY_PATH="DEFAULT_COPYPATH"    # [REDACTED] <====
### Related to -cs/--custom-server
CUSTOM_FILESERVER_OPTION=false
FILESERVER="DEFAULT_FILESERVER" # [REDACTED] <====
### Related to -sv/--specific-version
INSTALL_VERSION="latest" # Default
INSTALL_VERISON_OPTION=false
### Related to -po/--usb/--portable/--portable-usb
INSTALL_FROM_LOCAL_PATH="N/A" # Default
INSTALL_FROM_LOCAL_BOOLEAN=false
INSTALL_PATH="./Linux"
## Other arguments
### Check for too many arguments
if [ $# -gt 10 ] ; then
  ErrorAll "argument" "TooMany" "$#"
fi
## Otherwise, filter as needed
for PARAM_COUNT in $(seq 0 $#) ; do
  case "$1" in
    "-scp"|"--force-scp") FORCE_SSH=true ;;
    "-l"|"--login") LOGIN_FLAG=true ;;
    "-cs"|"--custom-server") CUSTOM_FILESERVER_OPTION=true ;;
    "-cp"|"--copy-path") CUSTOM_PATH_OPTION=true ;;
    "-sv"|"--specific-version") INSTALL_VERISON_OPTION=true ;;
    "-po"|"-usb"|"--portable"|"--portable-usb") INSTALL_FROM_LOCAL_BOOLEAN=true ;;
    *)
      # If a username is needed
      case "$LOGIN_FLAG" in
        "true")
          case "$1" in
            ""|'') ErrorAll "argument" "MissingLogin" ;;
            *)
              USER_LOGIN=$1
              LOGIN_FLAG=false
              shift 1
              continue
              ;;
          esac
          ;;
        "false")
          case "$1" in
            ""|'') ;;
            *)
              OptionsLeft $LOGIN_FLAG $CUSTOM_PATH_OPTION $CUSTOM_FILESERVER_OPTION $INSTALL_VERISON_OPTION $INSTALL_FROM_LOCAL_BOOLEAN
              case "$ARGS_AVAILABLE" in
                "true")
                  # Continue as normal
                  ;;
                "false")
                  ErrorAll "argument" "DoesNotExist" "$1"
                  ;;
              esac
              ;;
          esac
          ;;
      esac

      # If a custom fileserver is used
      case "$CUSTOM_FILESERVER_OPTION" in
        "true")
          case "$1" in
            ""|'') ErrorAll "argument" "MissingPath" ;;
            *)
              FILESERVER=$1
              CUSTOM_FILESERVER_OPTION=false
              shift 1
              continue
              ;;
          esac
          ;;
        "false")
          case "$1" in
            ""|'') ;;
            *)
              OptionsLeft $LOGIN_FLAG $CUSTOM_PATH_OPTION $CUSTOM_FILESERVER_OPTION $INSTALL_VERISON_OPTION $INSTALL_FROM_LOCAL_BOOLEAN
              case "$ARGS_AVAILABLE" in
                "true") ;;
                "false") ErrorAll "argument" "DoesNotExist" "$1" ;;
              esac
              ;;
          esac
          ;;
      esac

      # If a custom path is used
      case "$CUSTOM_PATH_OPTION" in
        "true")
          case "$1" in
            ""|'') ErrorAll "argument" "MissingPath" ;;
            *)
              COPY_PATH=$1
              CUSTOM_PATH_OPTION=false
              shift 1
              continue
              ;;
          esac
          ;;
        "false")
          case "$1" in
            ""|'') ;;
            *)
              OptionsLeft $LOGIN_FLAG $CUSTOM_PATH_OPTION $CUSTOM_FILESERVER_OPTION $INSTALL_VERISON_OPTION $INSTALL_FROM_LOCAL_BOOLEAN
              case "$ARGS_AVAILABLE" in
                "true") ;;
                "false") ErrorAll "argument" "DoesNotExist" "$1" ;;
              esac
              ;;
          esac
          ;;
      esac

      # If a specific version to install is used
      case "$INSTALL_VERISON_OPTION" in
        "true")
          case "$1" in
            ""|'') ErrorAll "argument" "MissingPath" ;;
            *)
              INSTALL_VERSION=$1
              INSTALL_VERISON_OPTION=false
              shift 1
              continue
              ;;
          esac
          ;;
        "false")
          case "$1" in
            ""|'') ;;
            *)
              OptionsLeft $LOGIN_FLAG $CUSTOM_PATH_OPTION $CUSTOM_FILESERVER_OPTION $INSTALL_VERISON_OPTION $INSTALL_FROM_LOCAL_BOOLEAN
              case "$ARGS_AVAILABLE" in
                "true") ;;
                "false") ErrorAll "argument" "DoesNotExist" "$1" ;;
              esac
              ;;
          esac
          ;;

      esac

      # If a custom fileserver is used
      case "$INSTALL_FROM_LOCAL_BOOLEAN" in
        "true")
          case "$1" in
            ""|'') ErrorAll "argument" "MissingPath" ;;
            *)
              INSTALL_FROM_LOCAL_PATH=$1
              INSTALL_FROM_LOCAL_BOOLEAN=false
              shift 1
              continue
              ;;
          esac
          ;;
        "false")
          case "$1" in
            ""|'') ;;
            *)
              OptionsLeft $LOGIN_FLAG $CUSTOM_PATH_OPTION $CUSTOM_FILESERVER_OPTION $INSTALL_VERISON_OPTION $INSTALL_FROM_LOCAL_BOOLEAN
              case "$ARGS_AVAILABLE" in
                "true") ;;
                "false") ErrorAll "argument" "DoesNotExist" "$1" ;;
              esac
              ;;
          esac
          ;;
      esac

      ;;
  esac
  # Shift script arguments
  shift 1
done
# Define other variables
## Tool-related
SPECIFIC_COMMAND="N/A"
TOOL_EXISTS=true
TOOL_SUCCESS=true
INITIAL_LS="$(ls)"
USE_PKG="N/A"
# Manually input a username for the fileserver, if USER_LOGIN is blank
while [ $INSTALL_FROM_LOCAL_PATH = "N/A" ] && [ -z "$USER_LOGIN" ]  ; do
  echo "Please enter a username below:"
  read USER_LOGIN
  # Check if login is acceptable
  case "$USER_LOGIN" in
    "") echo "username CANNOT be blank" ;;
    *) echo "username acceptable, continuing..." ; break ;;
  esac
done
# Run ToolDefine() method
ToolDefine $FORCE_SSH
## Check if local repository has bee selected
case "$INSTALL_FROM_LOCAL_PATH" in
  "N/A")

    # THIS SECTION IS SPECIALLY-MADE FOR THE PUBLIC EDITION.
    # IF THE DEFAULTS ARE USED, A TURORIAL METHOD WILL EXECUTE AND QUIT THE SCRIPT
    if [ $COPY_PATH = "DEFAULT_COPYPATH" ] || [ $FILESERVER = "DEFAULT_FILESERVER" ] ; then
      echo "A Critical default value has not been set by the user."
      echo "COPY_PATH  = $COPY_PATH"
      echo "FILESERVER = $FILESERVER"
      echo "This is the public [Redacted] version, with sensitive names and directories redacted."
      echo "If you have the right credentials, you can access the INTERNAL version at:"
      echo "  https://git.doit.wisc.edu/ortizlunyov/endpointinstallation_chemhelpdesk_internal ."
      echo "Otherwise, access Help via the -h or--help file argument."
      exit 2
    fi
    #
    # END OF SECTION

    # Run appropriate method based on SPECIFIC_COMMAND
    case "$SPECIFIC_COMMAND" in
      "sftp") SFTP_Use ;;
      "scp") SCP_Use ;;
    esac
    ;;
  *)
    if [ -d "./$INSTALL_FROM_LOCAL_PATH" ] ; then
      INSTALL_PATH=$INSTALL_FROM_LOCAL_PATH
    else
      # Directory does not exist, sed error message
      ErrorAll "argument"  "LocalRepo" "NoExist" $INSTALL_FROM_LOCAL_PATH
    fi
    ;;
esac
# Install the specific package based on the selected package manager
echo "Expect SUDO prompts!"
case "$USE_PKG" in
  "rpm") RPM_Install ;;
  "dpkg") DEB_Install ;;
esac
#!/bin/bash
AGENT_APP="/Applications/spiceworks-agentshell.app"
AGENT_SHELL="${AGENT_APP}/Contents/MacOS/AgentShell.exe"
AGENT_SERVICE="AgentShell"
MONO="/Library/Frameworks/Mono.framework/Versions/Current/Commands/mono"
SW_REG_PATH="/Library/Frameworks/Mono.framework/Versions/Current/etc/mono/registry/LocalMachine/software/spiceworks"
PLIST="/Library/LaunchDaemons/org.spiceworks.spiceworks-agentshell.plist"
PLIST_TRAY="/Library/LaunchDaemons/org.spiceworks.spiceworks-agentshell-tray.plist"
AGENT_SHELL_WORKING_DIR="/var/tmp/com.spiceworks.agentshell"
HOST_FILE="/tmp/sw_agent_shell_config.host"
KEY_FILE="/tmp/sw_agent_shell_config.key"
VALUE_FILE="/tmp/sw_agent_shell_config.properties"

# Read Options
while getopts ":c" opt; do
  case $opt in
    c)
      CLEAR="true"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

# AgentShell Cleanup
if [ ! -e ${AGENT_SHELL} ]
then
  echo "AgentShell.exe does not exist. Skipping delete_app call."
else
  # Call out to AgentShell.exe to delete working files
  echo "Running delete_app on AgentShell.exe"
  ${MONO} ${AGENT_SHELL} --delete_app
fi

# Stop Service and Remove
echo Removing services
pkill -f ${AGENT_SERVICE}
launchctl unload ${PLIST}

# Stop All System Trays
echo Removing system tray
USERS=`who | awk '/console/ { print $1 }'`
for CURRUSER in $USERS
do
    su -l $CURRUSER -c "launchctl unload ${PLIST_TRAY}"
done

# To fix race condition where unload doesnt finish before remove
sleep 0

# Remove Application and PList Files
echo Removing files
rm ${PLIST}
rm ${PLIST_TRAY}
rm -rf ${AGENT_APP}

# Cleaning up application working-files directory
if [ -e ${AGENT_SHELL_WORKING_DIR} ]
then
  echo "Cleaning Agent-Shell Working Files directory"
  rm -rfd ${AGENT_SHELL_WORKING_DIR}
fi

# Cleaning up the registry
if [ -e ${SW_REG_PATH} ]
then
  echo "Clearing out Mono registry"
  rm -rf ${SW_REG_PATH}
fi

# Cleaning up the temp property files
echo "Clearing out Temp Property Files"
if [ -e ${HOST_FILE} ]
then
  rm -rf ${HOST_FILE}
fi
if [ -e ${KEY_FILE} ]
then
  rm -rf ${KEY_FILE}
fi
if [ -e ${VALUE_FILE} ]
then
  rm -rf ${VALUE_FILE}
fi

echo "Uninstall complete"
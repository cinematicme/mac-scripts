#!/bin/bash
#
# Author: Johan McGwire - Yohan @ Macadmins Slack - Johan@McGwire.tech
#
# Description: This script informs the user to connect to a wifi network using an upper left window, once the wifi network connection is detected it closes and writes a receipt
# Jamf Script Parameters:
#   $3 - Running username   - automatic
#   $4 - WiFi Network Name  - mandatory
#   $5 - Icon Path          - mandatory
#   $6 - Window Title       - mandatory
#   $7 - Email Domain       - mandatory
#   $8 - Receipt Directory  - mandatory

# Checking if the username was sent using a jamf param
if [ -z $3 ];then
    read -p "Please enter the username: " loggedInUser
else 
    loggedInUser=$3
fi

# Checking if the wifi network was sent
if [ -z $4 ];then
    read -p "Please enter the wifi network name: " networkName
else 
    networkName=$4
fi

# Checking if the icon path was sent
if [ -z $5 ];then
    read -p "Please enter the icon path: " iconPath
else 
    iconPath=$5
fi

# Checking if the title was sent
if [ -z $6 ] 2> /dev/null ;then
    read -p "Please enter the title: " title
else 
    title=$6
fi

# Checking if the email domain was sent
if [ -z $7 ] 2> /dev/null ;then
    read -p "Please enter the email domain: " emailDomain
else 
    emailDomain=$7
fi

# Checking if the receipt directory; eg /Library/INSITUTIONNAME/Receipts/
if [ -z $8 ] 2> /dev/null ;then
    read -p "Please enter the receipt directory: " receiptDir
else 
    receiptDir=$8
fi

# Writing out the window
/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper \
    -windowType utility \
    -windowPosition ul \
    -title "${title}" \
    -description "To continue the setup of your machine please click on the WiFi icon located at the top right of your screen and connect to the ${networkName} WiFi network. Your username is: 
    
${loggedInUser}@${emailDomain}

This prompt will disappear after you are successfully connected."\
    -heading "Welcome to your new Mac" \
    -alignHeading natural \
    -icon ${iconPath} &

# Saving the pid to kill it later
promptPID=$!

# Setting up
connectivityNotVerified=true

# Checking to see if the receipt or the wifi network is detected
while $connectivityNotVerified; do

    # Checking for the receipt file
    if [[ -f "${receiptDir}.${networkName}ConnectivityVerified" ]]; then
        connectivityNotVerified=false
        echo "${networkName} receipt detected"
        break
    fi

    # Getting the Wifi interface and network list
    wifiInterface=`sudo networksetup -listnetworkserviceorder | grep Hardware | awk '/Wi-Fi/ { print $NF }' | awk -F ")" '{ print $1 }'`
    wifiList=`sudo networksetup -listpreferredwirelessnetworks ${wifiInterface}`

    # Checking to see if it has the network in that list
    if echo ${wifiList} | grep -q ${networkName} 2> /dev/null > /dev/null; then
        connectivityNotVerified=false
        echo "${networkName} detected"

        # Waiting for the connection to establish
        sleep 5
    else
        # Waiting to check again
        sleep 5
    fi
done

# Writing the receipt
touch "${receiptDir}.${networkName}ConnectivityVerified"

# Killing the window
kill -9 $promptPID

# Exiting and returning the policy call code
exit $?
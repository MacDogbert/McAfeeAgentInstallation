#!/bin/bash
#Script: McAfeeAgentInstallation.sh
#Created by: Josh Smith
#Purpose: This script is intended to run as a postinstall script as part of a package to install the McAfee Agent

#########
#Variables
#########

SCRIPTNAME="McAfeeAgentInstallation.sh"
LOGHEADER=$(date +"%Y %m %d %H:%M:%S")" :"
LOGFILE=""
CurrentDate=$(date "+%Y%m%d")

#Update these variables as needed. ${3} refers to the target volume when this is run as a postinstall script in a package
#McAfeeInstallScript is where your package is placing the install.sh McAfee install script
McAfeeInstallScript="${3}/private/tmp/install.sh"
McAfeeUnInstallScript="${3}/Library/McAfee/cma/uninstall.sh"
McAfeeAgentPath="${3}/Library/McAfee/agent/bin/cmdagent"
McAfeeAgentCurrentVersion="5.0.2.185"


#########
#LOG CONFIGURATION
#########

#Check for log file on the Mac
if [ ! -e "$LOGFILE" ];
then
	#if log file not found then create the log file
	touch "$LOGFILE"
	chmod 666 "$LOGFILE"
fi


# Example of logging:
#echo "$LOGHEADER $SCRIPTNAME result: YOUR_LOG_MESSAGE_HERE." >> "$LOGFILE"


#########
#Functions
#########

CheckMcAfeeAgentInstalledVersion() {
  if [ -e "$McAfeeAgentPath" ]
    then
      McAfeeAgentInstalledVersion=$("$McAfeeAgentPath" -i | awk '/^Version:/{print $NF}')
    else
      McAfeeAgentInstalledVersion="0"
  fi
}

CheckMcAfeeAgentLastPolicyUpdateTime() {
  if [ -e "$McAfeeAgentPath" ]
    then
      McAfeeAgentLastPolicyUpdateTime=$("$McAfeeAgentPath" -i | awk '/^LastPolicyUpdateTime:/{print $NF}' | cut -c 1-8)
    else
      McAfeeAgentLastPolicyUpdateTime="0"
  fi
}

InstallMcAfeeAgent() {
	if [ -e "$McAfeeInstallScript" ]
    then
			"$McAfeeInstallScript" -i
		  echo "$LOGHEADER $SCRIPTNAME result: Installing McAfee Agent $McAfeeAgentCurrentVersion" >> "$LOGFILE"

    else
      echo "$LOGHEADER $SCRIPTNAME result: Unable to uninstall, $McAfeeInstallScript missing." >> "$LOGFILE"
  fi
}

UpgradeMcAfeeAgent() {
	if [ -e "$McAfeeInstallScript" ]
    then
			"$McAfeeInstallScript" -u
		  echo "$LOGHEADER $SCRIPTNAME result: Upgrading McAfee Agent $McAfeeAgentCurrentVersion" >> "$LOGFILE"

    else
      echo "$LOGHEADER $SCRIPTNAME result: Unable to upgrade, $McAfeeInstallScript missing." >> "$LOGFILE"
  fi
}


UnInstallMcAfeeAgent() {
  if [ -e "$McAfeeUnInstallScript" ]
    then
      "$McAfeeUnInstallScript"
      echo "$LOGHEADER $SCRIPTNAME result: Uninstalling McAfee Agent." >> "$LOGFILE"

    else
      echo "$LOGHEADER $SCRIPTNAME result: Unable to uninstall, $McAfeeUnInstallScript missing." >> "$LOGFILE"
  fi
}

TestMcAfeeAgentPolicyUpdate() {
  #check for policy on server
  "$McAfeeAgentPath" -c
  sleep 20
  CheckMcAfeeAgentLastPolicyUpdateTime
  if [ "$McAfeeAgentLastPolicyUpdateTime" == "$CurrentDate" ]
    then
      McAfeeAgentPolicyUpdate="YES"
      echo "$LOGHEADER $SCRIPTNAME result: Policy updating successfully." >> "$LOGFILE"
    else
      McAfeeAgentPolicyUpdate="NO"
      echo "$LOGHEADER $SCRIPTNAME result: Unable to update policy." >> "$LOGFILE"
  fi
}

#########
#SCRIPT
#########

CheckMcAfeeAgentInstalledVersion
#If agent is not installed, install
if [ $McAfeeAgentInstalledVersion == "0" ]
	then
		echo "$LOGHEADER $SCRIPTNAME result: McAfee Agent not detected, attempting to install" >> "$LOGFILE"
		UnInstallMcAfeeAgent
		InstallMcAfeeAgent
		TestMcAfeeAgentPolicyUpdate
	#If Agent is already installed check if version is current
	elif [[ $McAfeeAgentInstalledVersion != "$McAfeeAgentCurrentVersion" ]]
		then
			echo "$LOGHEADER $SCRIPTNAME result: MCAfee Agent is version $McAfeeAgentInstalledVersion, should be $McAfeeAgentCurrentVersion" >> "$LOGFILE"
			#If agent is out of date then see if old version is functioning
			TestMcAfeeAgentPolicyUpdate
			if [ "$McAfeeAgentPolicyUpdate" == "YES" ]
				then
					#if old version is working run the update
					echo "$LOGHEADER $SCRIPTNAME result: McAfee Agent policy is  updating successfully, running upgrade." >> "$LOGFILE"
					UpgradeMcAfeeAgent
					#if old version is not working, uninstall and reinstall.
				elif [[ "$McAfeeAgentPolicyUpdate" == "NO" ]]
					then
						echo "$LOGHEADER $SCRIPTNAME result: McAfee Agent policy is  not updating, uninstaling and re-installing." >> "$LOGFILE"
						UnInstallMcAfeeAgent
						sleep 5
						InstallMcAfeeAgent
						TestMcAfeeAgentPolicyUpdate
			fi
		#if agent is latest version verify policy is updating
	elif [[ $McAfeeAgentInstalledVersion == "$McAfeeAgentCurrentVersion" ]]
		then
			echo "$LOGHEADER $SCRIPTNAME result: McAfee Agent is already $McAfeeAgentInstalledVersion." >> "$LOGFILE"
			#If agent is current then see if old version is functioning
			TestMcAfeeAgentPolicyUpdate
			if [ "$McAfeeAgentPolicyUpdate" == "YES" ]
				then
					#if new version is working just exit
					echo "$LOGHEADER $SCRIPTNAME result: McAfee Agent policy is already updating successfully, exiting without re-installing." >> "$LOGFILE"
					#if current version is not working, uninstall and reinstall.
				elif [[ "$McAfeeAgentPolicyUpdate" == "NO" ]]; then
					UnInstallMcAfeeAgent
					sleep 5
					InstallMcAfeeAgent
					TestMcAfeeAgentPolicyUpdate
			fi
fi
rm $McAfeeInstallScript
exit 0

#!/bin/bash
ACCOUNT=guardcaptain
SEDIRECTORY=/ScoreEngine
File=$SEDIRECTORY/teamname
TeamName=$(zenity --entry --title="Enter Team Name" --text="Enter your team name.\nThis value should only be set once.")

echo $TeamName > $File
#rm /home/$ACCOUNT/.ScoreEngine/getteamname
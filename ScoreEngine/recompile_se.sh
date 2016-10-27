#!/bin/bash
if [[ $USER != "root" ]]; then
	echo "You must be root in order to run this script!"
	exit 1
fi

if [[ ! -e ./ScoringEngine.sh ]]; then 
	echo "Please 'cd' into the SEDIECTORY. Thanks"
	exit 1
fi

shc -rf ScoringEngine.sh
gcc ScoringEngine.sh.x.c -o ScoringEngine

./ScoringEngine

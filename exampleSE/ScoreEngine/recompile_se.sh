#!/bin/bash
if [[ $USER != "root" ]]; then
	echo "You must be root in order to run this script!"
	exit 1
fi

shc -f ScoringEngine.sh
mv ScoringEngine.sh.x.c score.c
score

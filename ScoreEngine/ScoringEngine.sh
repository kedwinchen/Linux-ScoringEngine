#!/bin/bash

# LICENSE FOR LINUX-SCORINGENGINE
# 
# Copyright (c) 2016-2017 Kedwin Chen
# All rights reserved.
# 
# The License (LICENSE.txt) governs use of the accompanying software.
# If you use the software, you accept this license.
# If you do not accept the license, do not use the software.
# 
# FAILURE TO MEET THE REQUIREMENTS OF THIS LICENSE WILL RESULT IN IMMEDIATE 
# REVOCATION OF THE RIGHTS GRANTED BY THE LICENSE.


##### CONSTANTS #####

export readonly ACCOUNT=sysadmin
export readonly TIME=$(date "+%r %Z on %F")
export readonly SEDIRECTORY=/opt/ScoreEngine
export readonly SEFUNCTIONS=${SEDIRECTORY}/master_se_functions.sh
export readonly OUTPUT=${SEDIRECTORY}/ScoreReport.html
export readonly CSV=${SEDIRECTORY}/data.csv
export readonly TEAMNAME=$(cat ${SEDIRECTORY}/teamname)
export readonly TITLE="Linux Practice Round <NUMBER_GOES_HERE>"

##### GLOBAL Variables #####
export count=0
export max=0

export penalties=0
export deduction=0

export points=0
export maxpoints=0

export finalscore=0

export is_verbose=0
## End GLOBAL Variables ##

##### INTEGRITY FUNCTION #####
readonly CHECKSUM_SHA512="acd6b28cbe53d5f891ad79926544fa28caeaf7818e2a1dbbf7296059580395691a345b77b66c1c5726b612733305ee8089fd18b17366ee6b1e43d20d83a7ca2f"

function check_integrity {
if [[ $(sha512sum ${SEFUNCTIONS}|cut -d ' ' -f1) = ${CHECKSUM_SHA512} ]]; then
        echo "PASS: The integrity of \"${SEFUNCTIONS}\" has not been compromised."
        return 0
else
        echo "FATAL ERROR: \"${SEFUNCTIONS}\" appears to be compromised. Execution Aborted."
        exit 1
fi
}
##### END INTEGRITY FUNCTION #####

## Custom Functions ##
function check_verbose {
if [[ $1 = "verbose" ]]; then
	$verbose=1
fi
}

function initialize {
check_integrity
source ${SEFUNCTIONS}
check_root
show_license
set_os
check_verbose

cat ${SEDIRECTORY}/HEADER.html > ${OUTPUT}
echo "sep=;" > ${CSV}
echo "Description;Points" >> ${CSV}
}

function finalize {
cat ${SEDIRECTORY}/FOOTER.html >> ${OUTPUT}
finalize_score
replace_values

echo "" >> ${CSV}
echo "End of Vulnerabilities" >> ${CSV}
echo "Number of:" >> ${CSV}
echo "Vulnerabilities Found;$count;" >> ${CSV}
echo "Vulnerabilities Scored;$max;" >> ${CSV}
echo "Points awarded;$points;" >> ${CSV}
echo "Maximum points;$maxpoints;" >> ${CSV}
echo "Penalties assessed;$penalties;" >> ${CSV}
echo "Points deducted;$deduction;" >> ${CSV}
echo "Final score;$finalscore;" >> ${CSV}

sleep 3s
clear

echo "Your score has been updated."
exit 0
}
## End Custom Functions ##

#########################
#####Begin Execution#####
#########################

initialize

# Check Penalties first (functions in se_functions.sh)
# check_authorized_users <arguments go here>
# check_authorized_sudoers <arguments go here>

# Score Vulnerabilities next
echo "<h3>NULLCOUNT out of NULLMAX scored security issues fixed, for a gain of NULLPOINTS points:</h3>" >> ${OUTPUT}


finalize

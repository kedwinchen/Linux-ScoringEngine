#!/bin/bash

##### CONSTANTS #####

ACCOUNT=sysadmin
# export SYSTEM="$(cat /proc/version |cut -d '(' -f4 |cut -d ')' -f1 |sed -s 's/[0123456789]/./g' |cut -d '.' -f1 |tr -d ' ')"
# The above variable is set temporarily in the master_se_functions.sh in the 'set_os' function
export TIME=$(date "+%r %Z on %F")
export SEDIRECTORY=/opt/ScoreEngine
export SEFUNCTIONS=${SEDIRECTORY}/master_se_functions.sh
export OUTPUT=${SEDIRECTORY}/ScoreReport.html
export TEAMNAME=$(cat ${SEDIRECTORY}/teamname)
export TITLE="Linux Practice Round <NUMBER_GOES_HERE>"

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
readonly CHECKSUM_SHA512="a9df6ddb7b5fcf0a97348476e83c711692400fff7fea4627f8cfe3dd44838146fcd62232cd6427404cb88c658e44c3ae46b27affe8b37c4b63a84710188696aa"

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
set_os
check_verbose

cat ${SEDIRECTORY}/HEADER.html > ${OUTPUT}
}

function finalize {
cat ${SEDIRECTORY}/FOOTER.html >> ${OUTPUT}
finalize_score
replace_values
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

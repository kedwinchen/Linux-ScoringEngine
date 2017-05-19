#!/bin/bash

##### CONSTANTS #####

ACCOUNT="sysadmin"
DESKTOP="/home/${ACCOUNT}/Desktop/"

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
readonly CHECKSUM_SHA512="a0be47d875fe7c8954c4f5afaba95767a0bb093bfa76a34eff42b9455c858293501b3f713f30c65fe6d1246b1a0053886f24cdb37577dee7b09d960123938317"

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
	is_verbose=1
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
function remove_apache2 {

local readonly description="Removed the 'apache2' webserver"
local readonly value="5"

dpkg -s apache2 &> /dev/null
if [[ $? -ne 0 ]]; then
	success "${description}" $value
fi
raise_max $value
}
function guest_acct {

local readonly description="Guest account disabled"
local readonly value="5"
local readonly checkstr="allow-guest[[:blank:]]*=[[:blank:]]*false"

if grep -wisEq -- "${checkstr}" /usr/share/lightdm/lightdm.conf.d/*; then
	success "${description}" $value
fi
raise_max $value
}
#########################
#####Begin Execution#####
#########################

initialize

# Check Penalties first (functions in se_functions.sh)
# check_authorized_users <arguments go here>
# check_authorized_sudoers <arguments go here>

# Score Vulnerabilities next
echo "<h3>NULLCOUNT out of NULLMAX scored security issues fixed, for a gain of NULLPOINTS points:</h3>" >> ${OUTPUT}

## Forensics Question 1: Please list the users you removed, one per line:
FORENSICS_1_ANSWERS=("ilia" "ganon" "remoteadmin")
multiple_words "Forensics Question 1" 7 "${DESKTOP}/Forensics1.txt" "${FORENSICS_1_ANSWERS[@]}"

## Disable guest account
#single_line_in_file "Guest account disabled" 5 "/usr/share/lightdm/lightdm.conf.d/*" "allow-guest[[:blank:]]*=[[:blank:]]*false"
guest_acct

## Remove unauthorized user ilia
single_line_not_in_file "Removed unauthorized user ilia" 5 "/etc/passwd" "ilia"

## User link is not an administrator
key_pair_unset "User 'link' is not an administrator" 5 "/etc/group" "sudo:x:27" "link"

## Removed prohibited mp3 file
is_file_removed "Removed prohibited mp3 file" 3 "/home/sysadmin/Music/loz_ss_sacred_duet.mp3"

## Removed the unnecessary 'apache' service
#is_package_removed "Removed the 'apache' webserver" 5 "apache2"
remove_apache2

finalize

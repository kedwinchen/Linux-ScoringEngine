#!/bin/bash

##### CONSTANTS #####

ACCOUNT=sysadmin
export TIME=$(date "+%r %Z on %F")
export SEDIRECTORY=/opt/ScoreEngine
export SEFUNCTIONS=${SEDIRECTORY}/scoring_functions.sh
export OUTPUT=${SEDIRECTORY}/ScoreReport.html
export TEAMNAME=$(cat ${SEDIRECTORY}/teamname)
export TITLE="Debian Linux Practice Round 6"

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
readonly CHECKSUM_SHA512="9a03d7b38e64e85e397b6062e8c457cdff7524459d1552c42e7dca77a9f5233b385051d47027368ebd11955855b0649a469a6a54d85e9793eaf09c3723c11ca4"

function check_integrity {
if [ $(sha512sum ${SEFUNCTIONS}|cut -d ' ' -f1) = ${CHECKSUM_SHA512} ]; then
        echo "PASS: The integrity of \"${SEFUNCTIONS}\" has not been compromised."
        return 0
else
        echo "FATAL ERROR: \"${SEFUNCTIONS}\" appears to be compromised. Execution Aborted."
        exit 1
fi
}
##### END INTEGRITY FUNCTION ##### (Put in this file to protect the integrity of, you know, the integrity function)

## Custom Functions ##
function check_verbose {
if [[ $1 = "verbose" ]]; then
	$verbose=1
fi
}

function initialize {
check_integrity
cat ${SEDIRECTORY}/HEADER.html > ${OUTPUT}
source ${SEFUNCTIONS}
check_root
check_verbose
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
#check_variables

# Check Penalties first
#check_authorized_users 
#check_authorized_sudoers #-Currently bugged

# Score Vulnerabilities next
echo "<br>" >> ${OUTPUT}
echo "<h3> NULLCOUNT out of NULLMAX scored security issues fixed, for a gain of NULLPOINTS points:</h3>" >> ${OUTPUT}

single_line_in_file "Forensics Question 1 correct" 3 "/home/sysadmin/Desktop/Forensics1.txt" "Answer:[[:blank:]]*apropos"
key_pair_exists "Forensics Question 2 correct" 3 "/home/sysadmin/Desktop/Forensics2.txt" "Answer:" "/sbin/nologin"

key_pair_exists "SSH - StrictModes enabled" 4 "/etc/ssh/sshd_config" "StrictModes" "yes"
key_pair_exists "SSH - RHosts Ignored" 4 "/etc/ssh/sshd_config" "IgnoreRhosts" "yes"
key_pair_exists "System does not accept IPv4 Redirects" 4 "/etc/sysctl.conf" "net.ipv4.conf.all.secure_redirects" "0"
single_line_in_file "A password history is set" 6 "/etc/pam.d/common-password" "pam_pwhistory.so"
is_package_installed "MySQL Server Installed" 4 "mysql-server"
is_package_removed "xinetd removed" 5 "xinetd"
single_line_in_file "avahi-daemon set to 'manual' mode" 5 "/etc/init/avahi-daemon.override" "manual"

declare secure_console=("#tty2" "#tty17" "#tty42")
multiple_words "Console is secured" 7 "/etc/securetty" "${secure_console[@]}"

key_pair_exists "umask 077 in /etc/profile set" 4 "/etc/profile" "umask" "077"

declare audit_k_mods=("-w[[:blank:]]+/sbin/insmod[[:blank:]]+-p[[:blank:]]+x[[:blank:]]+-k[[:blank:]]+modules" "-w[[:blank:]]+/sbin/rmmod[[:blank:]]+-p[[:blank:]]+x[[:blank:]]+-k[[:blank:]]+modules" "-w[[:blank:]]+/sbin/modprobe[[:blank:]]+-p[[:blank:]]+x[[:blank:]]+-k[[:blank:]]+modules"  "-a[[:blank:]]+always,exit[[:blank:]]+-F[[:blank:]]+arch=b32[[:blank:]]+-S[[:blank:]]+init_module[[:blank:]]+-S[[:blank:]]+delete_module[[:blank:]]+-k[[:blank:]]+modules")
multiple_words "Audit system audits loading of dynamic kernel modules" 15 "/etc/audit/audit.rules" "${audit_k_mods[@]}"

finalize

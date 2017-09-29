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

##### Scoring Engine Self-Defence #####
function zeroize() {
    scoring_initialize
    scoring_finalize
    echo
    echo "Script terminated prematurely..."
    echo "Zeroing data for Scoring Engine Self-Defence..."
    echo
    exit 255
}
trap zeroize 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 SIGTSTP
##### End Self-Defence Section #####

##### CONSTANTS #####

export readonly ACCOUNT=sysadmin
export SEDIRECTORY=/opt/ScoreEngine/
export SEFUNCTIONS=${SEDIRECTORY}/master_se_functions.sh
export SEDATA=${SEDIRECTORY}/data/
export readonly TITLE="Linux Practice Round <NUMBER_GOES_HERE>"
export readonly DEVELOPING="yes"

##### INTEGRITY FUNCTION #####
readonly CHECKSUM_SHA512="%SE_FX_SHA512%"

function check_integrity {
  if [[ $(sha512sum ${SEFUNCTIONS}|cut -d ' ' -f1) = ${CHECKSUM_SHA512} ]]; then
          echo "PASS: The integrity of \"${SEFUNCTIONS}\" has not been compromised."
          return 0
  else
          echo "FATAL ERROR: \"${SEFUNCTIONS}\" appears to be compromised. Execution Aborted."
          exit 1
  fi
  for dir in /bin /dev /etc /home /lib /media /mnt /opt /proc /root /run /sbin /srv /sys /usr /var ;
  do
   	if [[ ! -d $dir ]]; then
  		echo "FATAL ERROR: Directory $dir is missing! Please restore it to continue!"
  		exit 1
  	fi
  done
}
##### END INTEGRITY FUNCTION #####

## Custom Functions ##

function check_params {
#  while getopts "vqh" OPTION ; do
  getopts "vqh" OPTION 
    case ${OPTION} in
      h)
        echo "Help"
        ;;
      v)
        verbose=1
        ;;
      q)
        quiet=1
        ;;
      \?)
        echo "Help"
        echo "${OPTION} was not understood"
        exit 2
        ;;
    esac
# done
}

function scoring_initialize {
  check_integrity
  source ${SEFUNCTIONS}
  set_vars
  calculate_time
  show_license
  check_params

  cat ${SERESOURCES}/report/HEADER.html > ${REPORT}

  cat <<- _EOF_ > ${CSV}
  sep=;
  Description;Points
  _EOF_
}

function scoring_finalize {
  cat ${SERESOURCES}/report/FOOTER.html >> ${REPORT}
  finalize_score
  replace_values

  cat <<- _EOF_ >> ${CSV}

  End of Vulnerabilities
  Number of:
  Vulnerabilities Found;$count;
  Vulnerabilities Scored;$max;
  Points awarded;$points;
  Maximum points;$maxpoints;
  Penalties assessed;$penalties;
  Points deducted;$deduction;
  Final score;$finalscore;

  _EOF_

  sleep 3s
  clear
  rm -f ${SEDATA}/ScoreReport.html
  cp ${SEDIRECTORY}/ScoreReport.html ${SEDATA}/
  echo "Your score has been updated."
  exit 0
}
## End Custom Functions ##

#########################
#####Begin Execution#####
#########################

scoring_initialize

# Check Penalties first (functions in se_functions.sh)
# check_authorized_users <arguments go here>
# check_authorized_sudoers <arguments go here>

# Score Vulnerabilities next
echo "<h3>%COUNT% out of %MAX% scored security issues fixed, for a gain of %POINTS% points:</h3>" >> ${REPORT}


scoring_finalize

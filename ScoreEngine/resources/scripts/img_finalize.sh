#!/bin/bash

source /opt/ScoreEngine/master_se_functions.sh
set_vars

if ! in_dev ; then
  echo "You are not a developer!"
  exit 1
fi

bash ${SESCRIPTS}/delete_logs.sh

cd ${SEDIRECTORY}

readonly dev_line=$(grep -i -- "readonly DEVELOPING") ${SEDIRECTORY}/ScoringEngine.sh
sed -i -e s/${dev_line}/'export readonly DEVELOPING="no"'/g ${SEDIRECTORY}/ScoringEngine.sh

readonly CUR_HASH=$(grep -- "readonly CHECKSUM_SHA512" ${SEDIRECTORY}/ScoringEngine.sh |cut -d '"' -f2)
readonly SE_FX_SHA512=$(sha512sum ${SEDIRECTORY}/master_se_functions.sh)
sed -i -e s/${CUR_HASH}/${SE_FX_SHA512}/g ${SEDIRECTORY}/ScoringEngine.sh

shc -Urf ${SEDIRECTORY}/ScoringEngine.sh
if [[ $? -ne 0 ]] ; then 
  echo "Could not cross-compile the script using shc!"
  exit 1
fi

gcc -o ${SEDIRECTORY}/ScoringEngine ${SEDIRECTORY}/ScoringEngine.sh.x.c
if [[ $? -ne 0 ]] ; then 
  echo "Could not compile the script using gcc!"
  exit 1
fi

chattr +i ${SEDIRECTORY}/ScoringEngine.sh.x.c

/usr/local/bin/score

echo "Done, please test to ensure the program works, then remove ScoringEngine.sh, ScoringEngine.sh.x, ScoringEngine.sh~, .ScoringEngine.sh.swp, and other files related to the plain text Scoring Engine script"

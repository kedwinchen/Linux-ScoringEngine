# -- DO NOT MODIFY THIS FILE UNLESS YOU KNOW WHAT YOU ARE DOING -- #
# -- MODIFYING THIS FILE WILL CAUSE THE SCORING ENGINE TO BREAK -- #

# LICENSE FOR LINUX-SCORINGENGINE
#
# Copyright (c) 2016-2017 Kedwin Chen
# All rights reserved.
#
# THE LICENSE FOR THIS SOFTWARE CAN BE FOUND IN ScoreEngine/LICENSE.txt
# If you use the software, you accept this license.
# If you do not accept the license, do not use the software.
#
# FAILURE TO MEET THE REQUIREMENTS OF THIS LICENSE WILL RESULT IN IMMEDIATE
# REVOCATION OF THE RIGHTS GRANTED BY THE LICENSE.
function show_license {
    cat ${SEDIRECTORY}/LICENSE.txt
}

##### CONSTANT FUNCTIONS  #####

# Description: Checks if the user running the script is root
function check_root {
    if [[ $EUID -ne 0 ]]; then
        echo "FATAL ERROR: You must be root to run this script. Execution aborted"
        exit 1
    fi
    return 0
}

# Description: Get the architecture of the system (i.e., 32 or 64)
function get_arch {
        getconf LONG_BIT
        if [[ $? -ne 0 ]] ; then
            echo "FATAL ERROR: Could not determine the architecture of the OS"
            exit 1
        fi
        export readonly OS_ARCH=$(getconf LONG_BIT)
        return 0
}

# Description: Checks the operating system.
function set_os {
    get_arch
    export readonly SYSTEM="$(cat /proc/version |cut -d '(' -f4 |cut -d ')' -f1 |sed -s 's/[0123456789]/./g' |cut -d '.' -f1 |tr -d ' ' | cut -d '/' -f1 |tr '[:upper:]' '[:lower:]')"

    case $SYSTEM in
    "redhat")
        export readonly OS_TYPE="redhat"
        export PKGQUERY="rpm -q "
        export PKG="yum "
        export ADMIN_GRP="wheel"
        export SVC_CONF="chkconfig "
        export PKGREMOVE="${PKG} autoremove "
        export readonly PKGUPDATE="${PKG} checkupdate "
        ;;
    "debian"|"ubuntu")
        export readonly OS_TYPE="debian"
        export PKGQUERY="dpkg -s "
        export PKG="apt-get "
        export ADMIN_GRP="sudo"
        export SVC_CONF="sysv-rc-conf "
        export PKGREMOVE="${PKG} --purge autoremove"
        export readonly PKGUPDATE="${PKG} update "
        ;;
    *)
        echo "FATAL ERROR: Could not determine the operating system type. This is due to one of the following: "
        echo "1. The SYSTEM variable (current value ${SYSTEM}) (in ${SEDIRECTORY}/master_se_functions.sh) is not set correctly."
        echo "2. Operating system not supported or recognized. The system uses /proc/version to determine the OS_TYPE"
        echo "-----"
        echo "Execution aborted"
        exit 1
        ;;
    esac

    export readonly PKGINSTALL="${PKG} install -y "
    return 0
}

# Description: Sets the variables
function set_vars {
    check_root
    set_os
    export readonly SEDIRECTORY=/opt/ScoreEngine/
    export readonly SEFUNCTIONS=${SEDIRECTORY}/master_se_functions.sh
    export readonly REPORT=${SEDIRECTORY}/ScoreReport.html
    export readonly SERESOURCES=${SEDIRECTORY}/resources/
    export readonly SESCRIPTS=${SERESOURCES}/scripts/
    export readonly SEDATA=${SEDIRECTORY}/data/
    export readonly CSV=${SEDATA}/data.csv
    export readonly UNIQUEID=$(cat ${SEDIRECTORY}/uniqueid)
    export readonly TIME=$(date "+%r %Z on %F")
    export count=0
    export max=0
    export penalties=0
    export deduction=0
    export points=0
    export maxpoints=0
    export finalscore=0
    export verbose=0
}

# Description: Returns a value to see if you are in a developing state without the need to run the ScoringEngine
function in_dev {
    local readonly state="$(grep -i -- 'readonly DEVELOPING' ${SEDIRECTORY}/ScoringEngine.sh|cut -d '"' -f2|tr '[:upper:]' '[:lower:]')"
    if [[ ${state} == "no" ]] ; then
        return 1
    else
        return 0
    fi
}

# Description: Sends the user a message through the notify command. Also plays appropriate file using the play command from sox package.
function notify {
    oldscore=$(cat ${SEDATA}/oldscore)
    if [[ $finalscore -gt $oldscore ]]; then
        notify-send "LINUX-SCORINGENGINE" "You gained points!"
        play -q ${SERESOURCES}/media/gain.wav &
    else
        if [[ $finalscore -lt $oldscore ]]; then
            notify-send "LINUX-SCORINGENGINE" "You lost points!"
            play -q ${SERESOURCES}/media/alarm.wav &
        else
            #if [[ $finalscore -eq $oldscore ]]; then
            notify-send "LINUX-SCORINGENGINE" "Your total points didn't change"
        fi
    fi

    echo "$finalscore" > ${SEDATA}/oldscore
}

# Description: Caclulates the time, formats it prettily into the ${TIME_PASSED} variable.
function calculate_time {
    starttime=$(cat /usr/local/starttime)
    elapsedtime=$(cat /usr/local/elapsedtime)
    sessiontime=0

    if [[ "$starttime" == "" ]]; then
        sessiontime=0
        time="$(date +%s)"
        echo $time > /usr/local/starttime
    else
        time="$(date +%s)"
        sessiontime=$((time-starttime))
    fi
    if [[ "$elapsedtime" == "" ]]; then
        elapsedtime=$sessiontime
    else
        elapsedtime=$((elapsedtime+sessiontime))
    fi

    export readonly ELAPSED_HOURS=$((elapsedtime/3600))
    export readonly ELAPSED_MINUTES=$(( (elapsedtime - ELAPSED_HOURS*3600)  /60 ))
    export readonly ELAPSED_SECONDS=$((elapsedtime%60))

    export readonly TIME_PASSED_STRING="${ELAPSED_HOURS} hours, ${ELAPSED_MINUTES} minutes, ${ELAPSED_SECONDS} seconds"
    export readonly TIME_PASSED_CLOCK="${ELAPSED_HOURS}:${ELAPSED_MINUTES}:${ELAPSED_SECONDS} (hh:mm:ss)"
}

function gain_points {
    local readonly value=$1

    ((count++))
    ((points+=value))
}

function penalize {
    local readonly value=$1

    ((penalties++))
    ((deduction+=value))
}

function raise_max {
    local readonly value=$1

    ((max++))
    ((maxpoints+=value))
}

function success {
    local readonly description="$1"
    local readonly value=$2

    if [[ $is_verbose -eq 1 ]]; then
        echo "${description} - $value points"
    fi

    echo "<br>${description} - $value points" >> ${REPORT}
    echo "${description};$value;" >> ${CSV}
    gain_points $value
}

function fail {
    local readonly description="$1"
    local readonly value=$2

    if [[ $is_verbose -eq 1 ]]; then
        echo "${description} -$value points"
    fi

    echo "<br>${description} -$value points" >> ${REPORT}
    echo "${description};$value;" >> ${CSV}
    penalize $value
}

# Description: Calculates the score based on score and deductions.
function finalize_score {
    finalscore=$(($points - $deduction))
}

# Description: Replaces values in the Scoring Report file.
function replace_values {
    sed -i -e "s/%TITLE%/$TITLE/g" ${REPORT}
    sed -i -e "s/%TIME_PASSED%/${TIME_PASSED_STRING}/g" ${REPORT}
    #sed -i -e "s/%TIME_PASSED%/${TIME_PASSED_CLOCK}/g" ${REPORT}
    sed -i -e "s/%TIME%/$TIME/g" ${REPORT}

    sed -i -e "s/%UNIQUEID%/$UNIQUEID/g" ${REPORT}

    sed -i -e "s/%PENALTY%/$penalties/g" ${REPORT}
    sed -i -e "s/%DEDUCTIONS%/$deduction/g" ${REPORT}

    sed -i -e "s/%POINTS%/$points/g" ${REPORT}
    sed -i -e "s/%MAXPOINTS%/$maxpoints/g" ${REPORT}

    sed -i -e "s/%COUNT%/$count/g" ${REPORT}
    sed -i -e "s/%MAX%/$max/g" ${REPORT}
}

# Description: Updates the banner to display the appropriate score.
function update_banner {
    local readonly BANNER_CFG="/etc/classification-banner"
    cp ${BANNER_CFG}.template ${BANNER_CFG}
    sed -i -e "s/%FRACTION%/$count OUT OF $max/g" ${BANNER_CFG}
    if [[ $count -eq $max ]] ; then
        sed -i -e "s/%BGCOLOR%/#00FF00/g"
    else
        sed -i -e "s/%BGCOLOR%/#FF0000/g"
    fi
    kill -9 $(ps -elf|grep -v grep | grep classification-banner.py|awk -F " " '{ print $4 }')
    /usr/bin/nohup /usr/bin/python2 /usr/local/bin/classification-banner.py &>/dev/null &
}

### Scoring Functions

## General Notes:
# Functions should make use of the success and raise_max functions and should not modify the points directly
#
# Return: Functions should echo a String with format "<Description> - <Point value> points" if the condition is met. Otherwise, should not return anything.


#--# Gain Points #--#

##
# The function checks for a single line in the file specified
# Arguments: Description (String); Point value (Integer); File (String); Line to find (String)
##
function single_line_in_file {
    local readonly description="$1"
    local readonly value="$2"
    local readonly query="$3"
    local readonly checkstr="$4"

    if grep -wisEq -- "${checkstr}" "${query}"; then
        success "${description}" $value
    fi
    raise_max $value
}

##
# The function checks that the specified line is not in the specified file
# Arguments: Description (String); Point value (Integer); File (String); Line to not find (String)
##
function single_line_not_in_file {
    local readonly description="$1"
    local readonly value="$2"
    local readonly query="$3"
    local readonly checkstr="$4"

    if ! grep -wisEq -- "${checkstr}" "${query}"; then
            success "${description}" $value
    fi
    raise_max $value
}

##
# The function checks if a specified file exists
# Arguments: Description (String); Point value (Integer); File (String)
##
function is_file_removed {
    local readonly description="$1"
    local readonly value="$2"
    local readonly query="$3"

    if [[ ! -e "${query}" ]]; then
        success "${description}" $value
    fi
    raise_max $value
}

##
# The function checks if a specified package is installed
# Arguments: Description (String); Point value (Integer); Package (String)
##
function is_package_installed {
    local readonly description="$1"
    local readonly value="$2"
    local readonly query="$3"

    if ${PKGQUERY} ${query} &> /dev/null; then
        success "${description}" $value
    fi
    raise_max $value
}

##
# The function checks if a specified package is removed
# Arguments: Description (String); Point value (Integer); Package (String)
##
function is_package_removed {
    local readonly description="$1"
    local readonly value="$2"
    local readonly query="$3"

    if ! ${PKGQUERY} ${query} &> /dev/null; then
        success "${description}" $value
    fi
    raise_max $value
}

##
# The function checks if a multiple words (Strings) in a file exist
# Arguments: Description (String); Point value (Integer); File (String); Multiple values (ARRAY of Strings)
##
function multiple_words {
    local readonly description="$1"
    local readonly value="$2"
    local readonly query="$3"

    shift 3

    IFS='
    '

    local readonly words=($(printf "%s\n" "$@"))
    local readonly keys=${#words[@]}
    local check=0

    for find_this in ${words[@]}; do
        grep -wisEq -- "${find_this}" ${query}
        if [[ $? -eq 0 ]]; then
            let check=$((check+1))
        fi
    done

    if [[ $check -eq $keys ]]; then
        success "${description}" $value
    fi
    raise_max $value
}

##
# The function checks if the setting for the key exists
# Arguments: Description (String); Point value (Integer); File (String); Key to find (String); Setting of key (String)
##
function key_pair_set {
    local readonly description="$1"
    local readonly value="$2"
    local readonly query="$3"
    local readonly key="$4"
    local readonly setting="$5"

    if grep -wisE -- "${key}" "${query}"|grep -wisEq -- "${setting}"; then
        success "${description}" $value
    fi
    raise_max $value
}

##
# The function checks if the setting for the key does not exist
# Arguments: Description (String); Point value (Integer); File (String); Key to find (String); Setting of key (String)
##
function key_pair_unset {
    local readonly description="$1"
    local readonly value="$2"
    local readonly query="$3"
    local readonly key="$4"
    local readonly setting="$5"

    grep -wisE -- "${key}" "${query}"|grep -wisEq -- "${setting}"
    if [[ $? -ne 0 ]]; then
        success "${description}" $value
    fi
    raise_max $value
}

##
# The function checks if multiple values exist on the same line (the function does not check if the same line exists twice)
# Arguments: Description (String); Point value (Integer); File (String); Key to find (String); Settings of key (ARRAY of String)
##
function multiple_keys_set {
    local readonly description="$1"
    local readonly value="$2"
    local readonly query="$3"
    local readonly key="$4"
    local readonly setting="$5"
    local check=0

    for multi_key in ${setting[@]}; do
        grep -wisE -- "${key}" "${query}"|grep -wisEq -- "${multi_key}"
        if [[ $? -eq 0 ]]; then
            ((check++))
        fi
    done

    if [[ $check -eq $keys ]]; then
        success "${description}" $value
    fi
    raise_max $value
}

##
# The function checks if multiple values do not exist on the same line (the function does not check if the same line exists twice)
# Arguments: Description (String); Point value (Integer); File (String); Key to find (String); Settings of key (ARRAY of String)
##
function multiple_keys_unset {
    local readonly description="$1"
    local readonly value="$2"
    local readonly query="$3"
    local readonly key="$4"
    local readonly setting="$5"
    local check=0

    for multi_key in ${setting[@]}; do
        grep -wisE -- "${key}" "${query}"|grep -wisEq -- "${multi_key}"
        if [[ $? -eq 0 ]]; then
            ((check++))
        fi
    done

    if [[ $check -eq 0 ]]; then
        success "${description}" $value
    fi
    raise_max $value
}

##
# The function checks if the permissions specified are set on the file
# Arguments: Description (String); Point value (Integer); File (String); Permission (3 or 4 digit integer)
##
function is_permission_set {
    local readonly description="$1"
    local readonly value="$2"
    local readonly query="$3"
    local readonly permissions="$4"

    if [[ "${permissions}" == "$(stat -c %a ${query})" ]]; then
        success "${description}" $value
    fi
    raise_max $value
}

#--# Lose Points #--#

##
# The function checks if authorized users have accounts
# Arguments: Point value (Integer); Users (ARRAY of Strings)
##
function check_authorized_users {
    local readonly value="$1"
    local readonly query="/etc/passwd"

    shift 1

    IFS=$'\n'

    local readonly words=($(printf "%s\n" "$@"))
    local readonly keys=${#words[@]}

    for find_this in ${words[@]}; do
        grep -wisEq -- "${find_this}" ${query}
        if [[ $? -ne 0 ]]; then
            fail "Authorized user $find_this has been deleted" $value
        fi
    done
}

##
# The function checks if authorized admins have sudo privileges
# Arguments: Point value (Integer); Admins (ARRAY of Strings)
##
function check_authorized_admins {
    local readonly value="$1"
    local readonly query="/etc/group"

    shift 1

    IFS=$'\n'

    local readonly words=($(printf "%s\n" "$@"))
    local readonly keys=${#words[@]}

    for multi_key in ${words[@]}; do
        grep -wisE -- "${ADMIN_GRP}" "${query}"|grep -wisEq -- "${multi_key}"
        if [[ $? -ne 0 ]]; then
            fail "Authorized administrator $find_this does not have administrator privileges!" $value
        fi
    done
}

##### CONSTANT FUNCTIONS  #####
# -- DO NOT MODIFY UNLESS YOU KNOW WHAT YOU ARE DOING -- #
# -- Modifying this file WILL cause your scoring engine to break -- #

# Description: Checks if the user running the script is root
function check_root {
if [[ $USER != "root" ]]; then
	echo "FATAL ERROR: You must be root to run this script. Execution aborted"
	exit 1
fi
return 0
}

# Description: Checks the operating system.
function set_os {
	export readonly SYSTEM="$(cat /proc/version |cut -d '(' -f4 |cut -d ')' -f1 |sed -s 's/[0123456789]/./g' |cut -d '.' -f1 |tr -d ' ' | cut -d '/' -f1 )"

	case $SYSTEM in
	"RedHat")
		export readonly OS_TYPE="redhat"
		export PKGQUERY="rpm -q "
		export ADMIN_GRP="wheel"
		;;
	"Debian"|"Ubuntu")
		export readonly OS_TYPE="debian"
		export PKGQUERY="dpkg -s "
		export ADMIN_GRP="sudo"
		;;
	*)
		echo "FATAL ERROR: Could not determine the operating system type. This is due to one of the following: "
		echo "1. The SYSTEM variable (current value ${SYSTEM}) (in ${SEDIRECTORY}/master_se_functions.sh is not set correctly."
		echo "2. Operating system not supported or recognized. The system uses /proc/version to determine the OS_TYPE"
		echo "-----"
		echo "Execution aborted"
		return 1
		;;
	esac
}

# Description: Sends the user a message through the notify command. Also plays appropriate file using the play command from sox package.
function notify {
oldscore=$(cat ${SEDIRECTORY}/oldscore)
if [ $finalscore -gt $oldscore ]; then
	notify-send "CyberPatriot" "You gained points!"
	play -q ${SEDIRECTORY}/gain.wav &
else
	if [ $finalscore -lt $oldscore ]; then
		notify-send "CyberPatriot" "You lost points!"
		play -q ${SEDIRECTORY}/alarm.wav &
	else
		#if [ $finalscore -eq $oldscore ]; then
		notify-send "CyberPatriot" "Your total points didn't change"
	fi
fi

echo "$finalscore" > ${SEDIRECTORY}/oldscore
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

echo "<br>${description} - $value points" >> ${OUTPUT}
gain_points $value
}

function fail {
local readonly description="$1"
local readonly value=$2

if [[ $is_verbose -eq 1 ]]; then
	echo "${description} -$value points"
fi

echo "<br>${description} -$value points" >> ${OUTPUT}
penalize $value
}

# Description: Calculates the score based on score and deductions.
function finalize_score {
finalscore=$(($points - $deduction))
}

# Description: Replaces values in the Scoring Report file.
function replace_values {
sed -i -e "s/NULLTITLE/$TITLE/g" ${OUTPUT}
sed -i -e "s/NULLTIME/$TIME/g" ${OUTPUT}

sed -i -e "s/NULLTEAMNAME/$TEAMNAME/g" ${OUTPUT}

sed -i -e "s/NULLPENALTY/$penalties/g" ${OUTPUT}
sed -i -e "s/NULLDEDUCTIONS/$deduction/g" ${OUTPUT}

sed -i -e "s/NULLPOINTS/$points/g" ${OUTPUT}
sed -i -e "s/NULLMAXPOINTS/$maxpoints/g" ${OUTPUT}

sed -i -e "s/NULLCOUNT/$count/g" ${OUTPUT}
sed -i -e "s/NULLMAX/$max/g" ${OUTPUT}
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
	if [ $? -eq 0 ]; then
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
function key_pair_exists {
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
# The function checks if multiple values exist on the same line (the function does not check if the same line exists twice)
# Arguments: Description (String); Point value (Integer); File (String); Key to find (String); Settings of key (ARRAY of String)
##
function multiple_keys {
local readonly description="$1"
local readonly value="$2"
local readonly query="$3"
local readonly key="$4"
local readonly setting="$5"
local check=0

for multi_key in ${setting[@]}; do
	grep -wisE -- "${key}" "${query}"|grep -wisEq -- "${multi_key}"
	if [ $? -eq 0 ]; then
		((check++))
	fi
done

if [[ $check -eq $keys ]]; then
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

IFS='
'

local readonly words=($(printf "%s\n" "$@"))
local readonly keys=${#words[@]}

for find_this in ${words[@]}; do
	grep -wisEq -- "${find_this}" ${query}
	if [ $? -ne 0 ]; then
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

IFS='
'

local readonly words=($(printf "%s\n" "$@"))
local readonly keys=${#words[@]}

for multi_key in ${words[@]}; do
	grep -wisE -- "${ADMIN_GRP}" "${query}"|grep -wisEq -- "${multi_key}"
	if [[ $? -ne 0 ]]; then
		fail "Authorized administrator $find_this does not have administrator privileges!" $value
	fi
done
}

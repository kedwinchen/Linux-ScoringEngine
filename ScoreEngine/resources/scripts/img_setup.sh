#!/bin/bash

source /opt/ScoreEngine/master_se_functions.sh
set_vars

if ! in_dev ; then
  echo "You are not a developer!"
  exit 1
fi

${PKGINSTALL} sox libsox-fmt-all notify-osd dos2unix curl git automake python-gtk2

cd /tmp/
git clone https://github.com/neurobin/shc.git ./shc
cd ./shc
./configure
make
make install

echo '* * * * * root /usr/local/bin/score' >> /etc/crontab
echo 'ALL ALL=NOPASSWD: /usr/local/bin/score' > /etc/sudoers.d/ScoreEngine
chattr +i /etc/sudoers.d/ScoreEngine
echo "/usr/lib/notify-osd/notify-osd &" >> /etc/profile

bash ${SESCRIPTS}/setup_banner.sh

echo <<- _EOF_ > /usr/local/bin/score
#!/bin/bash
if [[ \$EUID -ne 0 ]]; then
   echo "You must be root to run this script!"
   exit 1
fi

/bin/rm /opt/ScoreEngine/ScoringEngine
/usr/bin/gcc /opt/ScoreEngine/ScoringEngine.sh.x.c -o /opt/ScoreEngine/ScoringEngine
/opt/ScoreEngine/ScoringEngine 2> /dev/null
if [[ \$? -ne 0 ]]; then
       echo "Something went wrong..."
       exit 1
else
       exit 0
fi
_EOF_
chown root:root /usr/local/bin/score
chmod 4755 /usr/local/bin/score
chattr +i /usr/local/bin/score

echo "PLEASE NOTE THAT THIS SCORING ENGINE HAS NOT YET BEEN CONFIGURED TO USE systemd STYLE INITIALIZATION SCRIPTS!"
cat << _EOF_ > /etc/rc6.d/K99initScoring
#!/bin/bash

starttime=\$(cat /usr/local/starttime)
elapsedtime=\$(cat /usr/local/elapsedtime)


sessiontime=0

if [[ "\$starttime" == "" ]]; then
	sessiontime=0
else
	time="\$(date +%s)"
	sessiontime=\$((time-starttime))
fi

if [[ "\$elapsedtime" == "" ]]; then
	totaltime=\$sessiontime
	if [[ \$totaltime == 0 ]]; then
	    echo > /usr/local/elapsedtime
	else
	    echo \$totaltime > /usr/local/elapsedtime
	fi
else

	totaltime=\$((elapsedtime+sessiontime))
	echo \$totaltime > /usr/local/elapsedtime

fi

echo > /usr/local/starttime
_EOF_

touch /usr/local/starttime
touch /usr/local/elapsedtime

readonly ACCOUNT=$(grep -i -- 'ACCOUNT=' ${SEDIRECTORY}/ScoringEngine.sh |cut -d '=' -f2)
for DESKTOP_FILE in ReadMe ScoreReport UpdateScore ; do
  cp ${SESCRIPTS}/${DESKTOP_FILE}.desktop /home/${ACCOUNT}/Desktop/
done

chown ${ACCOUNT}. /home/${ACCOUNT}/Desktop/*
chmod 500 /home/${ACCOUNT}/Desktop/*.desktop
chmod 600 /home/${ACCOUNT}/Desktop/*.txt

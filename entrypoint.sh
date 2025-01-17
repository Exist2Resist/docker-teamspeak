#!/bin/sh

set -e

# change user and group id as specified in env and based on os
if [[ $(cat /etc/os-release | awk 'NR==1') == 'NAME="Alpine Linux"' ]]; then 
  usermod -u ${PUID} teamspeak
elif [[ $(cat /etc/os-release | awk 'NR==1') == 'NAME="Debian"' ]]; then

elif [[ unraid ]]; then

else
  echo "Invalid or unknown OS"
fi

# create directory for teamspeak files
test -d /data/files || mkdir -p /data/files && chown teamspeak:teamspeak /data/files

# create directory for teamspeak logs
test -d /data/logs || mkdir -p /data/logs && chown teamspeak:teamspeak /data/logs

# create symlinks for all files and directories in the persistent data directory
cd "${TS_DIRECTORY}"
for i in /data/*
do
  ln -sf "${i}" .
done

# remove broken symlinks
find -L "${TS_DIRECTORY}" -type l -delete

# create symlinks for static files
STATIC_FILES="query_ip_whitelist.txt query_ip_blacklist.txt ts3server.ini ts3server.sqlitedb ts3server.sqlitedb-shm ts3server.sqlitedb-wal .ts3server_license_accepted"

for i in ${STATIC_FILES}
do
  ln -sf /data/"${i}" .
done

# check to see if license agreement method has been passed (this doesn't validate the license agreement acceptance; just a basic check)
if [ -f "${TS_DIRECTORY}/.ts3server_license_accepted" ] || [ "$(echo "$*" | grep -q "license_accepted=1"; echo $?)" = "0" ] || [ "${TS3SERVER_LICENSE}" = "accept" ]
then
  echo "Found a license agreement method; launching TeamSpeak"
else
  echo "Warning: license agreement method hasn't been passed; see the README (https://github.com/mbentley/docker-teamspeak#license-agreement) for how to do so with this Docker image"
  echo "Note: if you're running TeamSpeak < 3.1.0; you can safely ignore this message"; echo
fi

export LD_LIBRARY_PATH=".:$LD_LIBRARY_PATH"
exec tini -- ./ts3server "$@"

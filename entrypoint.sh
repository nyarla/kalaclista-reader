#!/usr/bin/env bash

set -euo pipefail

# set timezone
# copied from https://github.com/FreshRSS/FreshRSS/blob/edge/Docker/entrypoint.sh#L3
ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime
echo "$TZ" >/etc/timezone

find /etc/php*/ -type f -name php.ini -exec sed -r -i "\\#^;?date.timezone#s#^.*#date.timezone = $TZ#" {} \;

# initialize datadir
export DATA_PATH=/data/freshrss
[[ -d $DATA_PATH ]] || mkdir -p $DATA_PATH

cp -R /var/lib/freshrss/data/* $DATA_PATH/

chmod -R -w $DATA_PATH
chown -R nobody:nobody $DATA_PATH

# reconfigure or install FreshRSS
if [[ -e /data/freshrss/config.php ]]; then
  /var/lib/freshrss/cli/reconfigure.php $settingsFlags
  /var/lib/freshrss/cli/update-user.php  $userFlags
else
  /var/lib/freshrss/cli/prepare.php
  /var/lib/freshrss/cli/do-install.php $settingsFlags
  /var/lib/freshrss/cli/create-user.php $userFlags
fi

# start FreshRSS command
cd /var/run/freshrss
/app/bin/goreman start

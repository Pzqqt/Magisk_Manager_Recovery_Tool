#!/sbin/sh

. /tmp/mmr/script/common.sh

module=$1

/tmp/mmr/bin/tree ${workPath}/${module}

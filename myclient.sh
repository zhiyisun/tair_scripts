#!/bin/bash - 
#===============================================================================
#
#          FILE: myclient.sh
# 
#         USAGE: ./myclient.sh 
# 
#   DESCRIPTION: launch tair client to connect to config server
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Zhiyi Sun (zsun), zhiyisun@msn.com 
#  ORGANIZATION: 
#       CREATED: 09/20/2016 09:03:02 AM
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

if [ -z ${SERVER+x} ]
then
	SERVER=13.0.0.3
fi

if [ -z ${TAIR_DIR+x} ]
then
	TAIR_DIR=/home/zsun/workspace/code/tair
fi

PORT=5198
GROUP=group_1
TAIR_CS=${TAIR_DIR}/tair_bin_cs
cd ${TAIR_CS}/sbin
./tairclient -c ${SERVER}:${PORT} -g ${GROUP}

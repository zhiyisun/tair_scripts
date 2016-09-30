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

SERVER=12.0.0.100
PORT=5198
GROUP=group_1
TAIR_DIR=/home/zsun/workspace/code/tair
TAIR_CS=${TAIR_DIR}/tair_bin_cs
cd ${TAIR_CS}/sbin
./tairclient -c ${SERVER}:${PORT} -g ${GROUP}

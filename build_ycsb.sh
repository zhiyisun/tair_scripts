#!/bin/bash - 
#===============================================================================
#
#          FILE: build_ycsb.sh
# 
#         USAGE: ./build_ycsb.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Zhiyi Sun (zsun), zhiyisun@msn.com
#  ORGANIZATION: 
#       CREATED: 09/20/2016 07:45:20 AM
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

if [ -z ${YCSB+x} ]
then
	YCSB=${YCSB}/workspace/code/YCSB
fi

cd ${YCSB}
mvn -Dcheckstyle.console=false -pl com.yahoo.ycsb:tair-binding -am clean package

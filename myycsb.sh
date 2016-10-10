#!/bin/bash - 
#===============================================================================
#
#          FILE: myycsb.sh
# 
#         USAGE: ./myycsb.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Zhiyi Sun (zsun), zhiyisun@msn.com
#  ORGANIZATION: 
#       CREATED: 09/19/2016 05:40:22 PM
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

PROGRAM_NAME="myycsb.sh"
YCSB_PARENT_DIR=${HOME}/workspace/code
YCSB_DIR=${YCSB_PARENT_DIR}/YCSB
YCSB_DATA=${YCSB_PARENT_DIR}/tair_scripts/tair.dat
YCSB_LOG_DIR=${YCSB_PARENT_DIR}/tair_scripts/log
NUM_OF_YCSB_DEFAULT="1"
YCSB_WORKLOAD_TYPE="workloadc"
LOAD="false"
TEMP_DIR=${HOME}/tmp

function print_help()
{
	printf "myycsb.sh up [-n num-of-ycsb] -l\n"
        printf "myycsb.sh clean\n"
}

if [ -z ${1+x} ]
then
	print_help
	exit 1

elif [ "${1}" = "up" ]
then
	shift

	echo "Launch YCSB"

	# Parse arguments
	TEMP_ARGS=`getopt -o n:l --long num-of-ycsb:load  -n "$PROGRAM_NAME" -- "$@"`

	if [ $? != 0 ]
	then
		echo "Error parsing arguments. Try $PROGRAM_NAME up --help"
		exit 1
	fi

	eval set -- "$TEMP_ARGS";		

	while true; do
		case $1 in

			-n|--num-of-ycsb)
				NUM_OF_YCSB="$2"; shift 2; continue
			;;
			-l|--load)
				LOAD="true"; shift 1; continue
			;;
			--)
				break
			;;
			*)
				printf "Unknow option %s\n" "$1"
				print_help
				exit 1
			;;
		esac
	done

	# Set default values if they are not specified in input. 
	if [ -z ${NUM_OF_YCSB+x} ]
	then
		NUM_OF_YCSB=${NUM_OF_YCSB_DEFAULT}
	fi

	#Prepare YCSB 
	if [ ! -d ${TEMP_DIR} ]
	then
		mkdir ${TEMP_DIR}
	fi

	for (( i=1; i <= ${NUM_OF_YCSB}; i++ ))
	do
		cp -rf ${YCSB_DIR} ${TEMP_DIR}/YCSB_${i}
	done

	if [ ! -d ${YCSB_LOG_DIR} ]
	then
		mkdir ${YCSB_LOG_DIR}
	fi

	#Start YCSB
	for (( i=1; i <= ${NUM_OF_YCSB}; i++  ))
	do
		cd ${TEMP_DIR}/YCSB_${i}

		#load data is only needed for the first one.
		if [ "${LOAD}" = "true" ]
		then
			if [ $i = 1 ]
			then
				./bin/ycsb load tair -P ./workloads/${YCSB_WORKLOAD_TYPE} -P ${YCSB_DATA} -s > ${YCSB_LOG_DIR}/load_${i}.dat
			fi
		fi

		./bin/ycsb run tair -P ./workloads/${YCSB_WORKLOAD_TYPE} -P ${YCSB_DATA} -s > ${YCSB_LOG_DIR}/transactions_${i}.dat &
	done

elif [ ${1} = "clean" ]
then
	echo "Stop YCSB"
	if [ -x /usr/bin/killall  ]
	then
		killall java
	else
		printf "Command killall is needed.\n"
		exit 1
	fi

	#Remove all tair_bin of config server and data server

	if [ -d ${TEMP_DIR} ]
	then
		find ${TEMP_DIR}/ -type d -regex ".*YCSB_[0-9]+" -exec rm -rf {} +
		rm -rf ${TEMP_DIR}
	fi
else
	print_help
	exit 1
fi
exit 0

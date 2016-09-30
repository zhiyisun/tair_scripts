#!/bin/bash -
#===============================================================================
#
#          FILE: mytair.sh
# 
#         USAGE: ./mytair.sh 
# 
#   DESCRIPTION: This script is used to launch/stop tair config/data server
#                on single phisical server for benchmark purpose.
# 
#       OPTIONS: up/down
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Zhiyi Sun (zsun), zhiyisun@msn.com
#  ORGANIZATION: 
#       CREATED: 09/20/2016 08:59:44 AM
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

PROGRAM_NAME="mytair.sh"
TAIR_DIR_DEFAULT=/home/zsun/workspace/code/tair
DEV_NAME_DEFAULT="xgbe0"
NUM_OF_SVR_DEFAULT="1"
PROCESS_THREAD_NUM_DEFAULT="1"
DATA_SERVER_PORT=5290


function print_help()
{
	printf "mytair.sh up -i <dev name> -s <num of servers> -t <process thread num>\n"
        printf "mytair.sh down\n"
}

function prepare_config_server()
{
	cp -rf ${TAIR_BIN} ${TAIR_BIN_CS}

	CS_CONF=${TAIR_BIN_CS}/etc/configserver.conf
	cp ${CS_CONF}.default ${CS_CONF}

	#Remove 2nd config server, in this test, we only use single config server.
	sed -i "/config_server=192\.168\.1\.2:5198/d" ${CS_CONF}

	#Replace config server ip addr
	sed -i "s/192\.168\.1\.1/${IPADDR}/g" ${CS_CONF}

	#Replace dev name
	sed -i "s/eth0/${DEV_NAME}/g" ${CS_CONF}


	GROUP_CONF=${TAIR_BIN_CS}/etc/group.conf
	cp ${GROUP_CONF}.default ${GROUP_CONF}

	#Remove comments of server list
	sed -i "/# data center .*/d" ${GROUP_CONF}

	#Remove all server list first
	sed -i "/_server_list=.*/d" ${GROUP_CONF}

	#Add server list
	echo "" >> ${GROUP_CONF}
	echo "# data center" >> ${GROUP_CONF}
	for (( i=1; i <= ${NUM_OF_SVR}; i++  ))
	do
		echo "_server_list=${IPADDR}:$((${DATA_SERVER_PORT}+${i}))" >> ${GROUP_CONF}
	done
}

function prepare_data_server()
{
	TAIR_BIN_DS_TEMP=${TAIR_BIN_DS}_$1
	cp -rf ${TAIR_BIN} ${TAIR_BIN_DS_TEMP}

	DS_CONF=${TAIR_BIN_DS_TEMP}/etc/dataserver.conf
	cp ${DS_CONF}.default ${DS_CONF}

	#Remove 2nd config server, in this test, we only use single config server.
	sed -i "/config_server=192\.168\.1\.2:5198/d" ${DS_CONF}

	#Replace config server ip addr
	sed -i "s/192\.168\.1\.1/${IPADDR}/g" ${DS_CONF}

	#Replace port number
	sed -i "s/5191/$((${DATA_SERVER_PORT}+${i}))/g" ${DS_CONF}
	sed -i "s/6191/$((${DATA_SERVER_PORT}+${i}+1000))/g" ${DS_CONF}

	#Replace process thread num
	sed -i "s/process_thread_num=.*/process_thread_num=${PROCESS_THREAD_NUM}/g" ${DS_CONF}

	#Replace dev name
	sed -i "s/eth0/${DEV_NAME}/g" ${DS_CONF}

	#Replace mdb shm path
	sed -i "s/mdb_shm_path0/mdb_shm_path$1/g" ${DS_CONF}
}


# Check if $TAIR_DIR is set, this is the base directory in which tair source code
#and binary are located. If not set, set the default one defined in this script.
if [ -z ${TAIR_DIR+x} ]
then
	TAIR_DIR=${TAIR_DIR_DEFAULT}
fi

if [ ! -d ${TAIR_DIR} ]
then
	printf "Tair folder is not exist.\n"
	exit 1
fi

TAIR_BIN_CS=${TAIR_DIR}/tair_bin_cs
TAIR_BIN_DS=${TAIR_DIR}/tair_bin_ds

# This is the directory which tair binary package is installed.
if [ -z ${TAIR_BIN+x} ]
then
	TAIR_BIN=${TAIR_DIR}/tair_bin
fi

if [ ! -d ${TAIR_DIR} ]
then
	printf "Tair binary folder is not exist. Please build tair first.\n"
	exit 1
fi

if [ -z ${NUM_OF_SVR+x} ]
then
	NUM_OF_SVR=${NUM_OF_SVR_DEFAULT}
fi

if [ -z ${1+x} ]
then
	print_help
	exit 1

elif [ "${1}" = "up" ]
then
	shift

	echo "Launch tair server(s)"

	# Parse arguments
	TEMP_ARGS=`getopt -o i:s:t: --long interface:,num-of-server:,process-thread-num:  -n "$PROGRAM_NAME" -- "$@"`

	if [ $? != 0  ]
	then
		echo "Error parsing arguments. Try $PROGRAM_NAME up --help"
		exit 1
	fi

	eval set -- "$TEMP_ARGS";		

	while true; do
		case $1 in

			-i|--interface)
				DEV_NAME="$2"; shift 2; continue
			;;
			-s|--num-of-server)
				NUM_OF_SVR="$2"; shift 2; continue
			;;
			-t|--process-thread-num)
				PROCESS_THREAD_NUM="$2"; shift 2; continue
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
	if [ -z ${DEV_NAME+x} ]
	then
		DEV_NAME=${DEV_NAME_DEFAULT}
	fi

	if [ -z ${PROCESS_THREAD_NUM+x} ]
	then
		PROCESS_THREAD_NUM=${PROCESS_THREAD_NUM_DEFAULT}
	fi

	# Get IP address of server, in this test, config server and data
	# server are running on the same single physical server
	IPADDR=$(ifconfig ${DEV_NAME} | sed -n "s/.*inet \(addr:\)\?\([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\).*/\2/p")

	#Prepare config server congig files
	prepare_config_server

	#Prepare data server config file
	for (( i=1; i <= ${NUM_OF_SVR}; i++  ))
	do
		prepare_data_server ${i}
	done

	#set shm
	cd ${TAIR_BIN_CS}
	sudo ./set_shm.sh

	#Start all data server
	for (( i=1; i <= ${NUM_OF_SVR}; i++  ))
	do
		cd ${TAIR_BIN_DS}_${i}
		./tair.sh start_ds
	done

	#Start config server
	cd ${TAIR_BIN_CS}
	./tair.sh start_cs

elif [ ${1} = "down" ]
then
	echo "Stop tair server(s)"
	if [ -x /usr/bin/killall  ]
	then
		killall tair_server tair_cfg_svr
	else
		printf "Command killall is needed.\n"
		exit 1
	fi

	#Remove all tair_bin of config server and data server
	rm -rf ${TAIR_BIN_CS}
	find ${TAIR_DIR} -type d -regex ".*tair_bin_[cd]s\(_[0-9]+\)?" -exec rm -rf {} +

else
	print_help
	exit 1
fi
exit 0

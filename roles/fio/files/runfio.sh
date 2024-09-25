#!/bin/bash
declare -A args

#read all args in key value pairs
for arg in "$@"; do
    # Check if the argument contains an equal sign
    if [[ "$arg" == *"="* ]]; then
        # Split the argument into key and value
        key=${arg%%=*}
        value=${arg#*=}
        # Store the key-value pair in the associative array
        args["$key"]="$value"
    else
        echo "Invalid argument: $arg (should be in key=value format)"
    fi
done

FIO_CMD="fio"
DEVICE=${args["DEVICE"]}
MOUNT=${args["MOUNT"]}
TIME=${args["TIME"]}

if [[ -v args["NUMJOBS"] ]]; then
	NUMJOBS=${args["NUMJOBS"]}
else 
	NUMJOBS=1
fi 

if [[ -v args["SIZE"] ]]; then
	SIZE=${args["SIZE"]}
else 
	SIZE="1G"
fi 

echo ${args["TYPE"]} $DEVICE $MOUNT $TIME $NUMJOBS

FIO_ARGS="--group_reporting --direct=1 --ioengine=libaio"

if [[ -v args["TIME"] ]]; then
	FIO_ARGS="$FIO_ARGS --time_based --runtime=$TIME"
fi
if [[ ${args["TYPE"]} == "BLOCK" ]]; then
	FIO_ARGS="$FIO_ARGS --name=seq_write_test --filename=$DEVICE --rw=write --bs=1M --numjobs=$NUMJOBS"
elif [[ ${args["TYPE"]} == "FILE" ]]; then
	FIO_ARGS="$FIO_ARGS --name=nfs_test --directory=$MOUNT --rw=randwrite --bs=4k --size=$SIZE --numjobs=$NUMJOBS"
else 
	echo "Invalid Arguments"
	exit 1
fi

echo Running: $FIO_CMD $FIO_ARGS

$FIO_CMD $FIO_ARGS

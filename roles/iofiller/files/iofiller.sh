#!/bin/bash
declare -A args

#read all args in key value pairs
for arg in "$@"; do
    if [[ "$arg" == *"="* ]]; then
        key=${arg%%=*}
		key=${key#*--}
        value=${arg#*=}
        args["$key"]="$value"
    else
        echo "Invalid argument: $arg (should be in key=value format)"
		exit 1
    fi
done

if ! [[ -v args["treshold"]  &&  -v args["size"]   &&  -v args["max-capacity"] ]]; then
	echo " Usage:"
	echo "	$0 --treshold=<num> --size=<file_size_in_MB> --max-capacity=<size_in_MB> [--delete-percentage num]"
	echo " where:"
	echo "	threshold:  Time in seconds to sleep before moving to next file"
	echo "	size: size of the file to write to before moving to next file"
	echo "	max-capacity:  maximum capacity it can write before deleting the files"
	echo "	delete-percentage: [optional] percentage of files to delete on reaching max-capacity, default=70"
	exit 1
fi

treshold=${args["treshold"]}
filesize=${args["size"]}
max_capacity=${args["max-capacity"]}


working_dir="/data"
filename="datafile"
percentage=7

if [[ -v  args["max-capacity"] ]]; then
	percentage=`expr ${args["delete-percentage"]} / 10`
fi

COUNT=0
cd $working_dir

while true; do
	COUNT=`expr $COUNT + 1`
	echo "creating $filename$COUNT of ${filesize}MB"
	dd if=/dev/random of=$working_dir/$filename$COUNT bs=1M count=$filesize status=progress > /dev/null 2>&1
	
	USAGE=`du -csh $working_dir --block-size=1M  | grep total |  awk '{print $1}'`
	
	if [ $USAGE -gt $max_capacity ]; then
		to_delete=`expr \`ls -1 ${working_dir}/${filename}* | wc -l\` \* ${percentage} / 10`
		echo "reached max-capacity: ${max_capacity}MB. Deleting ${to_delete} files..."
		delete_count=0
		for file in `ls -1tr $working_dir/$filename*`; do
			delete_count=`expr $delete_count + 1`
			if [ $delete_count -gt $to_delete ]; then
				break
			fi
			rm -f $file
		done
	fi
	sleep $treshold
done

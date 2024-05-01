#!/bin/bash

USEDFLAGS="$@"
green="\033[01;32m"
red="\033[0;31m"
blue="\033[01;34m"

# set default values of some variables here
FILENAME="default-file.lst"
HOSTNAME="remote.de"
DEST="/local/destination/dir/"
USERNAME="username"
NPROC="$[$(nproc)-1]"
SOURCE=""
LOGFILE="default-file.log"
COMMAND=""
COMMAND2=""

# careful when changing these ones, since they cannot be adjusted via options afterwards!
JUMP=false
NSKIP=0
MAXINT=100000000000000 # this is just a verly large integer
NFILES=$MAXINT
TEST=false
UPDATE="--update"
REPLACE="off"
JUSTCHECK=false
INVERTDIRECTION=false
FSTRING=""

# read in options
while [ -n "$1" ]
do
  case "$1" in
  -f) FILENAME="$2"
      shift
      ;;
  -f2) FSTRING="$2"
      FILENAME="temp-filelist.lst"
      shift
      ;;
  -d) DEST="$2"
      shift
      ;;
  -s) SOURCE="$2"
      shift
      ;;
  -u) USERNAME="$2"
      shift
      ;;
  -H) HOSTNAME="$2"
	  shift 
	  ;;
  -C) COMMAND="$2"
      shift 
	  ;;
  -C2) COMMAND2="$2"
	  shift
	  ;;
  -N) NFILES="$2"
      shift
      ;;
  -S) NSKIP="$2"
      shift
	  ;;
  -p) NPROC="$2"
      shift
      ;;
  -L) LOGFILE="$2"
      shift
      ;;
  -r) REPLACE="on"
      ;;
  -c) JUSTCHECK=true
      ;;
  -i) INVERTDIRECTION=true
      ;;
  -t) TEST=true
      ;;
  -y) JUMP=true
      ;;
  -h) echo "--------------------------------------------------------------------------------"
      echo "Help for copy-cta-to-mnt.sh"
	  echo "--------------------------------------------------------------------------------"
	  echo "Tipps:"
	  echo "put -h at the end to see the current value of the provided options)"
	  echo "adjust default values for options in the .sh file at the top"
      echo "--------------------------------------------------------------------------------"
	  # the $(tput sgr0) resets the color to what it was before
      echo -e "-f FILENAME  : set file with commands to run in parallel $green($FILENAME)$(tput sgr0)"
      echo -e "-f2 FSTRING  : create filelist using 'ls \$FSTRING' on host $green($FSTRING)$(tput sgr0)"
      echo "             : you can use wildcards, it will create a temp-file and ignore -f"
      echo -e "-d DEST      : local location to copy files to $green($DEST)$(tput sgr0)"
      echo -e "-s SOURCE    : remote location to copy files from $green($SOURCE)$(tput sgr0),"
      echo "             : leave empty if absolute path is given in FILENAME"
      echo -e "-u USERNAME  : username to use on remote location $green($USERNAME)$(tput sgr0)"
      echo -e "-H HOSTNAME  : host name of remote location $green($HOSTNAME)$(tput sgr0)"
      echo -e "-C COMMAND   : command to be executed on host location before the copy $green($COMMAND)$(tput sgr0),"
	  echo "             : if you put it in single quotes('...'), you can use bash variables"
	  echo "             : (e.g. 'rm \$filename') that you create in the \"copy_one\" function"
      echo -e "-C2 COMMAND2 : command to be executed on host location after the copy $green($COMMAND)$(tput sgr0),"
	  echo "             : if you put it in single quotes('...'), you can use bash variables"
	  echo "             : (e.g. 'rm \$filename') that you create in the \"copy_one\" function"
      if [[ $NFILES == $MAXINT ]]
	  then 
	      echo -e "-N NFILES    : number of files from FILENAME to copy to DEST $green(all)$(tput sgr0)"
	  else
	      echo -e "-N NFILES    : number of files from FILENAME to copy to DEST $green($NFILES)$(tput sgr0)"
	  fi
      echo -e "-S NSKIP     : number of files to skip from FILENAME $green($NSKIP)$(tput sgr0)"
      echo -e "-p NPROC     : define number of parallely started processes $green($NPROC)$(tput sgr0)"
      echo -e "-L LOGFILE   : logfile for general problems $green($LOGFILE)$(tput sgr0)"
      echo -e "-r           : use this flag, if you want to replace files at DEST $green($REPLACE)$(tput sgr0)"
      echo -e "-c           : use this flag, if you only want to check file sizes $green(NPROC*4=$[$NPROC*4])$(tput sgr0)"
      echo -e "-i           : invert direction, i.e. copy from local to remote $green($(if [[ $INVERTDIRECTION == 'true' ]]; then echo 'yes'; else echo 'no'; fi;))$(tput sgr0),"
      echo "             : provide '-s SOURCE' to choose the local location of the files,"
      echo "             : always removes absolute paths from given file (keeps relative)!"
      echo -e "-t           : start in test-mode, only echo, no run $green($(if [[ $TEST == 'true' ]]; then echo 'yes'; else echo 'no'; fi;))$(tput sgr0)"
      echo -e "-y           : don't wait for user to check the input $green($(if [[ $JUMP == 'true' ]]; then echo 'yes'; else echo 'no'; fi;))$(tput sgr0)"
      echo "-h           : display this help (tipp: put it always as the last option)"
      echo "--------------------------------------------------------------------------------"
      exit
      ;;
  *)  echo "Option $1 not recognized! Ignored.." ;;
  esac

  shift
done

if [[ "$REPLACE" == "on" ]]
then 	
	UPDATE=""
fi

if [[ $SOURCE != "" ]]
then 
	if [[ ${SOURCE: -1} != "/" ]]
	then 
		SOURCE=$SOURCE/
	fi
fi 


echo "Used flags:
$USEDFLAGS" > $LOGFILE
echo "Used flags:
$USEDFLAGS" > check-$LOGFILE

host="$USERNAME@$HOSTNAME"

if [[ $JUSTCHECK == true ]]
then
	NPROC=$[$NPROC*4]	
fi

read -s -p "Please enter your password (hidden input): " PASSWORD
echo
if [[ "$PASSWORD" == "" ]]
then
	echo -e "${red}ERROR:$(tput sgr0) PASSWORD cannot be empty! Abort..."
	exit 1
fi
echo -e "Try connection to host via ${blue}ssh $USERNAME@$HOSTNAME$(tput sgr0) with provided password..."
connectiontest=$(sshpass -p $PASSWORD ssh -y $host "echo success")

if [[ "$connectiontest" == "success" ]]
then
	echo "Connection to remote location could be established. Continue..."
else
	if [[ "$TEST" == "true" ]]
	then 
		echo -e "${blue}Warning:$(tput sgr0) Password wrong, but since it is only a test, I will continue anyways..."
	else
		echo -e "${red}ERROR:$(tput sgr0) Connection to remote location failed. Probably password wrong?! Abort..."
		exit 1
	fi
fi

if [[ "$FSTRING" != "" ]]
then
  echo "Create temp-filelist.lst from provided FSTRING."
  sshpass -p $PASSWORD ssh -y $host "ls $FSTRING" > temp-filelist.lst
fi


check_one () {
	# see if file exists at the destination
	hostfilename=${SOURCE}$1
	filename=$1
	# if first letter "/", then remove absolute path from filename
	if [[ ${filename:0:1} == "/" ]]
	then 
		filename=$(echo $1 | sed 's,.*/,,')
	fi
	localfilename=${DEST}/$filename
	
	if [[ "$INVERTDIRECTION" == "true" ]]
	then 
		hostfilename=${SOURCE}$filename
		localfilename=${DEST}/$filename
  fi
  
	if [[ $(ls $DEST/$filename 2> /dev/null) ]];
	then
		hostfilesize=$(sshpass -p $PASSWORD ssh -y $host "stat -c %s $hostfilename")
		
		
		localfilesize=$(stat -c %s $localfilename)
		if [[ $hostfilesize == $localfilesize ]]
		then
			echo "SUCCESSFUL: $filename"
		else
			echo "FAILED: $filename"
		fi
	else
	  echo "MISSING: $filename" 
	fi
}



copy_one () {
	par=${SOURCE}$1
	returnvalue=0

	# if first letter "/", then remove absolute path from filename
	filename=$1
	if [[ ${filename:0:1} == "/" ]]
	then 
		filename=$(echo $1 | sed 's,.*/,,')
	fi

	date 

	if [[ "$COMMAND" != "" ]]
	then
		echo "start command before copy: $COMMAND" 
		
		sshpass -p $PASSWORD ssh -y $host "$COMMAND"
		if (( ! $? ))
		then
			echo 
			echo "command before copy successful" 
			echo 
			echo 
		else
			echo 
			echo "command before copy failed"  
			echo 
			echo 
			returnvalue=1
		fi 
	fi

	if [[ "$INVERTDIRECTION" == "true" ]]
	then 
		echo "start rsync -a $UPDATE ${SOURCE}$filename $host:$DEST/$filename"
		sshpass -p $PASSWORD rsync -a $UPDATE ${SOURCE}$filename $host:$DEST/$filename
	else
		echo "start rsync -a $UPDATE $host:${SOURCE}$1 $DEST/$filename"
		sshpass -p $PASSWORD rsync -a $UPDATE $host:${SOURCE}$1 $DEST/$filename
	fi

	if (( ! $? ))
	then
		echo 
		echo "rsync successful" 
		echo 
		echo 
	else
		echo 
		echo "rsync failed"  
		echo 
		echo 
		returnvalue=$[$returnvalue+2]
	fi 

	if [[ "$COMMAND2" != "" ]]
	then
		echo "start command2 after copy: $COMMAND2" 
		sshpass -p $PASSWORD ssh -y $host "$COMMAND2" 
		if (( ! $? ))
		then
			echo 
			echo "command2 after copy successful" 
			echo 
			echo 
		else
			echo 
			echo "command2 after copy failed"  
			echo 
			echo 
			returnvalue=$[$returnvalue+4]
		fi 
	fi
	date

	echo "RETURN: $returnvalue"
	if [[ $returnvalue == 0 ]]
	then 
		echo "SUCCESSFUL: $filename" >> $LOGFILE
	elif [[ $((returnvalue % 2)) == 1 ]]
	then 
		echo "FAILED: command before copy" >> $LOGFILE
	elif [[ $(( (returnvalue / 2) % 2)) == 1 ]]
	then
		echo "FAILED: rsync $filename" >> $LOGFILE
	else 
		echo "FAILED: command after copy" >> $LOGFILE
	fi

	( check_one $par >> check-$LOGFILE 2>&1 ) 

	return $returnvalue

}


#start of loop over files to copy/check

maximal_number_files=$(cat $FILENAME | wc -l)
number_files=$[$maximal_number_files-$NSKIP]

if [[ "$number_files" -ge "$NFILES" ]]
then 
	number_files=$NFILES
fi


commands_done=0
commands_skipped=0


started=0
for par in $(cat $FILENAME)
do
	if [[ "$commands_skipped" -lt "$NSKIP" ]]
	then 
		commands_skipped=$[$commands_skipped+1]
		continue
	fi
	
	if [[ "$commands_done" -ge "$number_files" ]]
	then 
		echo "no more files to copy"
		break
	else 
		commands_done=$[$commands_done+1]
	fi

	while (( $(jobs -l | grep "Running" | wc -l) == $NPROC ))
	do # check if a job finished
		if [[ $TEST == true ]] || [[ $JUSTCHECK == true ]]
		then
			sleep 0.1
		fi
	done 

	filename=$(echo $par | sed 's,.*/,,')
	logname="copy-${filename%.*}.log"
	copylog=$DEST/$logname
	started=$[$started+1]

	if [[ $JUSTCHECK == false ]]
	then
		if [[ -f $DEST/$filename && $UPDATE != "" ]]
		then 
			echo "SKIPPED: $filename" >> $LOGFILE
			continue
		fi
	
		if [[ $TEST == true ]]
		then
			echo "copy_one $par > $copylog 2>&1"
			echo "TEST: $filename" >> $LOGFILE
			sleep 0.2 &
		else 
			( copy_one $par > $copylog 2>&1 ) &
		fi
	else
		if [[ $TEST == true ]]
		then
			echo "check_one $par >> check-$LOGFILE 2>&1"
			sleep 0.2 &
		else
			( check_one $par >> check-$LOGFILE 2>&1 ) &
		fi
	fi
	echo "started job $started/$number_files"
done

# wait for remaining ones
while (( $(jobs -l | grep "Running" | wc -l) != 0 ))
do # check every second if remaing jobs are done
	echo "$(jobs -l | grep Running | wc -l) jobs still running"
	sleep 2
done 

echo "DONE"
echo
echo "--------------------------------------------"
echo "CHECK REPORT:"
echo "--------------------------------------------"
echo "Size check passed:"
cat check-$LOGFILE | grep SUCCESSFUL | wc -l
echo "Size check failed:"
cat check-$LOGFILE | grep FAILED | wc -l
echo "Files missing:"
cat check-$LOGFILE | grep MISSING | wc -l

rm -f temp-filelist.lst

echo "Consult 'check-$LOGFILE' for the ones that failed. Remove them and start the process again."
echo "(This will also take care of the missing ones.)"


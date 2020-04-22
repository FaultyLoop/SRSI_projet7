#!/usr/bin/env bash

#CONFIG - DEFAULT
LOG_STDERR=2            #Stderr
LOG_STDOUT=1            #Stdout
VERBOSE_LV=0            #Verbose Level
TIMEOUT=3				#3 second timeout
VERSION=1				#Block Version
MAX_SERVER=3			#Max fragment server
IPCHAIN="127.0.0.1;"		#Ip of file server
SELECT_MODE=0			#Enable choice
WORK_SPACE=`realpath .` #Sctipt Workplace (default .)
UNWANTED=

#CONFIG - CONSTANT
LOG_MODEDV=vars         #Log Modifier Var Values
LOG_MODELL=last         #Log Modifier Last Log
LOG_MODENV=ntvr         #Log Modifier Not a Var
LOG_MODESL=same         #Log Modifier Same Line (\r)
LOG_STADBG=debug        #Log Status Debug
LOG_STAERR=error        #Log Status Error
LOG_STAINF=info         #Log Status Info
LOG_STAWRN=warn         #Log Status Warn
LOG_STASET=vset         #Log Status Set

#INTERRUPTS

#MAIN   - FUNCTION

log(){
  out=$LOG_STDOUT
  headformat=$1
  execformat=""
  tailformat="\n\r";
  case "$1" in
    $LOG_STADBG) headformat="\033[33m$headformat";;
    $LOG_STAERR) headformat="\033[31m$headformat"; out=$LOG_STDERR;;
    $LOG_STAINF) headformat="\033[36m$headformat";;
    $LOG_STAWRN) headformat="\033[31m$headformat";;
    *)           headformat="\033[32m$headformat";;
  esac
  lvl=$1
  msg=$2
  if [[ -z $msg ]];then return ;fi
  shift 2

  if [[ $msg =~ " " ]];then val= ;else val="${!msg}";execformat="\033[32m";fi

  while (( "$#" ));do
    case "$1" in
        $LOG_MODESL) tailformat="\r" ;;
        $LOG_MODESZ) val=$(formatsize $val) ;;
    esac
    shift 1
  done
  
  case "$VERBOSE_LV" in
    0) if [[ $lvl ]];then return ;fi;;
	1|2|3) if ! [[ "$LOG_STAINF,$LOG_STAWRN,$LOG_STAERR" =~ $lvl ]];then return ;fi;;
	4|5|6) if ! [[ "$LOG_STAINF,$LOG_STAWRN,$LOG_STAERR,$LOG_STADBG" =~ $lvl ]];then return ;fi;;
	7|8|9) ;;
  esac

  printf "$headformat \033[39m$msg $execformat$val \033[39m$tailformat"
}

main(){
	log $LOG_STASET TIMEOUT
	log $LOG_STAINF "Preparing Files"
	for fs in $(ls $WORK_SPACE -R);do
		fs=$(echo $fs | sed "s/:/\n/g")
		if [[ -d $fs ]];then DIR=$fs;
		elif [[ -f "$DIR/$fs" ]];then FILES="$FILES;$DIR/$fs";fi
	done
	sendchain $FILES
}

serverchoice(){
	servercount=$([[ $FILE_SERVER ]] && echo $FILE_SERVER | wc -l || echo 0)
	log $LOG_STAINF "$servercount File server set"
	if [[ $servercount -le $MAX_SERVER ]];then COUNT=$servercount
	else COUNT=$MAX_SERVER;fi
	
	if [[ COUNT -eq 0 ]];then
		log $LOG_STAERR "No file server set, fatal error"
		exit -2
	fi
	
	for i in $(seq 1 $COUNT);do
		select=
		while [[ -z $select ]];do
			choice=$(($RANDOM % $MAX_SERVER))
			choice=${FILE_SERVER[$choice]}
			if ! [[ $list =~ $choice ]];then 
				select=$choice;
				log $LOG_STAINF "Selecting File Server : $choice"
			fi
		done
		list="$select;$list"
	done
	echo $list
}

sendchain(){
	LIST=$([[ $2 ]] && echo $2 || echo $IPCHAIN)
	for uwt in $UNWANTED;do LIST=$(echo $LIST | sed "s/$uwt//g");done
	
	if [[ -z $LIST ]];then 
		log $LOG_STAERR "Nothing in ip list, check server availability"
		exit -3
	fi
	
	FILES=$(echo $FILES | sed "s/;/ /g")
	MSGLIST=
	for ip in $LIST;do
		scp -o ConnectTimeout=$TIMEOUT $FILES -q srsi7@$ip:/home/srsi7/files
		if [[ $? -ne 0 ]];then
			log $LOG_STAERR "Failed to share file $1 with $ip"
			UNWANTED="$ip $UNWANTED"
		else
			MESSAGE=$(echo "./chaincheck --last-block" | ssh -o ConnectTimeout=$TIMEOUT $ip)
		fi
	done
	for file in $FILES;do
		md5=$(md5sum $1 | cut -d " " -f1)
		msgsum=$(echo $MESSAGE | md5sum | cut -d " " -f 1)
		MESSAGE='{"MD5":$md5,"filename":$file,"version":$VERSION,"sum":$mgsum}'
		for ip in $LIST;then
			log $LOG_STAINF "Sending Block"
			valid=$(echo "echo $MESSAGE | ./chaincheck.sh --check" | ssh -o ConnectTimeout=$TIMEOUT $ip)
			if [[ $valid = "OK" ]];then log $LOG_STAINF "Block validated by server ($ip)";
			else log $LOG_STAERR "Block not validated by server ($ip)";fi
		done
	done
}

#ARGS   - PARSER
while (( "$#" ));do
    case "$1" in
        -h|--help)
            help $2
            exit 0;
        ;;
		--choice)
			SELECT_MODE=$(! [[ $SELECT_MODE -eq 0 ]])
			shift 1
		;;
		-c|--chain-server)
			while [[ ! "$2" =~ "-" ]] && [[ "$2" != "" ]] && [[ "$2" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]];do
                if [[ "$2" =~ "list:" ]];then
                    list=$(echo $2 | cut -d ":" -f2)
                    if [[ -f $list ]];then
                      list=$(cat $list | tr "\000" "\n")
                      for ip in $list;do
                        if [[ $(ssh-keygen -F $ip | grep '#') ]];then
                          if     [[ -z $IPCHAIN ]];then IPCHAIN="$ip;";
                          elif ! [[ $IPCHAIN =~ "$ip;" ]];then IPCHAIN="$IPCHAIN$ip;";
                          else log $LOG_STAERR "$ip Already present in IP list";fi
                        fi
                      done
                    else log $LOG_STAERR "$list : No such file"; fi
                elif [[ $(ssh-keygen -F $2 | grep '#') ]];then
					if     [[ $IPCHAIN = "" ]];then IPCHAIN="$2;";
					elif ! [[ $IPCHAIN =~ "$2;" ]];then IPCHAIN="$IPCHAIN$2;";
					else log $LOG_STAERR "$2 : Already present in IP list";fi
                else log $LOG_STAERR "$2 : Unknown Host"; fi
                shift 1
            done
			IPCHAIN=$(echo $IPCHAIN | sed "s/;/\n/g")
		;;
        -v*|--verbose)
            if [[ "$1" = "--verbose" ]];then
              if [[ $2 =~ '^[0-9]+$' ]];then VERBOSE_LV=$2; else VERBOSE_LV=1;fi
            else VERBOSE_LV=$((${#1}-1));fi
            log $LOG_STASET VERBOSE_LV
            shift 1
        ;;
        *)
			if [[ -d $1 ]];then
				WORK_SPACE=$(realpath $1)
				log $LOG_STASET WORK_SPACE
			fi
			shift 1
    esac
done

if [[ -z $IPCHAIN ]];then 
	log $LOG_STAERR "Chain Server IP Required"
	exit -1
fi

main



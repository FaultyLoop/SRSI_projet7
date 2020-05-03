#!/usr/bin/env bash

#CONFIG - DEFAULT
LOG_STDERR=2            #Stderr
LOG_STDOUT=1            #Stdout
VERBOSE_LV=0            #Verbose Level
TIMEOUT=3				#3 second timeout
VERSION=1				#Block Version
MAX_SERVER=3			#Max fragment server
IPCHAIN=				#Ip of chain server
IPCHAINFILE=./chainip	#Ip list of chain server
SELECT_MODE=0			#Enable choice
WORK_SPACE=`realpath .` #Sctipt Workplace (default .)
USERACCESS=srsi7
IPFILESERVER=
SELECTEDFILESERVER=

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

getiplike(){
	echo $(echo $1 | grep -E -o "((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)")
}

checkserverchain() {
	if [[ -f $IPCHAINFILE ]] && [[ -z $IPCHAIN ]];then
		IPCHAIN=$(echo $IPCHAIN && cat $IPCHAINFILE)
		IPCHAIN=$(getiplike "$IPCHAIN")
	fi
	if [[ -z $IPCHAIN ]];then 
		log $LOG_STAERR "Chain Server IP Required"
		exit -1
	fi

	ipchaincopy=$(echo $IPCHAIN | sed "s/;/ /g")
	IPCHAIN=
	log $STA_INF "$(echo $IPCHAIN | wc -l) Chain server set"
	
	if [[ -w $IPCHAINFILE ]] || ([[ ! -d $IPCHAINFILE ]] && [[ ! -f $IPCHAINFILE ]]);then
		ipcopy=$(cat $IPCHAINFILE | grep -v ^#)
		ipcopy=$(getiplike $ipcopy)
		echo "#IpList file version 1.0" > $IPCHAINFILE
		echo "#Record : $(date)"       >> $IPCHAINFILE
		echo "#Warning : File autogenerated, edit at own risk !" >> $IPCHAINFILE
		echo "#Failed IP : " 		   >> $IPCHAINFILE
		for ip in $ipchaincopy;do
			if [[ $(cat $IPCHAINFILE && echo $IPCHAIN) =~ $ip ]];then 
				log $LOG_STAINF "$ip : Duplicate Host, skipping"
				continue
			fi
			log $LOG_STAINF "$ip : Testing Server Access" $LOG_MODESL
			ssh -oBatchMode=yes -oConnectTimeout=3 -ql $USERACCESS $ip exit 0
			if [[ $? -eq 255 ]];then
				if [[ -z $(ssh-keygen -H -F $ip) ]];then 
					log $LOG_STAINF "$ip : Host not set in ~/.ssh/known_hosts"
					if [[ $ipcopy =~ $ip ]];then log $LOG_STAWRN "$ip : Host failure (removing)"
					else echo "#$ip	UNKOWN_HOST" >> $IPCHAINFILE;fi
				else
					log $LOG_STAINF "$ip : Host is down or not responding"
					if [[ $ipcopy =~ $ip ]];then log $LOG_STAWRN "$ip : Host failure (removing)"
					else echo "#$ip	UNJOINABLE" >> $IPCHAINFILE;fi
				fi
			else 
				log $LOG_STAINF "$ip : Host Responding and valid"
				IPCHAIN=$(echo "$IPCHAIN;$ip")
			fi
		done

	fi
	IPCHAIN=$(echo $IPCHAIN | sed "s/;/ /g")
	echo "#Available at Record time" >> $IPCHAINFILE
	for ip in $IPCHAIN;do echo "$ip	OK" >> $IPCHAINFILE;done
	log $STA_INF "$(echo $IPCHAIN | wc -w) Chain server checkedssh"
}

getfileserver() {
	COUNT=0
	for ip in $IPCHAIN;do
		ipget=$(ssh $USERACCESS@$ip -oConnectTimeout=3 "(./chaincheck.sh --get-fileserver && exit 0) || exit 255")
		if [[ $? -eq 0 ]];then
			log $LOG_STAINF "$(echo $ipget | wc -w) fileserver defined from $ip"
			for ip in $ipget;do 
				if [[ ! $IPFILESERVER =~ $ip ]];then IPFILESERVER=$(echo "$IPFILESERVER;$ip");fi
			done
		else log $LOG_STAERR "Host response invalid";fi
	done
	if [[ -z $IPFILESERVER ]];then
		log $LOG_STAERR "fatal : no fileserver defined"
		exit -3
	fi
	IPFILESERVER=$(echo $IPFILESERVER | sed "s/;/ /g")
	IPFILESERVER=($IPFILESERVER)
}

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
	if [[ ! -f $WORK_SPACE/index ]];then log $LOG_STAERR "No index found";exit -1;fi
	if [[ ! -f ./chainip ]];then checkserverchain ;fi
	IPCHAIN=$(echo $IPCHAIN && cat $IPCHAINFILE | grep -v ^#)
	IPCHAIN=$(getiplike "$IPCHAIN")
	
	if [[ -z $IPCHAIN ]];then log $LOG_STAERR "fatal : No Chainserver ip defined";exit -1;fi
	
	getfileserver
	
	cd $WORK_SPACE
	FILES=($(tail -n +2 index | cut -d ";" -f 1))
	log $LOG_STAINF "Index give ${#FILES[@]} Files ($(du $WORK_SPACE/ -lh | cut -d$'\t' -f1))"
	INDEXMD5=$(md5sum index | cut -d' ' -f1)
	
	if [[ SELECT_MODE -eq 1 ]];then serverchoice;fi
	log $LOG_STAINF "${#IPFILESERVER[@]} fileserver selected";
	
	for index in "${!FILES[@]}";do
		if [[ SELECT_MODE -eq 1 ]];then SERVERLIST=(serverchoice)
		else SERVERLIST=$IPFILESERVER;fi
		
		for ip in ${SERVERLIST[@]};do
			if [[ $(ssh $USERACCESS@$ip "[[ -f ~/files/${FILES[$index]} ]] && echo 0 || echo 1") -eq 0 ]];then
				log $LOG_STAINF "Sending File $(($index+1))/${#FILES[@]}, ignored " $LOG_MODESL
			else
				scp -q ./${FILES[$index]} $USERACCESS@$ip:~/files/${FILES[$index]}
				log $LOG_STAINF "Sending File $(($index+1))/${#FILES[@]}, uploaded" $LOG_MODESL
			fi
		done
	done
	log $LOG_STAINF "Sending File $(($index+1))/${#FILES[@]}, done    "
	MD5INDEX=$(md5sum $WORK_SPACE/index | cut -d" " -f 1)
	
	log $LOG_STAINF "Seeding Index"
	for ip in $IPCHAIN;do scp -q $WORK_SPACE/index $USERACCESS@$ip:~/indexs/$MD5INDEX;done
	
	log $LOG_STAINF "Checking Blocks"
	for index in "${!FILES[@]}";do
		for ip in $IPCHAIN;do
			ssh $USERACCESS@$ip "./chaincheck.sh --check-block ${FILES[$index]} --source $MD5INDEX --hash $(md5sum ${FILES[$index]} | cut -d ' ' -f1)"
			case "$?" in
				0) log $LOG_STAINF "Block ${FILES[$index]} Verfified";;
				2) log $LOG_STAERR "Block ${FILES[$index]} Missing from index";;
				4|5|6) log $LOG_STAERR "Block ${FILES[$index]} Missing block";;
				7) log $LOG_STAERR "Block ${FILES[$index]} Cannot be identified";;
				255) log $LOG_STAERR "SSH ERROR : Connection Failed";;
				*) log $LOG_STAERR "Undefined Error : $?";;
			esac
		done
	done
	log $LOG_STAINF "Script completed !"
}

serverchoice(){
	TOTAL=$(echo "${#IPFILESERVER[@]}")
	if [[ $TOTAL -eq 0 ]];then
		log $LOG_STAERR "No file server set, fatal error"
		exit -2
	fi
	if [[ $TOTAL -lt $MAX_SERVER ]];then echo ${IPFILESERVER[@]};
	else
		for i in $(seq 1 $MAX_SERVER);do
			select=
			while [[ -z $select ]];do
				choice=$(($RANDOM % $TOTAL))
				choice=${IPFILESERVER[$choice]}
				if ! [[ $selected =~ $choice ]];then select=$choice;fi
			done
			selected="$select;$selected"
		done
		selected=$(echo $selected | sed "s/;/ /g")
		echo $selected
	fi
}

#ARGS   - PARSER
while (( "$#" ));do
    case "$1" in
        -h|--help)
            help $2
            exit 0;
        ;;
		--choice)
			SELECT_MODE=$([[ $SELECT_MODE -eq 0 ]] && echo 1 || echo 0)
			if [[ $2 =~ ^[0-9]+$ ]] && [[ $2 -gt 0 ]];then MAX_SERVER=$2;fi
            log $LOG_STASET SELECT_MODE
			log $LOG_STASET MAX_SERVER
			shift 1
		;;
		--chain-server-list)
			if [[ -f $2 ]];then IPCHAINFILE=$2;fi
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
		--make-list)
			checkserverchain
			log $LOG_STAINF "Chain list : Done"
			exit 0
		;;
		-u|--user)
			USERACCESS=$2
			shift 1
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

main



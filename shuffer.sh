#!/usr/bin/env bash
VERSION="1.1"
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
LOG_MODEAR=array		#Log Modifier Array
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

main(){
	if [[ ! -f $WORK_SPACE/index ]];then log $LOG_STAERR "No index found";exit -1;fi
	if [[ ! -f $IPCHAINFILE ]] && [[ ${#IPCHAIN[@]} -eq 0 ]];then log $LOG_STAERR "Invalid chainserver list";exit -1;fi
	if [[ ${#IPCHAIN[@]} -eq 1 ]] && [[ -z ${IPCHAIN[0]} ]];then 
		IPCHAIN=($(getiplike "$(cat $IPCHAINFILE | grep -v ^#)"))
		if [[ ${#IPCHAIN[@]} -eq 1 ]] && [[ -z ${IPCHAIN[0]} ]];then log $LOG_STAERR "fatal : No chainserver ip defined";exit -1;fi
	fi
	
	getfileserver
	
	cd $WORK_SPACE
	FILES=($(tail -n +2 index | cut -d ";" -f1))
	INDEXMD5=$(md5sum index | cut -d' ' -f1)
	log $LOG_STAINF "Index give ${#FILES[@]} Files ($(du $WORK_SPACE/ -lh | cut -d$'\t' -f1))"
	log $LOG_STAINF "Index hash is $INDEXMD5"
	
	if [[ SELECT_MODE -eq 1 ]];then serverchoice;fi
	log $LOG_STAINF "${#IPFILESERVER[@]} fileserver selected";
	
	for index in "${!FILES[@]}";do
		if [[ SELECT_MODE -eq 1 ]];then SERVERLIST=(serverchoice)
		else SERVERLIST=$IPFILESERVER;fi
		
		for IPCOPY in ${SERVERLIST[@]};do
			if [[ -z $(echo $IPCOPY | grep .*@ -o) ]];then IPCOPY="$USERACCESS@IPCOPY";fi
			if [[ $(ssh $IPCOPY "[[ -f ./files/${FILES[$index]} ]] && echo 0 || echo 1") -eq 0 ]];then
				IGNORED="$IGNORED${FILES[$index]};"
				log $LOG_STAINF "Sending File $(($index+1))/${#FILES[@]}, ignored " $LOG_MODESL
			else
				scp -q ./${FILES[$index]} $IPCOPY:~/files/${FILES[$index]}
				log $LOG_STAINF "Sending File $(($index+1))/${#FILES[@]}, uploaded" $LOG_MODESL
			fi
		done
	done
	log $LOG_STAINF "Sending File $(($index+1))/${#FILES[@]}, done    "
	MD5INDEX=$(md5sum $WORK_SPACE/index | cut -d" " -f 1)
	
	log $LOG_STAINF "Seeding Index"
	for IPCOPY in $IPCHAIN;do scp -q $WORK_SPACE/index $IPCOPY:~/chaindb/indexs/$MD5INDEX ; done
	
	log $LOG_STAINF "Checking Blocks"
	for index in "${!FILES[@]}";do
		if [[ $IGNORED =~ "${FILES[$index]}" ]];then log $LOG_STAWRN "File was ignored, skipping"
		elif [[ "${!FILES[@]}" = $MD5INDEX ]];then
			log $LOG_STADBG "Index Check not needed"
		else checkblock $index; fi
	done
	log $LOG_STAINF "Script completed !"
}

getiplike(){
	#Support <username>@<ip>
	echo $(echo $1 | grep -E -o "([a-zA-Z0-9_]*@)?((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)")
}

checkserverchain() {
	if [[ -f $IPCHAINFILE ]] && [[ -z $IPCHAIN ]];then
		IPCHAIN=$(cat $IPCHAINFILE | grep -v '#')
		IPCHAIN=($(getiplike "$IPCHAIN"))
	fi
	if [[ -z $IPCHAIN ]];then 
		log $LOG_STAERR "Chain Server IP Required"
		exit -1
	fi
	log $LOG_STAINF "${#IPCHAIN[@]} chainserver defined"

	IPCHAINCOPY=($(echo ${IPCHAIN[@]}))
	IPCHAIN=()
	
	echo "#IpList file version 1.0"	 > $IPCHAINFILE
	echo "#Record : $(date)"      	>> $IPCHAINFILE
	echo "#Failed IP" 				>> $IPCHAINFILE
	
	for IPCOPY in ${IPCHAINCOPY[@]};do
		USER=$(echo $IPCOPY | grep .*@ -o | cut -d "@" -f1)
		USER=$([[ $USER ]] && echo $USER || echo $USERACCESS)
		IPCOPY=$(echo $IPCOPY | sed s/$USER@//g)
		
		if [[ -f $IPCHAINFILE ]] && [[ $(cat $IPCHAINFILE && echo $IPCHAIN) =~ "$USER@$IPCOPY" ]];then 
			log $LOG_STAWRN "$USER@$IPCOPY : Duplicate Host, skipping"
			continue
		fi
		
		log $LOG_STAINF "$USER@$IPCOPY Server Access : " $LOG_MODESL
		ssh -oBatchMode=yes -oConnectTimeout=3 -ql $USER $IPCOPY exit 0
		if [[ $? -eq 255 ]];then
			if [[ $(ls /bin/nc) ]];then
				nc -w 1 -z $IPCOPY 22 
				if [[ $? -eq 0 ]];then echo "#$USER@$IPCOPY	UNKOWN_HOST(CONFIG_ERROR)" >> $IPCHAINFILE
				else echo "#$USER@$IPCOPY	UNJOINABLE(NETWORK_ERROR)" >> $IPCHAINFILE;fi
			elif [[ -z $(ssh-keygen -H -F $IPCOPY) ]];then 
				log $LOG_STAINF "$IPCOPY : Host not set in ~/.ssh/known_hosts"
				echo "#$USER@$IPCOPY	UNKOWN_HOST(CONFIG_ERROR)" >> $IPCHAINFILE
			else
				log $LOG_STAINF "$IPCOPY : Host is down or not responding"
				echo "#$USER@$IPCOPY	UNJOINABLE(LOGIN_ERROR)" >> $IPCHAINFILE
			fi
			log $LOG_STAWRN "$USER@$IPCOPY Server Access : Failed"
		else 
			log $LOG_STAINF "$USER@$IPCOPY Server Access : Success"
			IPCHAIN[${#IPCHAIN}]="$USER@$IPCOPY"
		fi
	done
	echo "#Available IP" >> $IPCHAINFILE
	for IPCOPY in ${IPCHAIN[@]};do echo "$IPCOPY	OK" >> $IPCHAINFILE;done
}

checkblock(){
	for IPCOPY in $IPCHAIN;do
		ssh $IPCOPY "./chaincheck.sh --verbose $VERBOSE_LV --check-block ${FILES[$1]} --source $MD5INDEX --hash $(md5sum ${FILES[$1]} | cut -d ' ' -f1) "
		case "$?" in
			0) log $LOG_STAINF "Block ${FILES[$1]} Verfified";;
			2) log $LOG_STAERR "Block ${FILES[$1]} Missing from index";;
			4|5|6) log $LOG_STAERR "Block ${FILES[$1]} Missing block";;
			7) log $LOG_STAERR "Block ${FILES[$1]} Cannot be identified";;
			255) log $LOG_STAERR "SSH ERROR : Connection Failed";;
			*) log $LOG_STAERR "Undefined Error : $?";;
		esac
	done
}

getfileserver() {
	COUNT=0
	for IPCOPY in $IPCHAIN;do
		if [[ -z $(echo $IPCOPY | grep -o ".*@") ]];then IPCOPY="$USERACCESS@$IPCOPY";fi
		ipget=$(ssh $IPCOPY -oConnectTimeout=3 "(~/chaincheck.sh --get-fileserver && exit 0) || exit 255")
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
	IPFILESERVER=($(echo $IPFILESERVER | sed "s/;/ /g"))
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
		$LOG_MODEAR) val="Array::$msg($(eval echo \${#${msg}[@]}))" ;;
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
			exit 0
		;;
		--choice)
			SELECT_MODE=$([[ $SELECT_MODE -eq 0 ]] && echo 1 || echo 0)
			if [[ $2 =~ ^[0-9]+$ ]] && [[ $2 -gt 0 ]];then MAX_SERVER=$2;fi
            log $LOG_STASET SELECT_MODE
			log $LOG_STASET MAX_SERVER
		;;
		--servers-max)
			if [[ $2 -gt 0 ]];then MAX_SERVER=$22;fi
			log $LOG_STASET MAX_SERVER
		;;
		--chain-server-list)
			if [[ -f $2 ]];then IPCHAINFILE=$2;fi
			log $LOG_STASET IPCHAINFILE $LOG_MODEAR
		;;
		-c|--chain-server)
			while [[ ! "$2" =~ "-" ]] && [[ "$2" != "" ]] && ([[ $(getiplike $2) ]] || [[ "$2" =~ "list:" ]]);do
                if [[ "$2" =~ "list:" ]];then
                    list=$(echo $2 | cut -d ":" -f2)
                    if [[ -f $list ]];then
						list=($(getiplike "$(cat $list)"))
						for ip in ${list[@]};do
							if     [[ -z $IPCHAIN ]];then IPCHAIN="$ip;";
							elif ! [[ $IPCHAIN =~ "$ip;" ]];then IPCHAIN="$IPCHAIN$ip;";
							else log $LOG_STAERR "$ip Already present in IP list";fi
						done
                    else log $LOG_STAERR "$list : No such file"; fi
				else
					if     [[ $IPCHAIN = "" ]];then IPCHAIN="$2;";
					elif ! [[ $IPCHAIN =~ "$2;" ]];then IPCHAIN="$IPCHAIN$2;";
					else log $LOG_STAERR "$2 : Already present in IP list";fi
				fi
                shift 1
            done
			IPCHAIN=($(echo $IPCHAIN | sed "s/;/ /g"))
			log $LOG_STASET IPCHAIN $LOG_MODEAR
		;;
		-m|--make-list)
			checkserverchain
			log $LOG_STAINF "Chainserver list Generated"
			exit 0
		;;
		-u|--user)
			USERACCESS=$2
			log $LOG_STASET USERACCESS
		;;
        -v*|--verbose)
            if [[ "$1" = "--verbose" ]];then
				if [[ $2 =~ '^[0-9]+$' ]];then VERBOSE_LV=$2; else VERBOSE_LV=1;fi
            else VERBOSE_LV=$((${#1}-1));fi
            log $LOG_STASET VERBOSE_LV
        ;;
        *)
			if [[ -d $1 ]];then
				WORK_SPACE=$(realpath $1)
				log $LOG_STASET WORK_SPACE
			fi
		;;
    esac
	shift 1
done

main



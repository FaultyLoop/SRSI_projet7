#!/usr/bin/env bash

#CONFIG - DEFAULT
ENCRY_MODE=aes256       #Encrypt Mode
FHASH_MODE=md5          #File (splited) Hash (checksum) md5
FHASH_NAME=true         #File (splited) Rename as <hashed-value>
LOG_STDERR=2            #Stderr
LOG_STDOUT=1            #Stdout
VERBOSE_LV=0            #Verbose Level
WORK_SPACE=`realpath .` #Sctipt Workplace (default .)
EXECMODE=			
SOURCE=
HASHVALUE=
#CONFIG - DYNAMIC

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

if [[ ! -d ./chaindb ]];then
	mkdir ./chaindb/
	> ./chaindb/fileserver
	> ./chaindb/chainblock
	chmod 0700 ./chaindb -r
fi

#INTERRUPTS

#MAIN   - FUNCTION

getiplike(){
	echo $(echo $1 | grep -E -o "((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)")
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
	if [[ -z $EXECMODE ]];then exit 4;fi
	case "$EXECMODE" in
		check)
			if [[ -z $SOURCE ]];then 
				log $LOG_STAERR "fatal : no source given"
				exit 2
			elif [[ ! -f ./indexs/$SOURCE ]];then
				log $LOG_STAERR "fatal : invalid source given"
				exit 5
			elif [[ -z $BLOCK ]];then 
				log $LOG_STAERR "fatal : no source given"
				exit 4
			elif [[ -z $(cat indexs/$SOURCE | grep $BLOCK) ]];then
				log $LOG_STAERR "fatal : block not in source"
				exit 6
			fi
			for ip in $(cat ./chaindb/fileserver | grep -v '#' || exit 9);do
				if [[ $ip = "127.0.0.1" ]];then
					locate=local
					log $LOG_STAINF "Testing local node : " $LOG_MODESL
					retcode=$([[ ! -f ./files/$BLOCK ]] && echo 1 || [[ ! $(md5sum ./files/$BLOCK | cut -d ' ' -f1) = $HASHVALUE ]] && echo 2 || echo 0)
				else
					locate=remote
					log $LOG_STAINF "Testing remote node : " $LOG_MODESL
					ssh $USERACCESS@$ip "[[ ! -f ./files/$BLOCK ]] && exit 1 || [[ ! $(md5sum ./files/$BLOCK | cut -d ' ' -f1) = $HASHVALUE ]] && exit 2"
					retcode=$?
				fi
				if   [[ $retcode -eq 0 ]];then log $LOG_STAINF "Testing $locate node : success" ;exit 0
				elif [[ $retcode -eq 1 ]];then log $LOG_STAINF "Testing $locate node : file not found" 
				elif [[ $retcode -eq 2 ]];then log $LOG_STAINF "Testing $locate node : hash failure";fi
			done
			exit 7
		;;
		recover)
			if [[ -z $BLOCK ]];then 
				log $LOG_STAERR "fatal : no source given"
				exit 4
			fi
		;;
	esac
}


#ARGS   - PARSER
while (( "$#" ));do
    case "$1" in
        -h|--help)
            help $2
            exit 0;
        ;;
		--get-fileserver)
			if [[ -f ./chaindb/fileserver ]];then
				LIP=$(ip a | grep "inet " | grep -v "127.0.0.1" | cut -d/ -f 1 | sed s/inet//g | tr -d ' ')
				RET=$(cat ./chaindb/fileserver | grep -v '#')
				if [[ $RET =~ "127.0.0.1" ]];then echo $(echo "$RET $LIP" | sed s/127.0.0.1//g)
				else echo $RET;fi
			else echo > ./chaindb/fileserver ;fi
			exit 0
		;;
		--check-block)
			BLOCK=$2
			if [[ $EXECMODE ]];then
				log $LOG_STAERR "EXECMODE already set to $EXECMODE"
				exit 3
			fi
			EXECMODE=check
			shift 1
		;;
		-r|--recover)
			if [[ $EXECMODE ]];then
				log $LOG_STAERR "EXECMODE already set to $EXECMODE"
				exit 3
			fi
			EXECMODE=recover
			shift 1
		;;
		-h|--hash)
			HASHVALUE=$2
			shift 1
		;;
		-s|--source)
			SOURCE=$2
			shift 1
		;;
        -v*|--verbose)
            if [[ "$1" = "--verbose" ]];then
              if [[ $2 =~ '^[0-9]+$' ]];then VERBOSE_LV=$2; else VERBOSE_LV=1;fi
            else VERBOSE_LV=$((${#1}-1));fi
            log $LOG_STASET VERBOSE_LV
            shift 1
        ;;
        *) shift 1;;
    esac
done

main
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
LISTMODE=
TEMPORAL=
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

if [[ ! -d ~/chaindb ]];then
	mkdir ~/chaindb/indexs/ -p
	> ~/chaindb/fileserver
	> ~/chaindb/chainblock
	chmod 0700 ~/chaindb -r
fi

#INTERRUPTS

#MAIN   - FUNCTION

getiplike(){
	#Support <username>@<ip>
	echo $(echo $1 | grep -E -o "([a-zA-Z0-9_]+@)?((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)")
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
		diagnonitic)
			log $LOG_STAINF "Starting diagnonitic : (WIP)"
			LISTINDEX=$(~/chaindb/indexs/*)
		;;
		check)
			if [[ -z $SOURCE ]];then 
				log $LOG_STAERR "fatal : no source"
				exit 2
			elif [[ ! -f ~/chaindb/indexs/$SOURCE ]];then
				log $LOG_STAERR "fatal : invalid source"
				exit 5
			elif [[ -z $BLOCK ]];then 
				log $LOG_STAERR "fatal : no block"
				exit 4
			elif [[ -z $(cat ~/chaindb/indexs/$SOURCE | grep $BLOCK) ]];then
				log $LOG_STAERR "fatal : block not in source"
				exit 6
			fi
			log $LOG_STAINF "Checking for : $BLOCK in $SOURCE ($HASHVALUE)"
			for ip in $(cat ~/chaindb/fileserver | grep -v '#' || exit 9);do
				if [[ $ip = "127.0.0.1" ]];then
					locate=local
					log $LOG_STAINF "Testing local node : " $LOG_MODESL
					echo $HASHVALUE : $(md5sum ./files/$BLOCK | cut -d ' ' -f1)
					retcode=$([[ ! -f ~/files/$BLOCK ]] && echo 1 || [[ ! $(md5sum ~/files/$BLOCK | cut -d ' ' -f1) = $HASHVALUE ]] && echo 2 || echo 0)
				else
					locate=remote
					log $LOG_STAINF "Testing remote node : " $LOG_MODESL
					ssh $USERACCESS@$ip "[[ ! -f ~/files/$BLOCK ]] && exit 1 || [[ ! $(md5sum ~/files/$BLOCK | cut -d ' ' -f1) = $HASHVALUE ]] && exit 2"
					retcode=$?
				fi
				if   [[ $retcode -eq 0 ]];then log $LOG_STAINF "Testing $locate node : success" ;exit 0
				elif [[ $retcode -eq 1 ]];then log $LOG_STAINF "Testing $locate node : file not found" 
				elif [[ $retcode -eq 2 ]];then log $LOG_STAINF "Testing $locate node : hash failure";fi
			done
			exit 7
		;;
		recover)
			if [[ -z $SOURCE ]];then 
				log $LOG_STAERR "fatal : no source given"
				exit 4
			fi
			if [[ ! -f ~/chaindb/indexs/$SOURCE ]];then
				log $LOG_STAINF "Search by name for $SOURCE"
				SOURCE=$(~/chaincheck.sh --list name recent --name $SOURCE | cut -d " " -f 2)
				if [[ -z $SOURCE ]];then
					log $LOG_STAERR "fatal : invalid source"
					exit 5
				fi
				log $LOG_STAINF "Search by name give $SOURCE"
			fi
			if [[ -z $(cat ~/chaindb/indexs/$SOURCE | grep "####### INDEX ######") ]];then printf "####### INDEX ######\n";fi
			printf "$(cat ~/chaindb/indexs/$SOURCE)\n"
			if [[ -z $(cat ~/chaindb/indexs/$SOURCE | grep "######## END #######") ]];then printf "######## END #######\n";fi
		;;
		list)
			log $LOG_STAINF "Listing refered files : $TARGET"
			OUTPUT=
			for file in ~/chaindb/indexs/*;do
				if [[ ! -z $TARGET ]] && [[ ! $(head -n 1 $file | grep -o "filename=$TARGET;") ]];then continue; fi
				filename=$(head -n 1 $file | grep -o "filename=[a-zA-Z0-1\.]*;" | cut -d '=' -f 2 | sed "s/;//g")
				timestamp=$(head -n 1 $file | grep -o "time=[0-9]*;" | cut -d '=' -f 2 | sed "s/;//g")
				if [[ -z $TEMPORAL ]] &&[[ OUTPUT =~ ";$filename;" ]];then continue;fi
				if [[ ! $FILENM =~ $filename ]];then FILENM="$FILENM$filename;";fi
				OUTPUT="$OUTPUT$filename=$timestamp=$(echo $file | sed "s/\/.*\///g");"
			done
			OUTPUT=$(echo $OUTPUT | sed "s/;/\n/g")
			FILENM=$(echo $FILENM | sed "s/;/ /g")
			for file in $FILENM;do
				list=($(echo $OUTPUT | grep -o "$file=[0-9]*" | sed "s/$file=//g"))
				list=($(echo ${list[*]}| tr " " "\n" | sort -n | tr "\n" " "))
				MATCH=
				for index in ${!list[@]};do
					block=$(echo $OUTPUT | grep -o "$file=${list[$index]}=[a-f0-9]*" | sed "s/$file=${list[$index]}=//g")
					if [[ $BLOCK ]] && [[ ! $(cat ~/chaindb/indexs/$block | grep -o "^$BLOCK;") ]];then continue;fi
					
					if [[ $LISTMODE =~ "oldest" ]] && [[ ! $index -eq 0 ]];then continue;fi
					if [[ $LISTMODE =~ "recent" ]] && [[ ! $index -eq $((${#list[@]}-1)) ]];then continue;fi
					if [[ $LISTMODE =~ "name" ]];then printf "$file $block"
					else 
						if [[ -z $MATCH ]];then printf "$file :\n";MATCH=1;fi
						printf "\t Index $block"
					fi
					if [[ $LISTMODE =~ "date" ]];then 
						if [[ $LISTMODE =~ "stamp" ]];then printf " ${list[$index]}"
						else printf " : $(date -d @${list[$index]})";fi
					fi
					
					if [[ ${#list[@]} -gt 1 ]] && [[ $LISTMODE =~ "info" ]];then 
						if [[ $index -eq 0 ]];then printf " (oldest)"
						elif [[ $index -eq $((${#list[@]}-1)) ]];then printf " (recent)";fi
					fi
					printf "\n"
				done
			done
		;;
		listip)
			if [[ -f ~/chaindb/fileserver ]];then
				LIP=$(ip a | grep "inet " | grep -v "127.0.0.1" | cut -d/ -f 1 | sed s/inet//g | tr -d ' ')
				RET=$(cat ~/chaindb/fileserver | grep -v '#')
				if [[ $RET =~ "127.0.0.1" ]];then echo $(echo "$RET $LIP" | sed s/127.0.0.1//g)
				else echo $RET;fi
			else echo > ~/chaindb/fileserver ;fi
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
		--block)
			BLOCK=$2
			shift 1
		;;
		--check-block)
			if [[ $EXECMODE ]] && [[ ! $EXECMODE = check ]];then
				log $LOG_STAERR "EXECMODE already set to $EXECMODE"
				exit 3
			fi
			BLOCK=$2
			EXECMODE=check
			log $LOG_STASET EXECMODE
			shift 1
		;;
		--get-fileserver)
			if [[ $EXECMODE ]] && [[ ! $EXECMODE = listip ]];then
				log $LOG_STAERR "EXECMODE already set to $EXECMODE"
				exit 3
			fi
			EXECMODE=listip
			log $LOG_STASET EXECMODE
			shift 1
		;;
		-l|--list)
			if [[ $EXECMODE ]] && [[ ! $EXECMODE = list ]];then
				log $LOG_STAERR "EXECMODE already set to $EXECMODE"
				exit 3
			fi
			while [[ $2 ]] && [[ ! "$2" =~ "-" ]];do
				LISTMODE="$LISTMODE$2;"
				shift 1
			done
			EXECMODE=list
			log $LOG_STASET EXECMODE
			shift 1
		;;
		-r|--recover)
			if [[ $EXECMODE ]] && [[ ! $EXECMODE = recover ]];then
				log $LOG_STAERR "EXECMODE already set to $EXECMODE"
				exit 3
			fi
			EXECMODE=recover
			log $LOG_STASET EXECMODE
			shift 1
		;;
		-h|--hash) HASHVALUE=$2;shift 1;;
		-n|--name) TARGET=$2;shift 1;;
		-s|--source)  SOURCE=$2;shift 1;;
		-t|--time)	TEMPORAL=$([[ $2 ]] && echo $2 || echo "recent");shift 1;;
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
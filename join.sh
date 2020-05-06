#!/usr/bin/env bash

#CONFIG - DEFAULT
ENCRY_MODE=aes256       #Encrypt Mode
FHASH_MODE=md5          #File (splited) Hash (checksum) md5
FHASH_NAME=true         #File (splited) Rename as <hashed-value>
LOG_STDERR=2            #Stderr
LOG_STDOUT=1            #Stdout
VERBOSE_LV=0            #Verbose Level
WORK_SPACE=`realpath .` #Sctipt Workplace (default .)
OUTPUT_DIR=$(realpath .)/out

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
  if ! [[ -f $INDEX ]];then
    if ! [[ -f $WORK_SPACE/index ]];then
      log $LOG_STAERR "No index file found"
      exit 1;
    fi
    INDEX=$WORK_SPACE/index
    log $LOG_STAINF "Index Found"
  fi
  
  log $LOG_STAINF "Reading Header"
  head=($(cat $INDEX | grep -v "^#" | head -n 1 | sed "s/;/ /g"))
  
  index=0
  while [[ ${head[$index]} ]];do
	varname="$(echo ${head[$index]} | cut -d = -f 1)"
	value=$(echo ${head[$index]} | cut -d = -f 2)
	index=$(($index+1))
	case $varname in
		"version")	 version=$value;;
		"hash")		 hash=$value;;
		"block")	 block=$value;;
		"filename")	 filename=$value;;
		"time")		 time=$value;;
		"encryption")encryption=$value;;
		*) log $LOG_STAWRN "Unregoginzed entry \033[33m'$varname'\033[39m";continue;;
	esac
	log $LOG_STASET $varname
  done
  files=$(cat $INDEX | grep -v "^#" | sed 1d)
  total=$(echo $files | wc -l)
  count=0
  > $WORK_SPACE/merge
  chmod 0600 $WORK_SPACE/merge
  > $WORK_SPACE/tmp
  chmod 0600 $WORK_SPACE/tmp
  
  ciphers=$(openssl enc -ciphers)
  
  for line in $files;do
	case "$version" in
		1) 
			file=$(echo $line | cut -d ";" -f 1)
			size=$(echo $line | cut -d ";" -f 2)
			if ! [[ -f $WORK_SPACE/$file ]];then 
				log $LOG_STAERR "Missing Fragment $file"
				exit -1
			fi
			if [[ ciphers =~ $encrypted ]];then
				openssl enc -d -$ENCRY_MODE -pbkdf2 -pass pass:$hash -salt -in $WORK_SPACE/$file > $WORK_SPACE/tmp
				file=$WORK_SPACE/tmp
			fi
			head -c $size $file >> $WORK_SPACE/merge
		;;
		*) log $LOG_STAERR "Unsupported Version $version";exit -2 ;;
	esac
	count=$(($count+1))
	log $LOG_STAINF "File $count/$total " $LOG_MODESL
  done
  log $LOG_STAINF "Removing tmp file"
  rm $WORK_SPACE/tmp
  log $LOG_STAINF "Moving merge file"
  mv $WORK_SPACE/merge $OUTPUT_DIR
  log $LOG_STAINF "Output -> $OUTPUT_DIR"
 
}

#ARGS   - PARSER
while (( "$#" ));do
    case "$1" in
        -h|--help) help $2;exit 0;;
        -o|--output)
          if [[ $2 = "auto" ]];then OUTPUT_DIR=auto
          elif [[ -f $2 ]];then
            read -p "Output file $2 Exist, overwrite ? [y|N] " key
            if [[ "yYoO" =~ $key ]];then OUTPUT_DIR=$(realpath $OUTPUT_DIR);fi
          else OUTPUT_DIR=$(realpath $OUTPUT_DIR);fi
          log $LOG_STAINF "Output -> $OUTPUT_DIR"
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
    esac
    shift 1
done

main

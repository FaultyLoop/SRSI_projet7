#!/usr/bin/env bash

#CONFIG - DEFAULT
BLOCK_SIZE=4096         #4096 bytes
ENCRY_MODE=aes256       #Encrypt Mode
FHASH_MODE=md5          #File (splited) Hash (checksum) md5
FHASH_NAME=true         #File (splited) Rename as <hashed-value>
FFILL_MODE=random       #Fill method for file
FILL_PATRN="\0"         #Fill Parrern
INDEX_VERS=1            #Basic index version (0 : top-down, 1 : link-pem (wip), 2 : future)
LOG_STDERR=2            #Stderr
LOG_STDOUT=1            #Stdout
SIZEFORMAT=             #Size unit
SIZEUNITDP=             #Size unit Display
VERBOSE_LV=0            #Verbose Level
WORK_SPACE=`realpath .` #Sctipt Workplace (default .)

#CONFIG - CONSTANT
LOG_MODESL=same         #Log Modifier Same Line (\r)
LOG_MODESZ=size         #Log Modifier size
LOG_STADBG=debug        #Log Status Debug
LOG_STAERR=error        #Log Status Error
LOG_STAHLP="\t"         #Log Status Help
LOG_STAINF=info         #Log Status Info
LOG_STARUN=exec         #Log Status Executing
LOG_STAWRN=warn         #Log Status Warn
LOG_STASET="variable_set"    #Log Status Set

#CONFIG - DYNAMIC
FILES_LIST=             #List Of Files
INDEX_HEAD=             #Index Header (See HeaderInfo)

#INTERRUPTS

#MAIN   - FUNCTION
fill(){
  size=$(getsize $1)
  miss=$(($BLOCK_SIZE-$size))
  if [[ $miss -gt 0 ]];then
    while [[ $miss -gt 0 ]];do
      case "$FFILL_MODE" in
        random) dd if=/dev/urandom status=none bs=1 count=$miss seek=$size of=$1;;
        *) bytes=$FILL_PATRN
      esac
      printf "$bytes" >> $file
      size=$(getsize $1)
      miss=$(($BLOCK_SIZE-$size))
    done
  fi
}

formatsize(){
    size=$1
    counter=1
    div=$([[ $SIZEFORMAT = si ]] && echo 1000 || echo 1024)
    unit=$([[ $SIZEUNITDP = bytes ]] && echo "B" || echo "o")

    while [[ $size -ge $div ]];do
      keep=$(($size % $div))
      size=$(($size / $div))
      counter=$(($counter + 1))
    done

    if   [[ $keep -lt 10 ]];  then size="$size"
    elif [[ $keep -lt 100 ]]; then size="$size,0$keep"
    else size="$size,$keep" ; fi
    major=$(echo " K M G T P E Z Y" | cut -d " " -f$counter)
    echo "$size ${major}${unit}"
}

getsize(){
  echo $(stat $1 -c %s)
}

help(){
    case "$1" in
        *|-h|--help)
            if [[ "$1" = "-h" ]] || [[ "$1" = "--help" ]];then
                log $LOG_STAINF "Display this help"
            elif [[ $1 ]];then
                log $LOG_STAERR "$1 Argument inconnu"
                exit 0
            fi
            log $LOG_STAHLP "-h/--help      <option>                : Display helper or usage if <option> is given"
            log $LOG_STAHLP "-i/--input     <file | file:<list>>    : Define Input file or list"
        ;;
    esac
    RETURN=
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
  files=$(echo $FILES_LIST | sed "s/;/\n/g")
  for file in $files;do
    size=$(getsize $file)
    hash=$(openssl $FHASH_MODE $file | cut -d " " -f2)
    log $LOG_STAINF "File Size : $(formatsize $size)"
    log $LOG_STAINF "File Hash  ($FHASH_MODE) : $hash"

    if ! [[ -d "dir_$hash" ]];then mkdir "dir_$hash";fi
    cd "dir_$hash"
    echo $(setIndexHeader $hash $BLOCK_SIZE $file) > index

    log $LOG_STAINF "Splitting file"
    split $file -b $BLOCK_SIZE
    log $LOG_STAINF "Encrypting files"
    total=$(ls x* | wc -l)
    count=0
    for file in $(ls x*);do
      size=$(getsize $file)
      subh=$(openssl $FHASH_MODE $file | cut -d " " -f2)
      echo "$subh;$size;" >> index

      if [[ $size -lt $BLOCK_SIZE ]];then fill $file; fi
      mv $file $subh

      #Encryption
      openssl enc -$ENCRY_MODE -pbkdf2 -pass pass:$hash -salt -in $subh -out $subh.enc
      mv $subh.enc $subh
      count=$(($count+1))
      log $LOG_STAINF "Files $count/$total" $LOG_MODESL
    done
    cd ..
  done
  log $LOG_STAINF "Done"
}

setIndexHeader(){
	time=$(date +"%s")
	filename=$(basename $3)
    header="version=$INDEX_VERS;hash=$1;block=$2;filename=$filename;time=$time";
    case "$INDEX_VERS" in
        0) echo "$header;encryption=plaintext;";;
        1) echo "$header;encryption=$ENCRY_MODE;";;
    esac
}

#SETUP - PREPARE


#ARGS PARSER
while (( "$#" ));do
    case "$1" in
        -b|--block)
          BLOCK_SIZE=$([[ $2 = "/^[0-9]*$/"]] && echo $2 || echo $BLOCK_SIZE)
          log $LOG_STASET BLOCK_SIZE
        ;;
        --fill)
          case "$2" in
            random) FFILL_MODE=random ;;
            *) if [[ $2 ]];then FILL_PATRN=$2;FFILL_MODE=patten;fi ;;
          esac
        ;;
        -h|--help) help $2;exit 0;;
        -i|--input)
            while [[ ! "$2" =~ "-" ]] && [[ "$2" != "" ]];do
                if [[ "$2" =~ "list:" ]];then
                    list=$(echo $2 | cut -d ":" -f2)
                    if [[ -f $list ]];then
                      list=$(cat $list | tr "\000" "\n")
                      for file in $list;do
                        file=$(realpath $file)
                        if [[ -f $file ]] && ! [[ $file =~ $FILES_LIST ]];then
                          if     [[ $FILES_LIST = "" ]];then FILES_LIST="$file;";
                          elif ! [[ $FILES_LIST =~ "$file;" ]];then FILES_LIST="$FILES_LIST$file;";
                          else log $LOG_STADBG "$file Already present in list";fi
                        fi
                      done
                    else log $LOG_STADBG "$list : No such file"; fi
                elif [[ -f $2 ]];then
                    file=$(realpath $2)
                    if     [[ $FILES_LIST = "" ]];then FILES_LIST="$file;";
                    elif ! [[ $FILES_LIST =~ "$file;" ]];then FILES_LIST="$FILES_LIST$file;";
                    else log $LOG_STADBG "$file Already present in list";fi
                else log $LOG_STADBG "$2 : No such file"; fi
                shift 1
            done
            log $LOG_STASET FILES_LIST
            FILE_COUNT=`echo -e $FILES_LIST | wc -l`
        ;;
        -v*|--verbose)
            if [[ "$1" = "--verbose" ]];then
              if [[ $2 =~ '^[0-9]+$' ]];then VERBOSE_LV=$2; else VERBOSE_LV=1;fi
            else VERBOSE_LV=$((${#1}-1));fi
            log $LOG_STASET VERBOSE_LV
        ;;
        --si)SIZEFORMAT=si;;
        *);;
    esac
	shift 1
done

#CONFIG - PREPARE
if [[ $FILE_COUNT -eq 0 ]];then
    log "No file, exiting"
    exit 0
fi

main

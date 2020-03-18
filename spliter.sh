#!/bin/bash

#CONFIG - DEFAULT
BLOCK_SIZE=4094         #4096 bytes
FHASH_MODE=md5          #File (splited) Hash (checksum) md5
FHASH_NAME=true         #File (splited) Rename as <hashed-value>
LOG_STDERR=2            #Stderr
LOG_STDOUT=1            #Stdout
INDEX_VERS=0            #Basic index version (0 : top-down, 1 : link-pem (wip), 2 : future)
VERBOSE_LV=0            #Verbose Level
WORK_SPACE=`realpath .` #Sctipt Workplace (default .)
SIZES_UNIT=             #Unit of file size

#CONFIG - CONSTANT
LOG_MODENV=none         #Log Modifier Not a Var
LOG_MODESZ=size         #Log Modifier size
LOG_STAERR=error        #Log Status Error
LOG_STAINF=info         #Log Status Info
LOG_STAWRN=warn         #Log Status Warn
LOG_STASET=vset          #Log Status Set
RTIME_MODE=`id -u`      #Check root (future)

#CONFIG - DYNAMIC
BLOCK_STEP=0            #Block Used
FILE_COUNT=0            #Files Do
FILES_LIST=             #List Of Files
INDEX_HEAD=             #Index Header (See HeaderInfo)

#CONFIG - FUNCTION
setBlockMax(){
    setIndexHeader
    HEADSTR_LEN=${#INDEX_HEAD}
    HASH_SAMPLE=`echo "" | openssl $FHASH_MODE | cut -d " " -f2`
    HASHSTR_LEN=${#HASH_SAMPLE}
    
    #Default/user defined
    log $LOG_STAINF BLOCK_SIZE $LOG_MODESZ
    
    BLOCK_FILE=$(($BLOCK_SIZE+$FILE_COUNT+$HASHSTR_LEN+$HEADSTR_LEN+1))
    log $LOG_STAINF BLOCK_FILE $LOG_MODESZ
    
    FREE_SPACE=$((`df . --output=avail | cut -d " " -f1`*1000))
    log $LOG_STAINF FREE_SPACE $LOG_MODESZ
    
    BLOCK_MAX=$(($FREE_SPACE/$BLOCK_FILE))
    log $LOG_STAINF BLOCK_MAX $LOG_MODESZ
    
    RETURN=
}

setIndexHeader(){
    case "$INDEX_VERS" in
        0)
            INDEX_HEAD="Version 0; Hash $FHASH_MODE; Block $BLOCK_SIZE;";
        ;;
    esac
    RETURN=
}

#MAIN   - FUNCTION
checkBlockUsage(){
    for FILE in `echo -e "$FILES_LIST"`;do
        getsize $FILE
        FILE_SIZE=$RETURN
        BLOCK_USAGE=$(($FILE_SIZE/$BLOCK_SIZE))
        BLOCK_TOTAL=$(($BLOCK_FILE*$BLOCK_USAGE))
        log "----------------------" "" $LOG_MODENV
        log $LOG_STAINF "FILE $FILE" $LOG_MODENV
        log $LOG_STAINF FILE_SIZE $LOG_MODESZ
        log $LOG_STAINF BLOCK_USAGE
        log $LOG_STAINF BLOCK_TOTAL $LOG_MODESZ
        
        if [[ $BLOCK_TOTAL > $BLOCK_MAX ]];then
            echo "wip"
        fi
        
        
        
    done
}
checkfile(){
    for FILE in `echo -e "$FILES_LIST"`;do
        if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]];then
            echo "WIP"
        fi
        TFILE=`realpath -eq $FILE`
        if [[ $TFILE = "" ]];then
            if [[ $REMOVE = "" ]];then REMOVE=$FILE; else REMOVE=`echo "$REMOVE\n$FILE"`;fi
        else log $LOG_STAINF "File $FILE OK" $LOG_MODENV;   fi
    done
    for FILE in $REMOVE;do
        FILES_LIST=${FILES_LIST//$FILE/}
        log $LOG_STAWRN "$FILE is INVALID" $LOG_MODENV
    done
    FILE_COUNT=`echo -e $FILES_LIST | wc -l`
    RETURN=`echo -e $REMOVE | wc -l`
}

formatsize(){
    COUNTER=0
    FORMAT=" K M G T P E Z Y"
    SIZE=$1
    SYTAIL=
    if [[ $SIZES_UNIT =~ "i" ]];then SYTAIL="i"; DIVISOR=1024; else DIVISOR=1000; fi
    if [[ $SIZES_UNIT =~ "b" ]];then
        SYTAIL="bit"
        SIZE=$(($SIZE*8))
    else
        if [[ $SIZES_UNIT =~ "B" ]];then SYTAIL="${SYTAIL}B";
        else SYTAIL="${SYTAIL}o";fi
    fi
    while [[ $SIZE -ge $DIVISOR ]];do
        KEEP=$(($SIZE%$DIVISOR))
        SIZE=$(($SIZE/$DIVISOR))
        COUNTER=$(($COUNTER+1))
        SYM="`echo $FORMAT | cut -d " " -f$COUNTER`"
        if [[ $SIZES_UNIT =~ $SYM ]];then break;fi
    done
    if [[ $KEEP < 100 ]];then KEEP="0$KEEP";fi
    RETURN="$SIZE,$KEEP $SYM$SYTAIL"
}

getsize(){
  SIZE=`ls -l $1 | cut -d " " -f5`
  RETURN=$SIZE
}

help() {
    case "$1" in
        *|-h|--help)
            if [[ "$1" = "-h" ]] || [[ "$1" = "--help" ]];then
                echo "Display this help"
            fi
            echo "-h    --help  <option>    : Display helper or usage if <option> is given"
            
        ;;
    esac
    RETURN=
}

log(){
    BYPASS=$RETURN
    OUTPUT=$LOG_STDOUT
    OFORMAT="\033[39m"
    EFORMAT="\033[39m"
    case "$1" in
        $LOG_STAERR)
            OUTPUT=$LOG_STDERR
            OFORMAT="\033[31m"
            ;;
        $LOG_STAWRN)
            OFORMAT="\033[31m"
        ;;
        $LOG_STAINF)
            OFORMAT="\033[36m"
        ;;
        *)
            OFORMAT=""
        ;;
    esac
    
    case "$3" in
        $LOG_MODESZ)
            formatsize $(($2))
            EFORMAT="\033[32m"
            VALUE=$RETURN
        ;;
        $LOG_MODENV)
            VALUE=
        ;;
        *)
            VALUE=$(($2))
        ;;
        
    esac
    if [[ $VALUE != "" ]];then
        echo -e "$OFORMAT$1 \033[33m$2\033[39m AT $EFORMAT$VALUE" >&$OUTPUT;
    else
        echo -e "$OFORMAT$1 \033[39m$2" >&$OUTPUT;
    fi
    RETURN=$BYPASS
}

#ARGS PARSER
while (( "$#" ));do
    case "$1" in
        -h|--help)
            help $2
            exit 0;
        ;;
        -i|--input)
            while [[ ! "$2" =~ "-" ]] && [[ "$2" != "" ]];do
                if [[ $FILES_LIST = "" ]];then FILES_LIST=$2; else FILES_LIST="$FILES_LIST\n$2";fi
                shift 1
            done;
            FILE_COUNT=`echo -e $FILES_LIST | wc -l`
            shift 1
        ;;
        -u|--unit)
            SIZES_UNIT=$2
            shift 1
        ;;
        -v*|--verbose)
            if [[ "$1" = "--verbose" ]];then
                VERBOSE=$2
                shift 1
            else VERBOSE=$((${#1}-1));fi
            log $LOG_STASET VERBOSE
            shift 1
        ;;
        -s|--strict)
            if [[ $2 != "" ]];then STRICT_MODE=$2; else STRICT_MODE="y"; fi
            shift 1
            ;;
        *) 
            shift 1
        ;;
    esac
done

#CONFIG - PREPARE
if [[ $FILE_COUNT = 0 ]];then
    log "No file, exiting"
    exit 0
fi
setBlockMax

log $LOG_STAINF "$FILE_COUNT File declared" $LOG_MODENV
checkfile
log $LOG_STAINF "$FILE_COUNT File confirmed" $LOG_MODENV

if [[ $STRICT_MODE =~ "y" ]];then
    if [[ $RETURN != 0 ]];then
        log $LOG_STAERR "Echec de la recuperation de certains ficher en mode strict" $LOG_MODENV
        exit 1
    fi
fi

checkBlockUsage






















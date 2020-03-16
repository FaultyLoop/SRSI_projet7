#!/bin/bash
#Defaults

BLOCKS=4096
LIMIT=2048
TIMER=5
TIMEOUT=5
HASH_METHOD=md5
LOGFILE=1
ERRFILE=2
UNIT=

function help(){
  echo "To be determined"
  exit 0
}

function getsize(){
  SIZE=`ls -s $TARGET | cut -d " " -f1`
  SIZE=$(($SIZE*1024))
}

function formatsize(){
  FORMAT=" K M G T P E Z Y"
  COUNTER=0
  TMP=$SIZE
  if   [[ $UNIT =~ "en" ]];then SYTAIL="B"; else SYTAIL="o";fi
  if   [[ $UNIT =~ "si" ]];then DIVISOR=1000; else SYTAIL="i$SYTAIL"; DIVISOR=1024; fi
  if ! [[ $UNIT =~ "-" ]];then
    while test $TMP -ge $DIVISOR;do
      TMP=$(($TMP/$DIVISOR))
      COUNTER=$(($COUNTER+1))
      SYM="`echo $FORMAT | cut -d " " -f$COUNTER`"
      if [[ $UNIT =~ $SYM ]];then
        break
      fi
    done
  fi
  FORMATSIZE="$TMP $SYM$SYTAIL"
}

function checkfile(){
  TMP="$PATH_TO_INPUTS"
  PATH_TO_INPUTS=""
  for TARGET in $TMP;do
    PATH_TO_INPUT=`realpath -eq $TARGET`
    if test $? -ne 0;then PATH_TO_INPUT=$TARGET;fi
    if [[ $TARGET =~ ":" ]];then
      scp -o ConnectTimeout=$TIMEOUT $TARGET ./
      if test $? -ne 0;then
        echo "ERROR : File not recovered from server $TARGET" >& $ERRFILE
        continue
      fi
      TARGET=`basename \`echo $TARGET | cut -d ":" -f 2\``
      TARGET=`realpath $TARGET`
      PATH_TO_INPUT=$TARGET
    elif test $? -eq 0;then
      echo "ERROR : File $TARGET not found"
      continue
    fi
    PATH_TO_INPUTS="$PATH_TO_INPUTS $PATH_TO_INPUT"
  done
  if test $STRICT || test -z $PATH_TO_INPUTS ;then
    echo "SCRIPT FATAL ERROR : UNABLE TO CONTINUE" >& $ERRFILE
    exit 1
  fi
  echo $PATH_TO_INPUTS
}

function splitfile(){
  for TARGET in $PATH_TO_INPUTS;do
    getsize;formatsize
    HASH_ORIGIN=`openssl $HASH_METHOD $TARGET | cut -d " " -f 2`
    FRAGMENTS=$(($SIZE/$BLOCKS))
    echo "FILE        $TARGET"
    echo "SIZE        $FORMATSIZE"
    echo "FRAGMENTS   $FRAGMENTS"
    echo "FRAG. SIZE  $FORMATBLOCKS"
    echo "HASH_METHOD $HASH_METHOD"
    echo "HASH_RESULT $HASH_ORIGIN"
    echo "------------------------"

    if test $FRAGMENTS -gt $LIMIT;then
      if test -z $AUTOCONTINUE;then
        echo "Fagments limit at $LIMIT, continu ?(y/[N])"
        read CONTINUE
      else
        CONTINUE=$AUTOCONTINUE
        echo "Fagments limit at $LIMIT, selection bypass ([$CONTINUE])"
      fi
      case "$CONTINUE" in
          y|Y|yes|YES)
            ;;
          *)
            continue
            ;;
      esac
    fi

    mkdir -p dir_$HASH_ORIGIN
    if test $? -eq 0;then
      cd "dir_$HASH_ORIGIN"
      printf "Splitting : "
      split -b $BLOCKS $TARGET
	    printf "Done\n"
      COUNTER=0
      TOTAL=`ls -1 | wc -l`
      > index
      for FILE in `ls`;do
        FILE=`realpath $FILE`
        HASH=`openssl $HASH_METHOD $FILE | cut -d " " -f 2`
        mv $FILE $HASH
        echo "$HASH" >> index
        printf "\rSorting : $COUNTER/$TOTAL"
        COUNTER=$(($COUNTER+1))
      done
      cd ..
      printf "\nDone !\n"
    else
      echo "ERROR : Workdir unavailable"
    fi
  done
}

#Aruments Parser
while (( "$#" ));do
  case "$1" in
    -h|--help)
      help
      ;;
    -b|--block)
      BLOCKS=$2         ;ADD_TO_INPUT=0;
      shift 2
      ;;
    -t|--timeout)
      TIMEOUT=$2        ;ADD_TO_INPUT=0;
      ;;
    -i|--input)
      PATH_TO_INPUTS=$2 ;ADD_TO_INPUT=1;
      shift 2
      ;;
    -n|--no)
      AUTOCONTINUE="n"  ;ADD_TO_INPUT=0;
      shift 1
      ;;
    -u|--unit)
      UNIT=$2           ;ADD_TO_INPUT=0;
      shift 2
      ;;
    -v|--verbose)
      VERBOSE=1         ;ADD_TO_INPUT=0;
      shift 1
      ;;
    -l|--log)
      ADD_TO_INPUT=0;
      if test `echo $2 | grep "-"`;then
        LOGFILE="./shifter.log"
        shift 1
      else
        LOGFILE=$2
        shift 2
      fi
      ;;
    -e|--err)
      ADD_TO_INPUT=0;
      if test `echo $2 | grep "-"`;then
        ERRFILE="./shifter.err"
        shift 1
      else
        ERRFILE=$2
        shift 2
      fi
      ;;
    -y|--yes)
      AUTOCONTINUE="y"  ;ADD_TO_INPUT=0;
      shift 1
      ;;
    --hash-method)
      HASH_METHOD=$2    ;ADD_TO_INPUT=0;
      shift 2
      ;;
    --strict)
      STRICT=1          ;ADD_TO_INPUT=0;
      shift 1
      ;;
    -*|--*)
      echo "Erreur : Argument '$1' Invalide" >& 2
      exit -1
      ;;
    *)
      if test $ADD_TO_INPUT = 1;then
        PATH_TO_INPUTS="$PATH_TO_INPUTS $1"
      else
        echo "Erreur : Symbole '$1' inconnu" >& 2
        exit -1
      fi
      shift 1
     esac
done
SIZE=$BLOCKS;formatsize;FORMATBLOCKS=$FORMATSIZE
checkfile
splitfile

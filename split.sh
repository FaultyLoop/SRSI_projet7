#!/usr/bin/env bash
VERSON="1.1"

#CONFIG - DEFAULT
BLOCK_SIZE=4096         #Block size (fragment pre-treated)
BINDP_SIZE=4096			#Binary Dump size (fragement final)
ENCRY_MODE=aes256       #Encrypt Mode
FHASH_MODE=md5          #File (splited) Hash (checksum) md5
FHASH_NAME=true         #File (splited) Rename as <hashed-value>
FFILL_MODE=random       #Fill method for file
FILL_PATRN="undefined"  #Fill Parrern
INDEX_VERS=1            #Basic index version (0 : top-down, 1 : link-pem (wip), 2 : future)
LOG_STDERR=2            #Stderr
LOG_STDOUT=1            #Stdout
SIZEFORMAT=             #Size unit
SIZEUNITDP=             #Size unit Display
VERBOSE_LV=0            #Verbose Level
WORK_SPACE=`realpath .` #Sctipt Workplace (default .)

#CONFIG - CONSTANT
LOG_MODESL=same         	#Log Modifier Same Line (\r)
LOG_MODESZ=size         	#Log Modifier size
LOG_STADBG=debug        	#Log Status Debug
LOG_STAERR=error        	#Log Status Error
LOG_STAHLP="\t"         	#Log Status Help
LOG_STAINF=info        		#Log Status Info
LOG_STARUN=exec        		#Log Status Executing
LOG_STAWRN=warn				#Log Status Warn
LOG_STASET="variable_set"   #Log Status Set
LIST_PATTERN=(0b00000000 0b11111111 0b01010101 0b10101010 0b11001100 0b00110011)

#CONFIG - DYNAMIC
FILES_LIST=             #List Of Files
INDEX_HEAD=             #Index Header (See HeaderInfo)

#INTERRUPTS

#MAIN   - FUNCTION
fill(){
	 #DISABLED (rework for version 1.1.1)
	> fill
	if [[ $FFILL_MODE == "random" ]];then
		dd if=/dev/urandom bs=1 count=$1 status=none of=fill
	elif [[ $$FFILL_MODE != "none" ]];then
		echo "" > fill
	fi	
}

xsplit(){
	fsize=$(getsize $1)
	cd $2
    echo $(setIndexHeader $3 $BLOCK_SIZE $1) > index
	log $LOG_STADBG "Generating $(($fsize / $BLOCK_SIZE)) fragments"
	for lid in $(seq 0 $(($fsize / $BLOCK_SIZE)));do
		rid=$(od -vAn -N4 -tu4 < /dev/urandom | grep -o '[0-9]*')
		dd status=none if=$1 bs=1 count=$BLOCK_SIZE skip=$((BLOCK_SIZE*$lid)) | openssl enc -$ENCRY_MODE -pbkdf2 -salt -pass pass:$3 -out ./$rid
		if [[ $(getsize ./$rid) -lt $BLOCK_SIZE ]];then cpy=$(($(getsize $file) - BLOCK_SIZE*$lid))
		else cpy=$BLOCK_SIZE;fi
		log $LOG_STAINF "Block ($lid/$(($fsize / $BLOCK_SIZE)))" $LOG_MODESL
		md5=$(md5sum $rid | cut -d " " -f1)
		mv $rid $md5
		echo "$md5;$cpy;" >> index
	done
	log $LOG_STAINF "Block ($(($lid))/$(($fsize / $BLOCK_SIZE))) : done"
	cd ..
}

unformatsize(){
	size=
	if [[ $1 =~ ^[0-9]*$ ]];then size=$1;
	elif [[ $1 =~ ^[0-9]*("K"|"M"|"G"|"k"|"m"|"g")("o"|"b"|"B")?$ ]];then
		size=$(echo $1 | grep -o '^[0-9]*')
		if [[ $1 =~ ("k"|"K") ]];then
			if [[ $1 =~ "o" ]];then size=$(($size * 1024));
			else size=$(($size * 1000));fi
		elif [[ $1 =~ ("m"|"M") ]];then
			if [[ 12 =~ "o" ]];then size=$(($size * 1024 * 1024));
			else size=$(($size * 1000 * 1000));fi
		elif [[ $1 =~ ("g"|"G") ]];then
			if [[ $1 =~ "o" ]];then size=$(($size * 1024 * 1024 * 1024));
			else size=$(($size * 1000 * 1000 * 1000));fi
		fi
	if [[ $1 =~ "b" ]];then size=$(($size * 8));fi
	else
		#log $LOG_STAWRN "Unsopported modifier : $(echo $1 | grep -o '[^0-9]*')"
		size=$2
	fi
	echo $size
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
	log $LOG_STAINF "File Hash : $hash ($FHASH_MODE)"

    if ! [[ -d "dir_$hash" ]];then mkdir "dir_$hash";fi
	xsplit $file "dir_$hash" $hash
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

#ARGS PARSER
while (( "$#" ));do
	case "$1" in
		-b|--block)
			BLOCK_SIZE=$(unformatsize $2 $BLOCK_SIZE)
			log $LOG_STASET BLOCK_SIZE $LOG_MODESZ
        ;;
		--binary-dump)
			BINDP_SIZE=$(unformatsize $2 $BINDP_SIZE)
			log $LOG_STASET BINDP_SIZE $LOG_MODESZ
			;;
        --fill)
			case "$2" in
				random) 
					FFILL_MODE=random;
					FILL_PATRN="<undefined>"
					;;
				sequence)
					if [[ $3 -lt ${#LIST_PATTERN[@]} ]] && [[ $3 -ge 0 ]];then
						FFILL_MODE=sequence;
						FILL_PATRN=${LIST_PATTERN[$3]}
					fi
				;;
				*)
					if [[ $2 ]];then FFILL_MODE=custom;FILL_PATRN=$2;fi
				;;
			esac
			log $LOG_STASET FILL_PATRN
			log $LOG_STASET FFILL_MODE
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
            FILE_COUNT=`echo -e $FILES_LIST | wc -l`
            log $LOG_STASET FILES_LIST
            log $LOG_STASET FILE_COUNT
        ;;
        -v*|--verbose)
            if [[ "$1" = "--verbose" ]];then
				if [[ $2 =~ '^[0-9]+$' ]];then VERBOSE_LV=$2;
				else VERBOSE_LV=1;fi
            else VERBOSE_LV=$((${#1}-1));fi
            log $LOG_STASET VERBOSE_LV
        ;;
        --si)
			SIZEFORMAT=si
            log $LOG_STASET SIZEFORMAT
		;;
        *)
		;;
    esac
	shift 1
done

#CONFIG - PREPARE
if [[ $FILE_COUNT -eq 0 ]];then
    log "No file, exiting"
    exit 0
fi

main

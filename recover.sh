#!/bin/bash*







































while (( "$#" ));do
    case "$1" in
        -h|--help)
            help $2
            exit 0;
        ;;
        -v*|--verbose)
            if [[ "$1" = "--verbose" ]];then
                VERBOSE=$2
                shift 1
            else VERBOSE=$((${#1}-1));fi
            log $LOG_STASET VERBOSE
            shift 1
        ;;
    esac
done

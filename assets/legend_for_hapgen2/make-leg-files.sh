#!/bin/bash

# Script to take in imputation results, extract all SNPs per chromosome and make *.leg file for input to hapgen2



USAGE() { echo "Usage: bash $0 [-f <input-VCF>]" 1>&2; exit 1; }

if (($# == 0)); then
        USAGE
fi

# Use getopts to accept each argument

while getopts ":f:h" opt
do
    case $opt in
       f ) VCFFILE=$OPTARG
        ;;
       h ) USAGE
        ;;
       \? ) echo "Invalid option: -$OPTARG exiting" >&2
        exit
        ;;
       : ) echo "Option -$OPTARG requires an argument" >&2
        exit
        ;;
        esac
    done

for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22
do
    grep  "^$i\t" $VCFFILE | awk '{print $3,$2,$4,$5}' | awk 'BEGIN{print "rs position X0 X1"}1' > chr${i}.leg
    firstpos=$(cat chr${i}.leg | awk 'NR==2' | cut -f2 -d " ")
    mv chr${i}.leg chr${i}-${firstpos}.leg
done



#!/bin/bash

declare -A tarcolors

function get_tar_colors()
{
  generationsfile=$1

  while read -r line; do
    tar=$(echo $line | cut -d' ' -f1)
    generation=$(echo $line | tr -s ' ' | cut -d' ' -f2)
    geneven=$(( generation & 0x1 ))
    compacted=$(echo $line | tr -s ' ' | cut -d' ' -f3)
    if [ "$geneven" -eq "1" ]; then
      if [ "$compacted" -eq "1" ]; then
        tarcolors[$tar]="30;43"
      else
        tarcolors[$tar]="33"
      fi
    else
      if [ "$compacted" -eq "1" ]; then
        tarcolors[$tar]="30;46"
      else
        tarcolors[$tar]="36"
      fi
    fi

    #echo ${tarcolors[$tar]}
    #echo ${tarcolors[data00074a.tar]}
    #echo -e "\e[${tarcolors[$tar]}m$tar\e[0m $generation $compacted"

  done < $generationsfile
}

#get_tar_colors generations.log

#echo "after get_tar_colors ${tarcolors[data00074a.tar]}"

function print_vmwatch() {
  while read -r line; do
    tar=$(echo $line | cut -d' ' -f1)

    # make each line fixed width
    printf -v line %-100.100s "$line"

    if [[ "$tar" == data0* ]] ; then
      [ ${tarcolors[$tar]+isset} ] && echo -e "\e[${tarcolors[$tar]}m${line}\e[0m" || echo "$line"
    else
      echo "$line"
    fi
  done < <( cat $1  | sed -e 's/^.*\r//g' | sed -e 's|/mnt/installation/crx-quickstart/repository/segmentstore/||g' | sed -e 'N;s/\n\[/ \[/' )
}

#print_vmwatch "../vmwatch-1534907881.log"

function play_vmwatch() {
  clear
  tput civis # hide cursor
  for f in $@ 
  do 
    [ "$f" = "vmtouch-2018-09-05-02-20-01.log.coloured" ] && tput clear 
    tput cup 0 0
    ghead -n-5 $f | paste -d "\0" - - 
    tail -5 $f
    sleep 0.2
  done
  tput cnorm # redisplay cursor
}

function save_vmwatch() {
  for logfile in $@
  do
    # redirect stdout
    exec >> $(basename $logfile).coloured
    print_vmwatch $logfile
    echo $(basename $logfile)
  done
}

play_vmwatch $@
#save_vmwatch $@


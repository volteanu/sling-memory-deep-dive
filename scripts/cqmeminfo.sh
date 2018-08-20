#!/bin/env bash

# requires: 
#   > apt install bc

CQ_PID=$( pgrep -f cq-quickstart )
echo "detected quickstart pid:"
ps $CQ_PID
echo ""

LOGSTASH_PID=$( pgrep -f logstash )
echo "detected logstash pid:"
ps $LOGSTASH_PID
echo ""

total=$(( $( cat /proc/meminfo  | grep "MemTotal" | tr -s ' ' | cut -d' ' -f 2 ) * 1024 ))

freemem=$(( $( cat /proc/meminfo  | grep "MemFree" | tr -s ' ' | cut -d' ' -f 2 ) * 1024 ))

#buffers=$(( $( cat /proc/meminfo  | grep "^Buffers" | tr -s ' ' | cut -d' ' -f 2 ) * 1024 ))
#cached=$(( $( cat /proc/meminfo  | grep "^Cached" | tr -s ' ' | cut -d' ' -f 2 ) * 1024 ))
#cachemem=$(( buffers + cached ))

cacheactive=$(( $( cat /proc/meminfo  | grep "Active(file)" | tr -s ' ' | cut -d' ' -f 2 ) * 1024 ))
cacheinactive=$(( $( cat /proc/meminfo  | grep "Inactive(file)" | tr -s ' ' | cut -d' ' -f 2 ) * 1024 ))
cachemem=$(( cacheactive + cacheinactive ))

anon_active=$(( $( cat /proc/meminfo  | grep "Active(anon)" | tr -s ' ' | cut -d' ' -f 2 ) * 1024 ))
anon_inactive=$(( $( cat /proc/meminfo  | grep "Inactive(anon)" | tr -s ' ' | cut -d' ' -f 2 ) * 1024 ))
procmem=$(( anon_active + anon_inactive ))

# kernel pages
slab=$(( $( cat /proc/meminfo  | grep "Slab" | tr -s ' ' | cut -d' ' -f 2 ) * 1024 ))
kernelstack=$(( $( cat /proc/meminfo  | grep "KernelStack" | tr -s ' ' | cut -d' ' -f 2 ) * 1024 ))
pagetables=$(( $( cat /proc/meminfo  | grep "PageTables" | tr -s ' ' | cut -d' ' -f 2 ) * 1024 ))
kernelmem=$(( slab + kernelstack + pagetables ))

# memory mapped files in CQ
cqmappedmem=$(( $( pmap -x -p $CQ_PID | grep "/" | grep -v "Xmx" | tr -s ' ' | cut -d' ' -f3 | paste -s -d+ - | bc ) * 1024 ))

tarmappedmem=$(( $( pmap -x -p $CQ_PID | grep "crx-quickstart/repository/segmentstore" | tr -s ' ' | cut -d' ' -f3 | paste -s -d+ - | bc ) * 1024 ))
indexmappedmem=$(( $( pmap -x -p $CQ_PID | grep "crx-quickstart/repository/index" | tr -s ' ' | cut -d' ' -f3 | paste -s -d+ - | bc ) * 1024 ))
jarmappedmem=$(( $( pmap -x -p $CQ_PID | grep "/" | grep "\.jar$" | tr -s ' ' | cut -d' ' -f3 | paste -s -d+ - | bc ) * 1024 ))
jremappedmem=$(( $( pmap -x -p $CQ_PID | grep "/" | grep "java/jre" | tr -s ' ' | cut -d' ' -f3 | paste -s -d+ - | bc ) * 1024 ))

# process pages
cqprocmem=$(( $( pmap -x $CQ_PID | grep "\[ anon \]" | tr -s ' ' | cut -d' ' -f3 | paste -s -d+ - | bc ) * 1024 ))
logstashprocmem=$(( $( pmap -x $LOGSTASH_PID | grep "\[ anon \]" | tr -s ' ' | cut -d' ' -f3 | paste -s -d+ - | bc ) * 1024 ))

#tarmappedmem=$(( $(vmtouch /mnt/installation/crx-quickstart/repository/segmentstore/* | grep "Resident Pages" | tr -s ' ' | cut -d' ' -f 4 | cut -d '/' -f 1) * 4 * 1024 ))

function toMB() {
	echo "$(( $1 / 1024 / 1024 )) MB"
}


echo "total=$total ($(toMB $total))"
echo "  freemem=$freemem ($(toMB $freemem))"
echo "  kernelmem=$kernelmem ($(toMB $kernelmem))"
echo ""
echo "  procmem=$procmem ($(toMB $procmem))"
echo "    cqprocmem=$cqprocmem ($(toMB $cqprocmem))"
echo "    logstashprocmem=$logstashprocmem ($(toMB $logstashprocmem))"
echo "    otherprocmem=$(( procmem - logstashprocmem - cqprocmem ))"
echo ""
echo "  cachemem=$cachemem ($(toMB $cachemem))"
echo "    cacheinactive=$cacheinactive ($(toMB $cacheinactive))"
echo "    cacheactive=$cacheactive ($(toMB $cacheactive))"
echo "      cqmappedmem=$cqmappedmem ($(toMB $cqmappedmem))"
echo "        tarmappedmem=$tarmappedmem ($(toMB $tarmappedmem))"
echo "        indexmappedmem=$indexmappedmem ($(toMB $indexmappedmem))"
echo "        jremappedmem=$jremappedmem ($(toMB $jremappedmem))"
echo "        jarmappedmem=$jarmappedmem ($(toMB $jarmappedmem))"
echo "        other=$(( cqmappedmem - tarmappedmem - indexmappedmem - jarmappedmem - jremappedmem ))"
echo "      othermappedmem=$(( cacheactive - cqmappedmem ))"
echo ""
echo "  othermem=$(( total - freemem - kernelmem - procmem - cachemem ))"


 #!/bin/bash

TS=`date +%Y%m%d`

LOG=/data/qa_stats/${TS}_perform_all_log.txt 

echo "Starting all subjects on NIC Archive " | ts > $LOG

PTH=`pwd`
cd /usr/sbin/qa_nic
folders=`ls -t /data/server_share/MRI/proefpersonen`

for f in ${folders[0]}
do
    subs=`ls -t /data/server_share/MRI/proefpersonen/$f`
    
    for s in ${subs[0]} 
    do
	if [ -d "/data/server_share/MRI/proefpersonen/$f/$s" ]; then
	    echo "working on $f / subject $s" 
	    echo "working on $f / subject $s"|ts >> $LOG
	    cp -R /data/server_share/MRI/proefpersonen/${f}/${s} /data/qa_queue
	    sh qa_wrapper.sh
	    rm -rf /data/qa_queue/*
	fi
    done
done

cd $PTH
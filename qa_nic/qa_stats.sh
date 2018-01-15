#!/bin/bash

TMPLOG=$1
REPORT_TYPE=$2

if [ "$#" -eq 2 ]; then
    BXHPATH=$3
else
    BXHPATH=/data/qa_queue
fi

echo "BXHPATH: $BXHPATH
exit

bxh_files=`find $BXHPATH | grep ".bxh$"`

for file in ${bxh_files}
do

    PARFILE=${file%_3D*}.PAR
    if [ ! -e $PARFILE ]; then
	PARFILE=${file%_4D*}.PAR
    fi
    
    study=`grep "Examination name" $PARFILE | awk -F ':' '{print $2}' | tr -d '[[:space:]]'`
    pp_id=${file%_*}
    file_id=${pp_id##*/}
    pp_path=`dirname $pp_id`
    pp_id=${pp_path##*/}

    proto=`grep "Protocol name" $PARFILE | awk -F ':' '{print $2}' | tr -d '[[:space:]]'`
    



TR=`grep "Repetition" $PARFILE | awk -F ':' '{print $2}' | tr -d '[[:space:]]'`

    linestart=`grep -n 'dimension.*type=\"t\"' $file | awk -F ':' '{print $1}' | tr -d '[[:space:]]'`

    if [ -n "$linestart" ]; then
	TRins=`echo $TR | bc -l`
	
	trline=`tail -n +$linestart $file | grep spacing`
	trnum=`tail -n +$linestart $file | grep -n spacing | awk -F ':' '{print $1}'`
	nextsection=`echo $trnum + $linestart | bc -l`
 	presection=`echo $trnum + $linestart -2 | bc -l`
	head -n $presection $file > $file.new
	echo $trline | sed "s#<spacing>\([^<][^<]*\)</spacing>#<spacing>${TRins}</spacing>#" >> $file.new
	tail -n +$nextsection $file >> $file.new
	
	## overwrite old bxh file
	mv $file.new $file
    fi

    outputdir="/data/qa_stats/$study/${pp_id}/${file_id}"
    logfile=${outputdir}/qa_nic_log.txt

    cat $TMPLOG >> $logfile

    mkdir -p $outputdir

    if [[ $proto =~ "PRESTO" ]]; then
	echo "PRESTO SCAN FOUND! " |ts >> $logfile
    fi
    
    ln -sf $pp_path /data/qa_stats/$study/${pp_id}/input

    echo -e "\n"
    echo -e "\n" >> $logfile
    echo "Generating QA Report in ${outputdir} for ${file}" |ts >> $logfile
    echo /usr/sbin/fBIRN/fmriqa_generate2.pl --overwrite --indexnonjs $file $outputdir |ts >> $logfile
    echo "Generating QA Report in ${outputdir} for ${file}"


    if [ "$REPORT_TYPE" == "phantom" ]; then
	echo /usr/sbin/fBIRN/fmriqa_phantomqa.pl --overwrite $file $outputdir |ts >> $logfile
	/usr/sbin/fBIRN/fmriqa_phantomqa.pl --overwrite $file $outputdir |ts >> $logfile
    else
	echo /usr/sbin/fBIRN/fmriqa_generate2.pl --overwrite --indexnonjs $file $outputdir |ts >> $logfile
	/usr/sbin/fBIRN/fmriqa_generate2.pl --overwrite --indexnonjs $file $outputdir |ts >> $logfile
    fi
    
    echo "removing large nii.gz files from report folders" | ts >> $logfile
    rm -f $outputdir/temp*.nii.gz
done
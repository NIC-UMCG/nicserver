#!/bin/bash

echo "Number of arguments : $#"
if [ "$#" -ne "1" ]; then 
    DICOMROOT=/data/qa_queue
    echo "Warning!: Using /data/qa_queue for input..."
else
    DICOMROOT=$1
fi

if [ -z $DICOMROOT ]; then
    echo "Incorrect DICOM root".
    exit
fi

dicomdirs=`find $DICOMROOT/ | grep "DICOMDIR" `

if [ "$#" -eq 2 ]; then
    TMPLOG=$2
else
    TMPLOG=/data/qa_queue/tmp.log
fi

if [ -z "$dicomdirs" ]; then
    echo "NO DATA!"
fi



for dicomdir in ${dicomdirs[*]}
do        
    echo -e "\t*) Found $dicomdir"
    
    filepath=${dicomdir%/*}    
    dicom_project=${filepath##*/}	    
    dicompath="$filepath/DICOM/"
    bxh_out=$filepath/${dicom_project}.bxh
    echo "Converting from DICOM ($file) to BXH : $bxh_out" | ts >> $TMPLOG
    echo /usr/sbin/fBIRN/dicom2bxh $dicompath/ $bxh_out &> $TMPLOG

    echo -e "\t   Converting from DICOM ($file) to BXH : $bxh_out" 
    im_files_rec=($dicompath/*/IM*)
    im_files=($dicompath/IM*)
    rm $bxh_out
    /usr/sbin/fBIRN/dicom2bxh  ${im_files[*]} ${im_files_rec[*]} $bxh_out 
    


done
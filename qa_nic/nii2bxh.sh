#!/bin/bash

files=`find /data/qa_queue/ | grep ".nii$"`

TMPLOG=/data/qa_queue/tmp.log

for file in ${files[*]}
do        
    filepath=${file%/*}
    filename=${file##*/}
    filebase=${filename%.*}
    echo $filepath $filebase
    
    bxh_out=$filepath/$filebase.bxh
    
    echo "Converting from nii ($file) to nii.gz" |ts >> $TMPLOG
    gzip $file

    echo "Converting from nii ($file) to BXH : $bxh_out" | ts >> $TMPLOG
    bxhabsorb --fromtype analyze ${file}.gz $bxh_out

done
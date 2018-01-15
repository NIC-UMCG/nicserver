#!/bin/bash

echo "======================================================="
echo "        Quality assurance measures for fMRI"
echo "                                           _  _ _  ___ "
echo "                                          | \| (_)/ __|"
echo "                                          | .\` | | (__ "
echo "                                          |_|\_|_|\___|"
echo "                         NeuroImaging Center Groningen"  
echo "                   University Medical Center Groningen"
echo ""
echo "script version: 1.0"
echo "date :          7/4/2016"
echo "author:         J.B.C. Marsman, j.b.c.marsman@umcg.nl"
echo "======================================================"

REPORT_TYPE=subject

if [ $# -eq 0 ];
then 
    while true; do
	echo "=============================================="	
	echo "What type of report do you want to generate? :"
	echo ""
	echo "1) Report for subject (using qa_fmri_generate.pl)"
	echo ""
	echo "2) Report for phantom (using qa_fmri_phantom.pl)"
	echo ""
	read -p "-> Your choice :" type
	
	case $type in
	    [1]* ) REPORT_TYPE=subject; break;;
	    [2]* ) REPORT_TYPE=phantom; break;;
	esac
    done
else
    case $1 in
	[phantom]* ) REPORT_TYPE=phantom;; 
	[subject]* ) REPORT_TYPE=subject;;
    esac
fi

echo "======================================================"
echo "   Generating $REPORT_TYPE report"
echo "======================================================"

PTH=`pwd`
cd /usr/sbin/qa_nic
TMPLOG=/data/qa_queue/tmp.log

## CONVERT ALL PARREC TO NIFTI TO BXH
##echo "Convert PARREC to Nifti" |ts >> $TMPLOG
##./parrec2nii.sh

echo "Convert Nifti to BXH" | ts >> $TMPLOG
##./nii2bxh.sh
./nii2bxh_rr.sh

## COMVERT ALL DICOM TO BXH
echo "Convert DCM to BXH" | ts >> $TMPLOG
./dicom2bxh.sh

## CALCULATE QA STATS FOR ALL BXH FILES
echo "Calculate QA stats" | ts >> $TMPLOG
./qa_stats_rr.sh $TMPLOG $REPORT_TYPE


cd $PTH

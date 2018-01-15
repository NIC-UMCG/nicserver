#!/bin/bash
set -o nounset
set -o errexit

## options
MEICA_OPT=0
EMAIL_OPT=0
EMAIL_TO=""
CLEANUP_OPT=1
NOTIFY_OPT=0
QC_OPT=0

## FLAGS
TARGET_WRITE=1;

INPUTDIR=""
TMPDIR=""
OUTPUTDIR=$HOME
MEICA_INPUTDIR=""
ME_SETS=0



SUBJECT_ID=""



declare -A IMASETS

report()
{
    if [ "$NOTIFY_OPT" -eq "1" ]; then
	echo -e "message: $1"
    fi
    
    echo -e $1
}


usage()
{
    echo -e "\t#######################################"
    echo -e "\t#                                     #"
    echo -e "\t# YAPS @ NIC v1.0                     #"
    echo -e "\t#  (Yet Another Processing Script)    #"
    echo -e "\t#       august 2017                   #"
    echo -e "\t#                   j.b.c. marsman    #"
    echo -e "\t#######################################"
    echo
    echo -e "\t*) This script converts DICOM files from the Prisma scanner"
    echo -e "\t   using dcm2niix, and optionally meica.py for mult-echo datasets."

    echo
    echo "Usage: "
    echo
    echo -e "[REQUIRED]"
    echo -e "\t-f <folder>\tInput folder"
    echo -e "\t-o <folder>\tOutput folder"
    echo
    echo -e "[OPTIONAL]"
    echo -e "\t-c [0/1]\tCleanup DICOM files after finished (default to 1)"
    echo -e "\t-e <e-mail>\tSend e-mail after finished"
    echo -e "\t-h\t\tPrint this help message"
    echo -e "\t-l [0/1]\tNotify via messages on the desktop (default to 0)"
    echo -e "\t-m\t\tPerform meica.py preprocessing for all multi echo datasets"
    echo -e "\t-q\t\tPerform optional quality checks using fBIRN toolkit"


    echo
}

## If data is stored on the server share, it should be copied via /tmp
test_ownership()
{
    echo $INPUTDIR
    if [[ "${INPUTDIR}" =~ "server_share" ]]; then
	echo
	echo "*) The provided source folder is on the server share --> Copying to your output directory via /tmp"	
	echo

	# reset INPUTDIR
	
	# TODO: Check for ending with slash!!!
	TARGET_WRITABLE=0

    fi

}    

copy_data()
{
    report "*) Copying files"


    #if [ "$TARGET_WRITABLE" == 0 ]; then
    #LASTFOLDER=${INPUTDIR##*/}	
    #INPUTDIR="/tmp/$LASTFOLDER"
    #	TMPDIR=$INPUTDIR
    #fi


    cpa -R --progress $INPUTDIR /tmp/	
    
	# reset INPUTDIR
    LASTFOLDER=${INPUTDIR##*/}	
    INPUTDIR="/tmp/$LASTFOLDER"
    TMPDIR=$INPUTDIR
        # locate the P-number
    
    for item in `echo $INPUTDIR | tr '/' '\n' `; do
	if [[ "$item" =~ P[0-9]{4} ]]; then
	    SUBJECT_ID=$item
	    report "*) Extracted subject_id : $item"
	    echo
	fi
    done	    	    
}

invalid_arguments_answer()
{    
    echo -e "\tThat's a no-brainer :)"
    echo
    echo -e "\tThe following error occurred: invalid arguments."
    echo    
}

## read json parameter
read_json_param() 
{

    FILE_IN=${1:-};
    KEY=${2:-}
    if [ -f "$FILE_IN" ]; then
	value=`cat $FILE_IN | python -c "import sys,json; print(json.load(sys.stdin)['$KEY'])" `
	echo "${value}";
    fi
}

## sub routine for sending out email, once finished
send_mail()
{
    user=`whoami`
    now=`date`

    C="Dear $user,\n\nI finished converting /processing at $now.\n"

    if [[ "$MEICA_OPT" -eq 1 ]];  then
        C=$C."There were $ME_SETS multi-echo datasets, which I also ran through meica.py"
    fi

    C=$C."\nKind regards,\n\nthe nicserver"

    # echo $C
    echo -e $C | mail -s "Conversion/processing has finished for $SUBJECT_ID." $EMAIL_TO   
    report "*) Mail has been sent."
}

## cleanup routine for DICOM files
cleanup() {
    echo
    report "*) Cleaning up"
    echo
    echo -e "\t+) Removing empty logfiles"
    echo

    logfiles=`find $LOGDIR`
    for logfile in ${logfiles[*]}
    do
	if [ ! -s "$logfile" ]; then
	    rm $logfile
	fi
    done

    echo -e "\t+) Moving logfiles from temp directory to $OUTPUTDIR/$SUBJECT_ID" 
    mv $LOGDIR $OUTPUTDIR/$SUBJECT_ID --backup=numbered
    echo

    echo -e "\t+) Cleaning up temp directory"
    rm -rf $TMPDIR
    echo

}

## subroutine for conversion to dicom
convert_to_nii() {
    
    LOGDIR=$INPUTDIR/.nic_log
    mkdir -p $LOGDIR
    
    IMAFILECOUNT=`find $INPUTDIR | grep ".IMA$" | wc -l`
    IMAFILES=`find $INPUTDIR | grep ".IMA$"`
    
    if [ "$IMAFILECOUNT" -eq "0" ]; then
	report "*) Error : no DICOM files found in $INPUTDIR"
	exit 1
    else
	report "*) Found $IMAFILECOUNT DICOM files in $INPUTDIR"
    fi    
    echo


    
    rm -f $LOGDIR/.imadirs.txt
    rm -f $LOGDIR/conversion.*
    rm -f $LOGDIR/*.dcm2nii.log
    c=0

    for i in ${IMAFILES[*]}
    do
	filedir=${i%/*}
	filename=${i##*/}
	  
	echo ${i%/*} >> $LOGDIR/.imadirs.txt
    done

    unique_ima_files=( `cat $LOGDIR/.imadirs.txt | uniq` )
    echo -e "*) Scans found in the following directory :\n"
    for imaset in ${unique_ima_files[*]}
    do
	echo -e "\to) $imaset"
	
    ## running dcm2niix on folders:
    done
    echo

    report "*) Converting each directory using dcm2niix :\n"
    
    for imaset in ${unique_ima_files[*]}
    do
	imafile=${imaset##*/}

        dcm2niix -b y $imaset 2>> $LOGDIR/$imafile.dcm2nii.err 1>> $LOGDIR/conversion.output

	echo "dcm2niix -b y $imaset > $LOGDIR/$imaset.dcmi2nii.log 2>> $LOGDIR/$imaset.dcm2nii.err" >> $LOGDIR/conversion.cmd
	echo -e "\to) $imaset converted"

	OUTPUTFILECOUNTER=$( cat $LOGDIR/conversion.output | grep $imaset | grep "Convert" | grep "as" | awk "{print \$5}" | wc -l )       
	OUTPUTFILES=$( cat $LOGDIR/conversion.output | grep $imaset | grep "Convert" | grep "as" | awk "{print \$5}" )	
	
	if [ "$OUTPUTFILECOUNTER" -gt "0" ]; then
	    for outputfile in ${OUTPUTFILES[*]}
	    do	    
		echo "$imaset;$outputfile" >> $LOGDIR/conversion.files
	    done
	fi
    done
    
}

organize()
{
    echo 
    report "*) Organizing data"
    
    rm -f $LOGDIR/.timestamps.*
    rm -f $LOGDIR/organizing.*

    unique_ima_files=( `cat $LOGDIR/.imadirs.txt | uniq` )

    # first, create a small text file to order based on timestamp
    for imaset in ${unique_ima_files[*]}
    do
	OUTPUTFILECOUNTER=$( cat $LOGDIR/conversion.output | grep $imaset | grep "Convert" | grep "as" | awk "{print \$5}" | wc -l )
	OUTPUTFILES=( $( cat $LOGDIR/conversion.output | grep $imaset | grep "Convert" | grep "as" | awk "{print \$5}" ) )
	
	if [ "$OUTPUTFILECOUNTER" -gt "0" ]; then	    
	    outputfile="${OUTPUTFILES[0]}"
	    jsonfile=${outputfile%.nii}.json
	    
	    timestamp=$(read_json_param $jsonfile "AcquisitionTime")
	    echo -e "$timestamp; $imaset" >> $LOGDIR/.timestamps.txt
	fi
    done
    
    sort -n -t ":" -k1 -k2 -k3 $LOGDIR/.timestamps.txt | uniq -w 16 | grep -v "_e3\|_e2" > $LOGDIR/.timestamps.sorted.txt 

    measurement=1    
    for imaset in `cat $LOGDIR/.timestamps.sorted.txt | awk '{print $2}'`  ##${unique_ima_files[*]}
    do
	OUTPUTFILECOUNTER=$( cat $LOGDIR/conversion.output | grep $imaset | grep "Convert" | grep "as" | awk "{print \$5}" | wc -l )
	OUTPUTFILES=( $( cat $LOGDIR/conversion.output | grep $imaset | grep "Convert" | grep "as" | awk "{print \$5}" ) )

	if [ "$OUTPUTFILECOUNTER" -gt "0" ]; then	    
	    outputfile="${OUTPUTFILES[0]}"	    
	
	    jsonfile=${outputfile%.nii}.json
	    timestamp=$(read_json_param $jsonfile "AcquisitionTime")
	    name_id=$(read_json_param $jsonfile "ProtocolName")
            measurement_id=$(printf "%02d" $measurement)
	    
	    timestring=`echo "${timestamp%.*}" | sed "s/:/_/g"`
	    foldername="${measurement_id}_${name_id}_${timestring}"
	    scan_outputdir=$OUTPUTDIR/$SUBJECT_ID/$foldername
	    
	    mkdir -p $scan_outputdir
	    
	    for outputfile in ${OUTPUTFILES[*]}
	    do	    
		mv ${outputfile}.nii $scan_outputdir
		mv ${outputfile}.json $scan_outputdir
		echo "mv ${outputfile}.nii $scan_outputdir" >> $LOGDIR/organizing.txt
		echo "mv ${outputfile}.json $scan_outputdir" >> $LOGDIR/organizing.txt
		

	    done
	    
	    let "measurement = $measurement + 1"
	fi
    done

    MEICA_INPUTDIR=$OUTPUTDIR/${SUBJECT_ID}    
}

read_te()
{
    te=$(read_json_param $1 "EchoTime")
    echo "${te}"
}

## sub-function to run a meica analysis
run_meica()
{
    
    report "*) Running meica.py for multi-echo datasets :\n"

    # cleanup of previous attempts 
    MEFILECOUNT=`find $MEICA_INPUTDIR | grep "funct_e*.*"| wc -l`
    
    if [ "$MEFILECOUNT" -gt "0" ]; then
	rm -rf `find $MEICA_INPUTDIR | grep "funct_e*.*"`
    fi

    # Count the ME-data sets: 
    ALL_MES=( `find $MEICA_INPUTDIR | grep "_e[1-3]*.nii" | grep -v ".meica"  ` )
    
    i=0
    for me in ${ALL_MES[*]}
    do
	me_folder[$i]=${me%/*}
	let "i=$i+1"
    done
    
    ME_NII=( `for f in ${me_folder[*]}; do echo $f ; done | uniq` )
    
    echo -e "\t+) Found ${#ME_NII[@]} multi-echo datasets :\n"

    for me_nii in ${ME_NII[*]}
    do	
	echo -e "\t\to) $me_nii"
    done

    mc=1

    echo
    echo -e "\t+) Starting meica.py program :\n"

    ## for all ME runs, prepare and run meica

    ## NB: me_nii is a directory
    for me_nii in ${ME_NII[*]}
    do

	me_dir=$me_nii
	me_file=${me_nii##*/}
	
	echo -e "\t\to) $me_nii"
		
	cd ${me_dir}

	# cleanup previous links / attempts
	rm -f funct_e*.*
	rm -rf .meica_logs
	mkdir -p .meica_logs
	
	jsonfiles=`ls *.json`	
	
	## read every json file, and extract TE parameter (this is stored in te_list.txt)
	for jsonfile in ${jsonfiles[*]}
	do
	    te=$(read_te $jsonfile) 
	    echo "$te,$jsonfile" >> .meica_logs/te_list.txt
	done
	
	## perform sorting based on echo times
	sort -n -t"," -k1 .meica_logs/te_list.txt > .meica_logs/te_list.sorted.txt 

	te_counter=1
	
	## generate links given the ordered echo times and files
	for jsonfile in `cat .meica_logs/te_list.sorted.txt | awk -F ',' '{print $2}' `
	do
	    ln -s ${jsonfile%.json}.nii funct_e${te_counter}.nii
	    ln -s ${jsonfile} funct_e${te_counter}.json
	    echo "ln ${jsonfile%.json}.nii funct_te${te_counter}.nii" >> .meica_logs/renaming.for.meica.txt
	    echo "ln $jsonfile%.json funct_te${te_counter}.json" >> .meica_logs/renaming.for.meica.txt
	    let "te_counter=$te_counter+1" 
	done
	
	# now the scan is named : functional_e1.nii / functional_e2.nii / functional_e3.nii 
	
	te1_s=$(read_te funct_e1.json)
	te2_s=$(read_te funct_e2.json)
	te3_s=$(read_te funct_e3.json)
	
	## report to the user
	te1=`echo "scale=2; $te1_s * 1000" | bc`
	te2=`echo "scale=2; $te2_s * 1000" | bc`
	te3=`echo "scale=2; $te3_s * 1000" | bc`
			
	echo -e "\t\t\t[1] ${te1} ms \t"
	echo -e "\t\t\t[2] ${te2} ms \t"
	echo -e "\t\t\t[3] ${te3} ms \t"
	
	echo 

	me1=funct_e1.nii
	me2=funct_e2.nii
	me3=funct_e3.nii

	## determine number of dynamics
	number_of_volumes=`fslnvols $me1`

	## meica won't work under 15 volumes
	if [[ "${number_of_volumes}" -lt "15" ]]; then
	    report ">> Skipping $me_nii, not enough volumes";
	    continue;
	fi
	    
	## generate a meica script for the given dataset
	echo "#!/bin/bash" > meica.$mc.sh 
	echo >> meica.$mc.sh
	echo "cd $me_dir" >> meica.$mc.sh
	echo "meica.py -d $me1,$me2,$me3 -e $te1,$te2,$te3 > .meica_logs/meica.$mc.log 2> .meica_logs/meica.$mc.err" >>meica.$mc.sh
	
	chmod 755 meica.$mc.sh
        
	## actually run the meica script 
	bash meica.$mc.sh &
	
	let "mc=$mc+1"
	let "ME_SETS = $ME_SETS + 1"
    done
}


## optional quality metrics 
run_qc()
{
    echo 
    report "*) Calculate Quality metrics using fBIRN."
    
    nii_files=`find $OUTPUTDIR/$SUBJECT_ID/ | grep "\.nii" ` 
    for nii_file in ${nii_files[*]}
    do
	nii_dir=${nii_file%/*}
	nii_filename=${nii_file##*/}
	nii_basename=${nii_filename%.*}

	qa_outputdir=$nii_dir/.fbirn
	mkdir -p $qa_outputdir
	
	# Create BXH file format from Nifti
	bxh_file=$qa_outputdir/${nii_basename}.bxh
	bxhabsorb --fromtype analyze ${nii_file} $bxh_file

	# Run fBIRN report
	/usr/sbin/fBIRN/fmriqa_generate2.pl --overwrite --indexnonjs $bxh_file $qa_outputdir |ts >> $qa_outputdir/fbirn.log

    done

}

while getopts "f:hl:mqc::o:" option;
do    
    case $option in

	l) NOTIFY_OPT=${OPTARG:-}
	    ;;
	c) CLEANUP_OPT=${OPTARG:-}	   
	    ;; 
	e) EMAIL_OPT=1
	   EMAIL_TO=$OPTARG
	   ;;
	f) INPUTDIR=${OPTARG:-}
	    ;;
	h) usage
	    ;;
	m) MEICA_OPT=1
	    ;;
	o) OUTPUTDIR=${OPTARG:-}
	    ;;
	q) QC_OPT=1
	    ;; 
    esac
    
done

## test for arguments
if [ "$#" -eq "0" ]; then
    usage
    echo 
    invalid_arguments_answer
    exit
fi


## test input directory
if [ ! -d "${INPUTDIR}" ]; then
    usage
    echo
    echo -e "\tThat's a no-brainer :)"
    echo
    echo -e "\tThe following error occurred: no valid directory specified"
    echo
    echo -e "\tYou supplied : ${INPUTDIR}"
    echo
    exit 1
fi

## test output directory
if [ ! -w "${OUTPUTDIR}" ]; then
    
    ## TODO : mkdir and continue anyway...
    echo 
    echo -e "\tError: Your output directory (${OUTPUTDIR})is not writable, check permissions"
    echo
    exit 1
fi

## main routine

test_ownership
#LOGDIR=$INPUTDIR/.nic_log
copy_data

convert_to_nii

organize



if [[ "${MEICA_OPT}" -eq "1" ]]; then

    run_meica

fi

if [[ "${QC_OPT}" -eq "1" ]]; then

    run_qc
fi

if [[ "${EMAIL_OPT}" -eq "1" ]]; then

    send_mail
fi

if [[ "${CLEANUP_OPT}" -eq "1" ]]; then
    
    cleanup
fi

report "*) Done"
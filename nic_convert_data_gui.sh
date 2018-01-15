#!/bin/bash

zenity --info \ --title="NIC Processing script" --text="<b>Welcome at the GUI for the NIC Conversion/Processing tool</b>\n\n\nPlease select a directory containing DICOM scans made on the Prisma in the following screen : "

INPUTDIR=$( zenity --file-selection --directory --filename=/data/server_share/MRI/Siemens_data/ --title="Select your MRI session" )

if [[ "${INPUTDIR##*/}" == "^[Pp][0-9]{4}" ]]; then
    echo "Correct"
else
    echo "Incorrect"
fi

table=( TRUE, "c", "Cleanup DICOM directory", \
        TRUE, "m", "Perform meica.py preprocessing", \
	FALSE, "q" ,"Calculate quality metrics using fBIRN", \
        FALSE, "e", "Send e-mail after finished")

#zenity --list --checklist --column=yes/no --column=parameter --column=description ${table[*]}

options=$(zenity  --list --width 400 --height 350 --text "What options would you like?" --checklist \
    --column "Yes/no" \
    --column "Parameter" \
    --column "Description" \
    --hide-column=2 \
    TRUE "c" "Cleanup DICOM directory" \
    FALSE "m" "Perform meica.py preprocessing" \
    FALSE "q" "Calculate quality metrics using fBIRN" \
    FALSE "e" "Send an e-mail after processing has finished" --separator=":"); echo $ans


email_opt=`echo $options | grep "e"`
cleanup_opt=`echo $options | grep "c"`
meica_opt=`echo $options | grep "m"`
qa_opt=`echo $options | grep "q"`

PARAMS=""
if [ ! -z "$email_opt" ]; then
    email=$(zenity --entry --text "Please enter your email-address" --entry-text="@umcg.nl")
    PARAMS="$PARAMS -e $email"
fi

OUTPUTDIR=$( zenity --file-selection --directory --filename=~/ --title="Select your output directory" )



if [ ! -z "$cleanup_opt" ]; then
    PARAMS="$PARAMS -c 1"
else
    PARAMS="$PARAMS -c 0"
fi


if [ ! -z "$meica_opt" ]; then
    PARAMS="$PARAMS -m"
fi

if [ ! -z "$qa_opt" ]; then
    PARAMS="$PARAMS -q"
fi

nic_convert_data.sh -l 1 -f $INPUTDIR -o $OUTPUTDIR $PARAMS | zenity --notification --listen




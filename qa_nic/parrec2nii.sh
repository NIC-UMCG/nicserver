#!/bin/bash

CPTH=`pwd`
cd /usr/sbin/qa_nic
matlab -nojvm -nodisplay -nosplash -r parrec2nii 
cd $CPTH

#!/bin/sh

#input check
if [ $# -ne 1 ]
then
  echo "Usage: <hemisphere>\ne.g. ./`basename $0` rh"
  exit 65
fi

#iterate through subjects and labels
for sub in `more subjects.txt`; do

for roi in `more ROI.txt`; do

	label=$SUBJECTS_DIR/${sub}/label/${1}.V1myel_f_${1}_${roi}.label

	if [ -e $label ]; then

		tksurfer $sub $1 inflated -tcl /share/kalanit/users/dfinzi/Desktop/tksurfer_scripting/tk_ls_${1}_${roi}.tcl

	fi
done

done

	


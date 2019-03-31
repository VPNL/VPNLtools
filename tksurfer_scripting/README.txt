--------------------------
TKSURFER SCRIPTING EXAMPLE
--------------------------
DF 3/31/2019
These scripts were designed to solve an annoying freesurfer bug where any labels you create and save in your code don't have surface vertex values and thus are pretty much useless for most things you would then want to do with them. This is easily solved by loading the subject's inflated surface and then loading and resaving the labels by hand but this is a *massive* pain if you have a lot of subjects/labels, hence the scripting. 

Only tested on Linux

--------------
INCLUDED FILES
--------------
1. label_resave_wrapper.sh
2. ROI.txt
3. subjects.txt
4. tk_ls_rh_IOG.tcl (etc etc)

----------
HOW TO USE
----------

To run this, navigate to this folder in terminal and run label_resave_wrapper.sh as follows:
Example: ./label_resave_wrapper.sh rh
Note that the script takes the hemisphere as an argument (rh or lh) and you will be prompted if you forget to include this. 
You will also need to edit the subjects.txt and ROI.txt files based on your needs (I've provided mine as examples). The script will then loop through your subjects and ROIs and execute corresponding .tcl files for each ROI if that label exists for the subject. My .tcl files for my right hemisphere ROIs are provided as examples (see TO-DO). These files currently load (labl_load) and save (labl_save) the label files. Note that for labl_save the first argument is the current label name and the second is your desired output name. You can also rotate the brain to quickly view the label with commands like >> rotate_brain_y 180 (followed by >> redraw) but I generally don't bother. 

NOTE: the .sh file has to be an executable before you can run it so make sure you run >> chmod +777 /yourpath/label_resave_wrapper.sh in the command line beforehand. (This is the same as >> chmod +rwxrwxrwx /yourpath/label_resave_wrapper.sh)

-----
TO-DO
-----
I currently have separate .tcl files for each ROI because it wasn't immediately obvious how to pass variables and I haven't put time into figuring it out. However, this is clearly a stupid way of doing things and should be fixed in the future. 

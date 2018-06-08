function nonlinAlign_4_applyWarp(subject,input,outname,outpath,val)
%
% this code will apply the warp calculated in script -2- to the ROIs
%or niftis you feed, using the alignment files created in
%nonlinAlign_2_createWarp.
%Last script of a series of 4. See first function for example input.
%
% Input:
% subject = name of the subject
% toAlign_in =  file to align to warped anatomy created in script -2-
% aligned_out = file name for warped file
% path = path to directory where the subject's anatomies are kept
% val = value of the ROI
%
% Output:
% warped nifti file
%
% See dependencies and example in nonlinAlign_1_.
% 
% MAB 2016 
% adapted for general lab use May 2018 by MR

toAlign_in = [outpath input];
aligned_out = [outpath outname];

refFile = fullfile(outpath,[subject '_warped.nii.gz']);
%if(strfind(subject,'pm18992'))
%    refFile = fullfile(targetpath,[target '_t1_noCerebellum_resl.nii.gz']); % for pm18992
%end
warpTrans = fullfile(outpath, [subject '1Warp.nii.gz']);
affineMat = fullfile(outpath, [subject '0GenericAffine.mat']);


if exist(toAlign_in, 'file') == 2
    if exist(refFile, 'file') == 2

cmd= ['antsApplyTransforms -d 3 -i ' toAlign_in ' -o ' aligned_out ' -r ' refFile ' -t ' warpTrans ' -t ' affineMat];
display(cmd)
system(cmd)
%% change ROI color (to glittery pink) and threshold 
nii = readFileNifti(aligned_out);

data = nii.data;
% binarize the output of the nonlinear warping
data(data <.4) = 0;
data(data >= .4) = val;

nii.data = data;
nii.fname = aligned_out;
writeFileNifti(nii)

    else
        disp([refFile, ' does not exist. Moving on.']);
    end
else
    disp([toAlign_in ' does not exist. Moving on.']);
    
end




end


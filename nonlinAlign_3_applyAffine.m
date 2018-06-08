function nonlinAlign_3_applyAffine(subject,toTransform,outname,sourcepath,outpath,val)
% This function will apply the affine transform created in
% nonlinAlign_1_createAffine.m to a given ROI or other nifti file. Function 3 in a
% series of 4.
%
% All the relevant files (anatomicals, ROIs and, tranformation files)
% should be in the same directory (this is the path input). 
%
% Input:
% subject = name of the subject directory
% toTransform =  string of ROI or other file that should be aligned
% transformed = string, outputfilename;
% outpath = oath the files of scripts 1 and 2 live in and the ones from
% here will be saved in
% val = the value that should be given to the ROI, e.g. 1, never 0
%
% Output:
% affine aligned input file
%
% See dependencies and example in nonlinAlign_1_.
%
% MAB 2016  
% modified Dec 2017 by MR

%% run 3dAllineate from afni

target = fullfile(outpath,[subject '_affine.nii.gz']);
%if(strfind(subject,'pm18992'))
% target = fullfile(targetpath,['t1_noCerebellum.nii.gz']); % pm18992
% end

roi_in = fullfile(sourcepath, toTransform);
transformed = fullfile(outpath,outname);
xfrm_1D = fullfile(outpath, [subject '.param.1D']);

if exist(roi_in,'file') ~= 2
    roi_in = ['S' roi_in(2:end)];
end

if exist(roi_in, 'file') == 2
    
    if exist(target, 'file') == 2

        cmd = ['3dAllineate -prefix ' transformed ' -base ' target '  -input ' roi_in ' -1Dparam_apply ' xfrm_1D];
        display(cmd)
        system(cmd)

        
        %% change ROI color
nii = readFileNifti(transformed);

data = nii.data;
% clean up the interpolations
%data(data <.3) = 0;
%data(data >= .3) = val;

%nii.data = data;
%nii.fname = transformed;
%writeFileNifti(nii)
        
        
    else
        disp([target, ' does not exist. Moving on.']);
    end
else
    disp([roi_in ' does not exist. Moving on.']);
    
end




end


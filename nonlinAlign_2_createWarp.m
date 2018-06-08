function nonlinAlign_2_createWarp(subject,target,targetpath,outpath,calcReg)
%  This code anatomically aligns the mri volume anatomy of a subject to a
%  target anatomy with nonlinear warping code of the ANTs package.
%
% Input:
% subject = name of the subject that will be aligned
% target = target to align to
% targetpath = path to directory where the target is kept
% outpath = path for affine aligned files and where warping will be saved
% calcReg = 1 or 0, if 1 if calculates the registration files, if 0 it just applies the tranformations
%
% Output:
% nonlinearly warped anatomy nifti
%
% See dependencies and example in nonlinAlign_1_.
% 
% MAB March 2016
%
% adapted for general lab use by MR May 2018

%% runs the ANTs script for volume transformation file generation

outFile = fullfile(outpath, subject);
toalign = fullfile(outpath, [subject  '_affine.nii.gz']);
refFile  = fullfile(targetpath, target);
%if(strfind(subject,'pm18992'))
 %   refFile  = fullfile(targetpath, [target(1:end-7) '_t1_noCerebellum_resl.nii.gz']);
%end

if exist(toalign, 'file') == 2
    if exist(refFile, 'file') == 2

        if calcReg
            cmd = ['antsRegistrationSyNQuick.sh -f ' refFile ' -m ' toalign ' -d 3 -o ' outFile ' -n 12'];
            display(cmd)	
            system(cmd)
        end

% Apply transform
warpTrans = fullfile(outpath, [subject '1Warp.nii.gz']);
affineMat = fullfile(outpath, [subject '0GenericAffine.mat']);
input = toalign;
output = fullfile(outpath, [subject, '_warped.nii.gz']);



cmd= ['antsApplyTransforms -d 3 -i ' input ' -o ' output ' -r ' refFile ' -t ' warpTrans ' -t ' affineMat];
display(cmd)
system(cmd)

    else
        disp([refFile, ' does not exist. Moving on.']);
    end
else
    disp([toalign ' does not exist. Moving on.']);
    
end



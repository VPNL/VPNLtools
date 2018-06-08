function nonlinAlign_1_createAffine(subject,source,target,sourcepath,targetpath,outpath)
% This function uses afni to create an affine alignment file, and aligns a
% brain volume. The first script of a series of 4.
%
%  This code creates an affine tranform to roughly align a volume anatomy to another volume
%  and a transformation file: fullfile(path, [subject '.param.1D']); The .param.1D file
%  will be needed for the function afniApplyAffine.m
%
%  Input:
%  subject = name of the subject that will be aligned. same name in
%  freesurfersegmentations directory and in filename for output
%  source = filename that should be aligned (the anatomy) 
%  target = target file we want to align to 
%   sourcepath = where the file we want to align lives
%   targetpath = where the target volume lives
%   outpath = where the alignment files (.param.1D) and the aligned source
%   should be saved
%
% Output:
% <subject>_affine.nii.gz
% <subject>.param.1D
%
% DEPENDENCIES
% ants and afni: your environment is set up in lines 76-78.
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Example input:
%{
% Theoretically, script 1 and 3 can be run without 2 and 4 if only an
% affine transformation is needed.

sourcepath =  '/biac2/kgs/projects/CytoArchitecture_lateral/data/unsmoothed/';
targetpath = '/biac2/kgs/3Danat/FreesurferSegmentations/';
resultspath = '/biac2/kgs/projects/CytoArchitecture_lateral/data/unsmoothed/';
subjects=  {'newpm295','pm14686', 'pm1696', 'pm18992','pm20784','pm28193','pm38281','pm54491','pm5694','pm6895'};
area =  {'V4la','V4lp','V3a','V3d','V5'};
hemi = {'l','r'};


for s = 1:length(subjects)
    
    source = ['_' subjects{s} 'histo_invNlin_corr_small_histcorr_pad_lin2colin27.nii.gz'];
    target = [subjects{s} '/mri/' subjects{s} '_T1.nii.gz'];
    
    % create affine alignment and align anatomy
    nonlinAlign_1_createAffine(subjects{s},source,target,sourcepath,targetpath,resultspath)
    
    % compute warping to the target volume and warp the affine anatomy
    nonlinAlign_2_createWarp(subjects{s},target,targetpath,resultspath,1)
    
    for h = 1:length(hemi)
        for a = 1:length(area)
            
            roi = [area{a} '_' hemi{h} '_' subjects{s} 'histo_nlin_small_pad_lin2colin27.nii.gz'];
            savename = [area{a} '_' hemi{h} 'h_' subjects{s} '_affine.nii.gz'];

            % apply affine to ROI
            nonlinAlign_3_applyAffine(subjects{s},roi,savename,sourcepath,resultspath,1)
            
            % apply warp to ROI           
            inputname = savename;
            outname = [savename(1:end-13) 'warped.nii.gz'];
            nonlinAlign_4_applyWarp(subjects{s},inputname,outname,resultspath,1)
            disp(['Aligned ROI called ' area{a} ' of subject ' subjects{s} '.']);            
        end
    end
end
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  MAB March 2016
%  adapted by MR Dec 17


%% add ants and afni to your environment
!export ANTSPATH=/usr/lib/ants/
!export PATH=${ANTSPATH}:$PATH
!source /etc/afni/afni.sh

%% run 3dAllineate from afni  -12 param alignment of the volumes
Allineate_out = fullfile(outpath, [subject '_affine.nii.gz']);
inFile = fullfile(sourcepath, source);
oneDparam_out = fullfile(outpath, subject);
refFile = fullfile(targetpath,target);

if exist(refFile, 'file') == 2
    if exist(inFile, 'file') == 2
        cmd = ['3dAllineate -prefix ' Allineate_out ' -base ' refFile ' -input ' inFile ' -cmass -twopass -1Dparam_save ' oneDparam_out];
        display(cmd)
         system(cmd)
    else
        disp([inFile, ' does not exist. Moving on.']);
    end
else
    disp([refFile ' does not exist. Moving on.']);
    
end

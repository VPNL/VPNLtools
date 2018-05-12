function fs_mgzWithROIsToLabels(mgzfile,hemisphere,areaID,areanames,inputdir,outputdir,subjectname,surfacetype)
% mgz2label(mgzfile,hemisphere,areaID,areanames,inputdir,outputdir,subjectname,surfacetype)
% this function converts mgz files that contain multiple ROIs (e.g. the Kastner atlas) to individual label files. both are
% freesurfer file types
%
% INPUT:
% mgzfile: string-  with the mgzfile name
% hemisphere: string
% areaID: vector with intensity values that will be
% areanames: cell string - area names. if empty, the areaIDs will be
% used as file names in combination with the hemisphere
% inputdir: string
% outputdir: string
% subjectname: string - freesurfer subject name in
% FreesurferSegmentations directory
% surfacetype: string - use inflated as default

% OUTPUT:
% label files are saved in outputdirectory specified in 'outdir'
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT EXAMPLE
%
%areaID = [ 1:1:25]; % intensity values of the areas in the mgz file. can be seen when opening the overlap in tksurfer and going over the respective area
%areanames = {'V1v','V1d','V2v','V2d','V3v','V3d','hV4','V01','V02','PHC1','PHC2','MST','hMT','L02','L01','V3b','V3a','IPS0','IPS1','IPS2','IPS3','IPS4','IPS5','SPL1','FEF'}; % if this is empty, labels will have the names of areaID IMPORTANT: has to have same order as the IDs in line above
%inputdir = '/biac2/kgs/3Danat/FreesurferSegmentations/fsaverage-bkup/label/';
%outputdir = ' /biac2/kgs/3Danat/FreesurferSegmentations/fsaverage-bkup/label/entireWangAtlas/';
%subjectname = 'fsaverage-bkup';
%surfacetype = 'inflated';
%mgzfiles = {'Kastner2015Labels-LH.mgz', 'Kastner2015Labels-RH.mgz'};
%hemisphere = {'lh' 'rh'}; % same order as for mgzfiles in row above
% call function to convert mgz file to individual labels
%for m = 1:length(mgzfiles)
    %  mgz2label(mgzfiles{m},hemisphere{m},areaID,areanames,inputdir,outputdir,subjectname,surfacetype)
%end


% MR Sept 2017


if (isempty(areanames))
    areanames = num2str(areaID);
    areanames = strsplit(areanames,' ');
end

if(isempty(mgzfile))
    error('no mgz file input')
end

if(isempty(hemisphere))
    error('please specifiy the hemisphere')
end

if(isempty(areaID))
    error('missing the intensity values to find labels in mgz file')
end

if(isempty(inputdir))
    error('specify input directory')
end

if(isempty(outputdir))
    error('specify output directory')
end

if(isempty(subjectname))
    error('no subject name - what freesurfer subject should be used?')
end

if(isempty(surfacetype))
    surfacetype = 'inflated';
end

for l = 1:length(areaID)
    command = [ 'mri_cor2label --i ' inputdir mgzfile ' --id '  num2str(areaID(l)) ...
        ' --l ' outputdir hemisphere '.' areanames{l} '.label --surf ' subjectname ' ' hemisphere ' ' surfacetype ];
    unix(command)
end

end

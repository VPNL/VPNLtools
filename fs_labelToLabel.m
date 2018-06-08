
function fs_labelToLabel(labelsToAlign,hemisphere,subjects,sourcesubject,sourcelabeldir,labelprefix)
% Label2label(labelsToAlign,hemisphere,subj,sourcesubject,sourcelabeldir,labelprefix)
% this function aligns FreeSurfer labels from a source subject to target subjects
% for example, you can use this function to project a group label (ROI)
% to individual subject brains
%
% INPUT:
% labelsToAlign: cell string - the label names without the hemisphere prefix
% hemisphere: cell string
% subjects: string - target subject (freesurfer segmentation names)
% sourcesubject: string - freesurfer subject name of origin subject
% sourcelabeldir: string
% labelprefix: string - what should be added before the area name, e.g.
%                       adding "WangAtlas" to each area that is
%                       transformed
%
% OUTPUT:
% label files are saved in the label folders of the subjects specified
% in "subj"
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Usage example:
% set params
% sourcesubject = 'fsaverage-bkup';
% sourcelabeldir = '/biac2/kgs/3Danat/FreesurferSegmentations/fsaverage-bkup/label/entireWangAtlas/';
% labelsToAlign = {'V1v','V1d','V2v','V2d','V3v','V3d','hV4','V01','V02','PHC1','PHC2','MST','hMT','L02','L01','V3b','V3a','IPS0','IPS1','IPS2','IPS3','IPS4','IPS5','SPL1','FEF'}; % if this is empty, labels will have the names of areaID IMPORTANT: has to have same order as the IDs in line above
% hemisphere = {'lh' 'rh'}; % 'lh' 'rh' or 'lh rh'
% labelprefix = 'WangAtlas'; % any prefix that should be added to the label
% when its aligned. leave empty otherwise
% subj = {'mr1','mr2'}; % subjects the labels should be aligned to
% run function
%   fs_labelToLabel(labelsToAlign,hemisphere,subj,sourcesubject,sourcelabeldir,labelprefix)
% 
% %%%%  OR:
%
%sourcesubjects =  {'newpm295','pm14686', 'pm1696', 'pm18992','pm20784','pm28193','pm38281','pm54491','pm5694','pm6895'};
%dir = '/biac2/kgs/3Danat/FreesurferSegmentations/';
%labelsToAlign = {'V5','V4la','V4lp','V3a','V3d' };
%hemisphere = {'lh' 'rh'}; % 'lh' 'rh' or 'lh rh'
%subj = {'fsaverage-bkup'}; % subjects the labels should be aligned to
%
%for s = 1:length(sourcesubjects)
%    sourcelabeldir = [dir '/label/'];
%    fs_labelToLabel(labelsToAlign,hemisphere,subj,sourcesubjects{s},sourcelabeldir,sourcesubjects{s})
%end
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% MR Sept 2017, update May 2018


if(isempty(labelsToAlign))
    error('no input labels specified')
end

if(isempty(hemisphere))
    error('specifiy hemisphere')
end

if(isempty(subjects))
    error('specify subjects the labels should be aligned to')
end

if(isempty(sourcesubject))
    error('specifiy source subject')
end


for h = 1:length(hemisphere)
    for s = 1:length(subjects)
        for a = 1:length(labelsToAlign)
        command = [ 'mri_label2label  --srcsubject ' sourcesubject '  --srclabel ' sourcelabeldir hemisphere{h} '.' labelsToAlign{a} '.label '...
            '--trgsubject ' subjects{s} ' --trglabel '  hemisphere{h} '.' labelprefix '_' labelsToAlign{a} '.label --regmethod surface --hemi ' hemisphere{h}];
        unix(command);
        end
    end
end

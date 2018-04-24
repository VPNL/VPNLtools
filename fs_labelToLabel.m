
function label2label(labelsToAlign,hemisphere,subj,sourcesubject,sourcelabeldir,labelprefix)
% Label2label(labelsToAlign,hemisphere,subj,sourcesubject,sourcelabeldir,labelprefix)
% this function aligns FreeSurfer labels from a source subject to target subjects
% for example, you can use this function to project a group label (ROI)
% to individual subject brains
%
% INPUT:
% labelsToAlign: cell string - the label names without the hemisphere prefix
% hemisphere: cell string
% subj: string - target subject (freesurfer segmentation names)
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
% Usage example:
% set params
% sourcesubject = 'fsaverage-bkup';
% sourcelabeldir = '/biac2/kgs/3Danat/FreesurferSegmentations/fsaverage-bkup/label/entireWangAtlas/';
% labelsToAlign = {'V1v','V1d','V2v','V2d','V3v','V3d','hV4','V01','V02','PHC1','PHC2','MST','hMT','L02','L01','V3b','V3a','IPS0','IPS1','IPS2','IPS3','IPS4','IPS5','SPL1','FEF'}; % if this is empty, labels will have the names of areaID IMPORTANT: has to have same order as the IDs in line above
% hemisphere = {'lh' 'rh'}; % 'lh' 'rh' or 'lh rh'
% labelprefix = 'WangAtlas'; % any prefix that should be added to the label
% when its aligned. leave empty otherwise
% subj = {'mr1','mr2'}; % subjects the labels should be aligned to
%
% run function
%   label2label(labelsToAlign,hemisphere,subj,sourcesubject,sourcelabeldir,labelprefix)
% 
%     
% MR Sept 2017


if(isempty(labelsToAlign))
    error('no input labels specified')
end

if(isempty(hemisphere))
    error('specifiy hemisphere')
end

if(isempty(subj))
    error('specify subjects the labels should be aligned to')
end

if(isempty(sourcesubject))
    error('specifiy source subject')
end


for h = 1:length(hemisphere)
    for s = 1:length(subj)
        for a = 1:length(labelsToAlign)
        command = [ 'mri_label2label  --srcsubject ' sourcesubject '  --srclabel ' sourcelabeldir hemisphere{h} '.' labelsToAlign{a} '.label '...
            '--trgsubject ' subj{s} ' --trglabel '  hemisphere{h} '.' labelprefix '_' labelsToAlign{a} '.label --regmethod surface --hemi ' hemisphere{h}];
        unix(command);
        end
    end
end

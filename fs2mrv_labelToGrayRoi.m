
function fslabel2mrVroi(source,targets,subj,area,hem,ProjectDir,niftiDir,varargin)
% fslabel2mrVroi(source,targets,subj,area,hem,ProjectDir,niftiDir,varargin)
% bringing an ROI that is a freesurfer label on the fsaverage brain into
% subject space and then transforming it into mrVista file format to be a
% Gray ROI there
%
% ROIs in mrVista will be in inplane and volume, with the name
% hemisphere_area
% function assumes that the freesurfer directory is
% /biac2/kgs/3Danat/FreesurferSegmentations/
%
% DEPENDENCIES:
% freesurfer version 5.3 or up, mrVista
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT EXAMPLE
%mrVistaDir = '/biac2/kgs/project/facehandsNew/'; % directory where all mrVista files live
%niftiDir = ''; % where should intermediate nifti files are saved?
%hemisphere = {'lh','rh'}; % hemispheres that should be touched
%source = 'fsaverage-bkup'; % assuming here that the labels i want are aligned to one brain, eg 'fsaverage-bkup
%
% tagets are the subjects in the FreesurferSegmentations folder the labels should be aligned to from the source subject (CBA surface alignment from source to target)
%targetsFS = {'kevin_2013', 'kalanit_2013', 'nick','manuel','makiko','moqian','grace','melina','michaelw','michaelp','xiaoting','winawer','gami','kendrick'}; % 'name in anatomy folder (in FreesurferSegmentations)
%
%targetsmrV HAS TO HAVE SAME ORDER AS TARGETS - the subjects the labels should be aligned to in mrVista
%targetsmrV = {'s4_kw_new','s5_kgs', 's6_nd_new', 's10_mh_new','s12_mf_new','s13_mt_new','s14_gt_new', 's15_mu_new','s16_mw_new','s17_mp_new','s18_xw_new', 's19_jw_new', 's20_gtg_new','s21_kk_new'};
%
%area = {'Wang_v1'}; % list of  labels that will be aligned in freesurfer and converted to mrVista ROIs, without the hemisphere as prefix, e.g. 'Wang_v1'. has to be in the /label/ directory of the source subject
%
% run the function
%fslabel2mrVroi(source,targetsFS,targetsmrV,area,hemisphere,mrVistaDir,niftiDir)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% MR Aug 2017

path = '/biac2/kgs/3Danat/';
FSdir = [path 'FreesurferSegmentations/'];

if(~isunix)
    if(~isempty(varargin))
        path = [varargin{1},path];
    else
        error('Since you are not on a unix system, please specify the path up to /biac2/')
    end
else
    if(~isempty(varargin))
        path = [varargin{1},path];
    end
end

%% prepare freesurfer files to be ready for script that transforms the ROI into a mrVista ROI - run on server
for h = 1:length(hem)
    for s = 1:length(targets)
        dir = [FSdir targets{s} '/'];
        
        for a = 1:length(area)
            
            % bring label from fsaverage space to subject space
            targetlabel =  [hem{h} '.' area{a} '.alignedTo.' targets{s} '.label']; % name it will have
            command = [ 'mri_label2label  --srcsubject ' source ' --srclabel ' FSdir '/' source '/label/' hem{h} '.' area{a}  '.label  --trgsubject ' targets{s} ' --trglabel ' targetlabel ' --regmethod surface --hemi ' hem{h}];
            a = unix(command);
            
            if a>0
                error('Something went wrong, check the freesurfer error message in the command window above.');
            end
            
            % convert the label to a nifti file
            outname = [hem{h} '.' area{a} '.alignedTo.' targets{s} '.nii.gz'];
            % convert label to volume
            command = ['mri_label2vol --label ', dir, 'label/', targetlabel ' --temp ', FSdir, targets{s}, '/mri/orig.mgz', ' --reg ', dir, 'label/register.dat --proj frac 0 1 .1  --fillthresh 0.1  --subject ', targets{s}, ' --hemi ', hem{h}, ' --o ', ProjectDir, outname ] ;
            a = system(command);
            
            if a>0
                error('Something went wrong, check the freesurfer error message in the command window above.');
            end
            
            % reslice like mrVista anatomy
            toConvert = [ProjectDir outname];
            fileToBe = [niftiDir hem{h} '.' area{a} '.alignedTo.' targets{s} '_rl.nii.gz' ];
            reffile = [path targets{s} '/t1.nii.gz'];
            
            command = ['mri_convert -ns 1 -rt nearest -rl  ',reffile, ' ', toConvert, ' ', fileToBe ];
            a = unix(command)
            
            if a>0
                error('Something went wrong, check the freesurfer error message in the command window above.');
            end
            
        end
    end
end

%%  load into mrVista
if varargin
    addpath(genpath([varagin{1}, '/biac2/kgs/projects/CytoArchitecture/segmentations/code']));
else
    addpath(genpath('/biac2/kgs/projects/CytoArchitecture/segmentations/code'));
end

cd(ProjectDir)

for s = 1:length(subj)
    % dir = [FSdir targets{s} '/'];
    cd(subj{s})
    for h = 1:length(hem)
        for a = 1:length(area)
            % read in nifti file
            ni = readFileNifti([niftiDir hem{h} '.' area{a} '.alignedTo.' targets{s} '_rl.nii.gz']);
            
            fname = [hem{h} '_' area{a} '.mat' ];
            
            spath = [ProjDir subj{s} '/Anat/ROIs/'];
            ROI = niftiROI2mrVistaROI(ni, 'name', fname, 'spath', spath, 'color', 'm', 'layer', 2);   % function lives in: /projects/CytoArchitecture/segmentations/code.
            
            h3 = initHiddenGray('GLM',1,fname);
            
            hI = initHiddenInplane('GLMs',1);
            hI = vol2ipCurROI(h3,hI);
            saveROI(hI)
            
            
        end
    end
    cd ..
end

%%

%mrVista
%INPLANE{1} = loadROI(INPLANE{1}, 'lh_Kastner_hV4'); INPLANE{1} = refreshScreen(INPLANE{1});
%INPLANE{1} = loadROI(INPLANE{1}, 'lh_CoS_Weiner'); INPLANE{1} = refreshScreen(INPLANE{1});



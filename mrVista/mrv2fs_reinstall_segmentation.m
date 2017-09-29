function mrv2fs_reinstall_segmentation(wm_path, fs_id)
% Reinstalls Freesurfer segmentation using edited mrVista class file.
%
% Inputs
%   wm_path: path to class file for a session 
%   fs_id: name of subject directory in FreesurferSegmentations
% 
% AS 9/2017

% path to subject data in FreesurferSegmentations
fsDir = fullfile(RAID, '3Danat', 'FreesurferSegmentations', fs_id);
mri_dir = fullfile(fsDir,'mri'); surf_dir = fullfile(fsDir,'surf');

% copy white matter (class) file to FreeSurfer and rename wm.mgz
copyfile(wm_path, fullfile(mri_dir, 't1_class.nii.gz'));
movefile(fullfile(mri_dir, 'wm.mgz'), fullfile(mri_dir, 'wm.old.mgz'));

% reinstall segmentation from mrVista class file and copy register file
unix(['mri_convert -ns 1 -rt nearest -rl ' mri_dir '/orig.mgz ' ...
    mri_dir '/t1_class.nii.gz '  mri_dir '/wm.mgz --conform']);
unix(['recon-all -autorecon2-wm -subjid ' fs_id]);
unix(['recon-all -autorecon3 -subjid ' fs_id]);
unix(['tkregister2 --mov ' mri_dir '/orig.mgz --noedit --regheader ' ...
    '--reg ' mri_dir '/register.dat --s ' fs_id]);
movefile(fullfile(mri_dir, 'register.dat'), fullfile(surf_dir,'register.dat'));

end


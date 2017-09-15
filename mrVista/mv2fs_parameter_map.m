function out_paths = mv2fs_parameter_map(map_path, fs_id, cba_flag)
% Transforms a mrVista paramter map into FreeSurfer-compatible .mgh files.
%
% Inputs
%   map_path: path to .mat file storing mrVista parameter 
%   fs_id: name of subject directory in FreesurferSegmentations
%   cba_flag: option to transform the map to fsaverage using CBA
%
% Output
%   out_paths: cell array of paths to all output .mgh files
% 
% AS 9/2017

% check inputs and initalize cell to store paths to FreeSurfer output
fs_dir = fullfile(RAID, '3Danat', 'FreesurferSegmentations', fs_id);
if ~ exist(fs_dir, 'dir') == 7
    error('fs_id not found in FreesurferSegmentations');
end
if nargin < 3
    cba_flag = 0;
end
if cba_flag == 1
    out_paths = cell(2, 2);
else
    out_paths = cell(1, 2);
end

% path to subject data in FreesurferSegmentations
fs_dir = fullfile(RAID, '3Danat', 'FreesurferSegmentations', fs_id);
mri_dir = fullfile(fs_dir, 'mri'); surf_dir = fullfile(fs_dir, 'surf');

% generate paths to mrVista session directories and FreeSurfer output
[session_dir, ~] = fileparts(fileparts(fileparts(map_path)));
[~, dt] = fileparts(fileparts(map_path));
[~, map_name] = fileparts(map_path);
out_path = fullfile(mri_dir, [map_name '.nii.gz']);
home_dir = pwd;

% generate FreeSurfer parameter map file from mrVista parameter map
cd(session_dir);
hg = initHiddenGray(dt, 1);
hg = loadParameterMap(hg, map_path);
hg = loadAnat(hg);
functionals2itkGray(hg, 1, out_path);
cd(mri_dir);
unix(['mri_convert -ns 1 -odt float -rt nearest -rl orig.mgz ' ...
    map_name '.nii.gz ' map_name '.nii.gz --conform']);
movefile(out_path, fullfile(surf_dir, [map_name '.nii.gz']));

% generate FreeSurfer surface files for each hemisphere
cd(surf_dir);
unix(['mri_vol2surf --mov ' map_name '.nii.gz ' ...
    '--reg register.dat --hemi lh --interp nearest --o ' ...
    map_name '_lh.mgh --projdist 2']); % left hemi
unix(['mri_vol2surf --mov ' map_name '.nii.gz ' ...
    '--reg register.dat --hemi rh --interp nearest --o ' ...
    map_name '_rh.mgh --projdist 2']); % right hemi
out_paths{1, 1} = fullfile(pwd, [map_name '_lh.mgh']);
out_paths{1, 2} = fullfile(pwd, [map_name '_rh.mgh']);

% transform surface files to fsaverage if selected
if cba_flag == 1
    fsa_dir = fullfile(RAID, '3Danat', 'FreesurferSegmentations', 'fsaverage');
    map_stem = fullfile(fsa_dir, 'surf', map_name);
    unix(['mri_surf2surf --srcsubject ' fs_id ' --srcsurfval ' ...
        map_name '_lh.mgh --trgsubject fsaverage --trgsurfval ' ...
        map_stem '_lh_regFrom_' fs_id '.mgh --hemi lh']); % left hemi
    unix(['mri_surf2surf --srcsubject ' fs_id ' --srcsurfval ' ...
        map_name '_rh.mgh --trgsubject fsaverage --trgsurfval ' ...
        map_stem '_rh_regFrom_' fs_id '.mgh --hemi rh']); % right hemi
    out_paths{2, 1} = fullfile(fsa_dir, [map_stem '_lh_regFrom_' fs_id '.mgh']);
    out_paths{2, 2} = fullfile(fsa_dir, [map_stem '_rh_regFrom_' fs_id '.mgh']);
end

% return to starting location
cd(home_dir);

end

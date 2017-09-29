%% specify paths to data directories and inputs files
data_dir = fullfile(RAID, 'projects', 'flicker', 'data');
sessions = {'as091515_ret' 'jg100515_ret' 'kg100515_ret'}; % mrVista sessions
fs_ids = {'anthony_avg_1mm' 'jesse' 'kalanit_2013'}; % Freesurfer directories
data_type = 'MotionComp_RefScan1'; % mrVista data type storing map
map_names = {'TBeta' 'SBeta'}; % stems of mrVista parameter map names

%% loop through sessions and transform maps to fsaverage using CBA
out_paths = cell(length(sessions), length(map_names)); home_dir = pwd;
for ss = 1:length(fs_ids)
    fs_id = fs_ids{ss}; session = sessions{ss};
    % generate FreeSurfer-compatible files from mrVista parameter maps
    for mm = 1:length(map_names)
        map_name = map_names{mm}; % name of a mrVista parameter map file
        map_path = fullfile(data_dir, session, 'Gray', data_type, [map_name '.mat']);
        out_paths{ss, mm} = mrv2fs_parameter_map(map_path, fs_id, 1);
    end
end

%% average surface maps across all subjects
cd(fullfile(RAID, '3Danat', 'FreesurferSegmentations', 'fsaverage', 'surf'));
for mm = 1:length(map_names)
    map_name = map_names{mm};
    unix(['mri_concat --i ' map_name '_lh_regFrom_*.mgh --o ' ...
        map_name '_lh_concat.mgh --mean']); % left hemi    
    unix(['mri_concat --i ' map_name '_rh_regFrom_*.mgh --o ' ...
        map_name '_rh_concat.mgh --mean']); % right hemi
    % generate nifti version of average files to check in Matlab
    unix(['mri_surf2vol --surfval ' map_name '_lh_concat.mgh ' ...
        '--hemi lh --fillribbon --o ' map_name '_lh_concat.nii.gz ' ...
        '--reg register.dat --template ../mri/orig.mgz']); % left hemi
    unix(['mri_surf2vol --surfval ' map_name '_rh_concat.mgh ' ...
        '--hemi rh --fillribbon --o ' map_name '_rh_concat.nii.gz ' ...
        '--reg register.dat --template ../mri/orig.mgz']); % right hemi
end

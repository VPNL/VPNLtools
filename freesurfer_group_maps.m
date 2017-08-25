%% store paths to data directories and copy necessary files
anat_ids = {'anthony_avg_1mm' 'jesse' 'kalanit_2013'};
fs_ids = {'anthony_avg_1mm' 'jesse' 'kalanit_2013'};
fsa_dir = fullfile(RAID, '3Danat', 'FreesurferSegmentations', 'fsaverage');
ret_sessions = {'as091515_ret' 'jg100515_ret' 'kg100515_ret'};
map_names = {'TBeta' 'SBeta'};

%% loop through sessions and transform maps to fsaverage surfaces using CBA
for ss = 1:length(anat_ids)
    anat_id = anat_ids{ss}; fs_id = fs_ids{ss}; ret_session = ret_sessions{ss};
    % path to subject data in 3Danat
    anat_dir = fullfile(RAID, '3Danat', anat_id);
    % path to subject data in FreesurferSegmentations
    fs_dir = fullfile(RAID, '3Danat', 'FreesurferSegmentations', fs_id);
    % paths to subject mri and surf directories
    mri_dir = fullfile(fs_dir, 'mri'); surf_dir = fullfile(fs_dir, 'surf');
    % path to subject retinotopy session
    ret_dir = fullfile(RAID,'projects', 'flicker', 'data', ret_session);
    % generate parameter map files from mrVista parameter maps
    for mm = 1:length(map_names)
        map_name = map_names{mm}; % name of a mrVista parameter map file
        map_path = fullfile(ret_dir, 'Gray' ,'Averages', [map_name '.mat']);
        out_path = fullfile(mri_dir, [map_name '.nii.gz']);
        % convert mrVista parameter map into nifti
        cd(ret_dir);
        hg = initHiddenGray('Averages', 1);
        hg = loadParameterMap(hg, map_path);
        hg = loadAnat(hg);
        functionals2itkGray(hg, 1, out_path);
        cd(mri_dir);
        unix(['mri_convert -ns 1 -odt float -rt nearest -rl orig.mgz ' ...
            map_name '.nii.gz ' map_name '.nii.gz --conform']);
        movefile(out_path, fullfile(surf_dir, [map_name '.nii.gz']));
        % generate freesurfer-compatible surface files for each hemisphere
        cd(surf_dir);
        unix(['mri_vol2surf --mov ' map_name '.nii.gz ' ...
            '--reg register.dat --hemi lh --interp nearest --o ' ...
            map_name '_lh.mgh --projdist 2']); % left hemi
        unix(['mri_vol2surf --mov ' map_name '.nii.gz ' ...
            '--reg register.dat --hemi rh --interp nearest --o ' ...
            map_name '_rh.mgh --projdist 2']); % right hemi
        % transform surface files to fsaverage
        map_stem = fullfile(fsa_dir, 'surf', map_name);
        unix(['mri_surf2surf --srcsubject ' fs_id ' --srcsurfval ' ...
            map_name '_lh.mgh --trgsubject fsaverage --trgsurfval ' ...
            map_stem '_lh_regFrom_' fs_id '.mgh --hemi lh']); % left hemi
        unix(['mri_surf2surf --srcsubject ' fs_id ' --srcsurfval ' ...
            map_name '_rh.mgh --trgsubject fsaverage --trgsurfval ' ...
            map_stem '_rh_regFrom_' fs_id '.mgh --hemi rh']);
    end
end

%% average surface maps across all sessions
cd(fullfile(RAID, '3Danat', 'FreesurferSegmentations', 'fsaverage', 'surf'));
for mm = 1:length(map_names)
    map_name = map_names{mm};
    unix(['mri_concat --i ' map_name '_lh_regFrom_*.mgh --o ' ...
        map_name '_lh_concat.mgh --mean']); % left hemi    
    unix(['mri_concat --i ' map_name '_rh_regFrom_*.mgh --o ' ...
        map_name '_rh_concat.mgh --mean']); % right hemi
    % generate nifti version of average files to check in matlab
    unix(['mri_surf2vol --surfval ' map_name '_lh_concat.mgh ' ...
        '--hemi lh --fillribbon --o ' map_name '_lh_concat.nii.gz ' ...
        '--reg register.dat --template ../mri/orig.mgz']);
    unix(['mri_surf2vol --surfval ' map_name '_rh_concat.mgh ' ...
        '--hemi rh --fillribbon --o ' map_name '_rh_concat.nii.gz ' ...
        '--reg register.dat --template ../mri/orig.mgz']);
end

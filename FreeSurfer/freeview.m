function freeview(varargin)
% MATLAB code for scripting cortical surface visualizations using the
% freeview package included with FreeSurfer. The function is called with 
% eight optional arguments ordered as follows: 
% 
% OPTIONAL INPUTS
% 1) subj: name of subject (default = 'fsaverage')
% 2) hemi: hemisphere (default = 'lh')
%      'lh' = left hemisphere
%      'rh' = right hemisphere
% 3) vw: viewing angle to initialize surface (default = 'm')
%      'm' = medial
%      'l' = lateral
%      'v' = ventral
%      'd' = dorsal
%      'vm' = ventromedial
%      'dl' = dorsolateral
%      'vl' = ventrolateral
% 4) map_name: name of parameter map in subject's surf directory (.mgh)
% 5) thresh: overlay thresholding parameters ([low mid high])
%      low = lower bound of transparent portion of colormap
%      mid = lower bound of opaque portion of colormap
%      high = upper limit of opaque portion of colormap
% 6) zoom: scale factor for camera zoom (default = 1.5)
% 7) surf: FreeSurfer surface name (default = 'inflated')
% 8) screenshot: whether or not to save a screenshot (default = false)
%
% NOTES
% 1) Default parameters are used for inputs that are omitted or set to [].
% 2) Freeview colors the gyri and sulci red and green by default unless a
%    parameter map is loaded, in which case the curvature map is shown with
%    a nicer looking binary grayscale. To force the binary curvature map in
%    both cases, a dummy map is loaded and then hidden using thresholding
%    when map_name is not defined by the user. 
% 3) If screenshot = true, then a file named 'subj_hemi_vw_map_name.png'
%    is written to your current directory and the freeview window is
%    automatically closed. This is useful for batch processing.
% 
% Usage with default settings: 
% freeview(subj, hemi, vw, map_name, thresh, zoom, surf, screenshot)
% freeview('fsaverage', 'lh', 'm', [], [], 1.5, 'inflated', false)
% 
% AS 2/2017


%% setup defaults

% store paths to current working directory and segmentation directory
cwd = pwd; fs_dir = fullfile(RAID,'3Danat', 'FreesurferSegmentations');
% check input list and set default parameters when applicable
numvarargs = length(varargin);
if numvarargs > 8; error('Too many input arguements'); end
optargs = {'fsaverage' 'lh' 'm' [] [] 1.5 'inflated' false};
optargs(1:numvarargs) = varargin;
[subj, hemi, vw, map_name, thresh, zoom, surf, screenshot] = optargs{:};

%% check inputs and apply defaults for emptpy arguements

% check for subj in FreesurferSegmentations directory
if isempty(subj); subj = 'fsaverage'; end;
if ~exist(fullfile(fs_dir, subj)); error('subj not found'); end
% check hemi setting
if isempty(hemi); hemi = 'lh'; end;
if sum(strcmp(hemi, {'rh' 'lh'})) ~= 1
    error('hemi must be "lh" or "rh"')
end
% check vw setting
if isempty(vw); vw = 'm'; end;
if sum(strcmp(vw, {'m' 'l' 'v' 'd' 'vm' 'dl' 'vl'})) ~= 1
    error('vw does not match any predefined views');
end
% assign camera angles depending on vw and hemi
if strcmp(hemi, 'lh')
    switch vw
        case 'm'
            az = 180; el= 0; ro = 0;
        case 'l'
            az = 0; el= 0; ro = 0;
        case 'v'
            az = 0; el= -85; ro = 0;
        case 'd'
            az = 180; el= 100; ro = 0;
        case 'vm'
            az = 160; el= -50; ro = 10;
        case 'dl'
            az = 50; el= 30; ro = 5;
        case 'vl'
            az = 15; el = -55; ro = -15;
    end
elseif strcmp(hemi, 'rh')
    switch vw
        case 'm'
            az = 0; el= 0; ro = 0;
        case 'l'
            az = 180; el= 0; ro = 0;
        case 'v'
            az = 180; el = -85; ro = 0;
        case 'd'
            az = 0; el = 100; ro = 0;
        case 'vm'
            az = 20; el= -50; ro = -10;
        case 'dl'
            az = 130; el= 30; ro = -5;
        case 'vl'
            az = 165; el= -50; ro = 15;
    end
end
az = num2str(az); el = num2str(el); ro = num2str(ro);
% create screenshot filename if necessary
screenshot = boolean(screenshot);
if screenshot
    spath = fullfile(cwd, [subj '_' hemi '_' vw]);
    if ~isempty(map_name); spath = [spath '_' map_name]; end
    spath = [spath '.png'];
end
% force binary curvature map if parameter map is not loaded
if isempty(map_name)
    % point to dummy map file in mri directory
    map_name = 'mri/aseg.mgz';
    thresh = repmat(10e4, 1, 3);
else
    % otherwise point to parameter map in surf directory
    map_name = ['surf/' map_name];
    % check for parameter map file
    if ~exist(fullfile(fs_dir, subj, map_name), 'file') > 0
        error('map_name not found in subj surf directory');
    end
end
% convert thresh vector to formatted string
ot = [];
for ti = 1:length(thresh) - 1
    ot = [ot num2str(thresh(ti)) ','];
end
ot = [ot num2str(thresh(ti + 1))];
% check zoom factor setting
if isempty(zoom); zoom = 1.5; end; zoom = num2str(zoom);
% check surface name setting
if isempty(surf); surf = 'inflated'; end;
if sum(strcmp(surf, {'inflated' 'pial' 'white'})) ~= 1
    error('surf must be "inflated", "pial", or "white"');
end


%% construct freeivew unix command
cmd = ['freeview -f surf/' hemi '.' surf];
if ~isempty(map_name); cmd = [cmd ':overlay=' map_name]; end
if ~isempty(map_name); cmd = [cmd ':overlay_method=piecewise']; end
if ~isempty(ot); cmd = [cmd ':overlay_threshold=' ot]; end
cmd = [cmd ':edgethickness=0' ':color=150,150,150' ...
    ' -cam Zoom ' zoom ' Azimuth ' az ' Elevation ' el ' Roll ' ro];
if screenshot; cmd = [cmd ' --screenshot ' spath]; end

% move to subject's FreeSurfer segmentation directory and execute command
cd(fullfile(RAID, '3Danat', 'FreesurferSegmentations', subj)); unix(cmd);

% move back to starting directory
cd(cwd);

end

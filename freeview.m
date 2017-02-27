function freeview(varargin)
% MATLAB code for scripting cortical surface visualizations using the
% freeview package included with FreeSurfer. The function is called with 
% eight optional arguements ordered as follows: 
% 
% freeview(subjID,hemi,vw,mapName,threshVec,zoomFactor,surfName,screenshot)
% 
% OPTIONAL INPUTS
% 1) subjID: name of subject (default = 'fsaverage')
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
% 4) mapName: name of parameter map in subject's surf directory)
% 5) threshVec: overlay thresholding parameters ([low mid high])
%      low = lower bound of transparent portion of colormap
%      mid = lower bound of opaque portion of colormap
%      high = upper limit of opaque portion of colormap
% 6) zoomFactor: scale factor for camera zoom (default = 1.5)
% 7) surfName: FreeSurfer surface name (default = 'inflated')
% 8) screenshot: whether or not to save a screenshot (default = false)
%
% NOTES
% 
% 1) Default parameters are used for inputs that are omitted or set to [].
% 
% 2) Freeview colors the gyri and sulci red and green by default unless a
%    parameter map is loaded, in which case the curvature map is shown with
%    a nicer looking binary grayscale. To force the binary curvature map in
%    both cases, a dummy map is loaded and then hidden using thresholding
%    when mapName is not defined by the user. 
% 
% 3) If screenshot = true, then a file named 'subjID_hemi_vw[_mapName].png'
%    is written to your current directory and the freeview window is
%    automatically closed. This is useful for batch processing.
% 
% Exapmle: 
% freeview(subjID,hemi,vw,mapName,threshVec,zoomFactor,surfName,screenshot)
% freeview('fsaverage','rh','v',[],[],2.5,'inflated',false)
% 
% AS 2/2017


%% setup defaults

% store paths to current working directory segmentation directory
homeDir = pwd;
fsDir = fullfile('/','share','kalanit','biac2','kgs','3Danat','FreesurferSegmentations');
% check input list
numvarargs = length(varargin);
if numvarargs > 8
    error('too many input arguements');
end
% set default arguments
optargs = {'fsaverage' 'lh' 'm' [] [] 1.5 'inflated' false};
optargs(1:numvarargs) = varargin;
% apply defaults to undefined arguements
[subjID,hemi,vw,mapName,threshVec,zoomFactor,surfName,screenshot] = optargs{:};


%% check inputs

% check for subjID in segmentations directory
if isempty(subjID); subjID = 'fsaverage'; end;
if ~exist(fullfile(fsDir,subjID))
    error('subjID not found in FreeSurfer Segmentations directory');
end
% check hemi
if isempty(hemi); hemi = 'lh'; end;
if sum(strcmp(hemi,{'rh' 'lh'})) ~= 1
    error('hemi must be "lh" or "rh"')
end
% check view
if isempty(vw); vw = 'm'; end;
if sum(strcmp(vw,{'m' 'l' 'v' 'd' 'vm' 'dl' 'vl'})) ~= 1
    error('view does not match any predefined views (see documentation)');
end
% assign camera angles depending on view and hemisphere
if strcmp(hemi,'lh')
    if strcmp(vw,'m'); az = 180; el= 0; ro = 0; end;
    if strcmp(vw,'l'); az = 0; el= 0; ro = 0; end;
    if strcmp(vw,'v'); az = 0; el= -85; ro = 0; end;
    if strcmp(vw,'d'); az = 180; el= 100; ro = 0; end;
    if strcmp(vw,'vm'); az = 160; el= -50; ro = 10; end;
    if strcmp(vw,'dl'); az = 50; el= 30; ro = 5; end;
    if strcmp(vw,'vl'); az = 15; el = -55; ro = -15; end;
elseif strcmp(hemi,'rh')
    if strcmp(vw,'m'); az = 0; el= 0; ro = 0; end;
    if strcmp(vw,'l'); az = 180; el= 0; ro = 0; end;
    if strcmp(vw,'v'); az = 180; el = -85; ro = 0; end;
    if strcmp(vw,'d'); az = 0; el = 100; ro = 0; end;
    if strcmp(vw,'vm'); az = 20; el= -50; ro = -10; end;
    if strcmp(vw,'dl'); az = 130; el= 30; ro = -5; end;
    if strcmp(vw,'vl'); az = 165; el= -50; ro = 15; end;
end
az = num2str(az); el = num2str(el); ro = num2str(ro);
% check screenshot
screenshot = boolean(screenshot);
if screenshot
    ssPath = fullfile(homeDir,[subjID '_' hemi '_' vw]);
    if ~isempty(mapName); ssPath = [ssPath '_' mapName]; end
    ssPath = [ssPath '.png'];
end
% use dummy paramter map to force binary curvature map
if isempty(mapName)
    % point to dummy map in mri directory
    mapName = ['surf/' mapName];
    mapName = 'mri/aseg.mgz';
    threshVec = repmat(10e4,1,3);
else
    % otherwise point to map in surf directory
    mapName = ['surf/' mapName];
end
% check for map file
if ~exist(fullfile(fsDir,subjID,mapName)) > 0;
    error('mapName not found in subjID surf directory');
end
% convert threshVec to formatted string
overlay_threshold = [];
for ti = 1:length(threshVec)-1
    overlay_threshold = [overlay_threshold num2str(threshVec(ti)) ','];
end
overlay_threshold = [overlay_threshold num2str(threshVec(ti+1))];
% check zoom factor
if isempty(zoomFactor); zoomFactor = 1.5; end;
zoomFactor = num2str(zoomFactor);
% check surface name
if isempty(surfName); surfName = 'inflated'; end;
if sum(strcmp(surfName,{'inflated' 'pial' 'white'})) ~= 1
    error('surfName must be "inflated", "pial", or "white"');
end

%% construct freeivew unix command

cmd = ['freeview -f surf/' hemi '.' surfName];
if ~isempty(mapName); cmd = [cmd ':overlay=' mapName]; end
if ~isempty(mapName); cmd = [cmd ':overlay_method=piecewise']; end
if ~isempty(overlay_threshold); cmd = [cmd ':overlay_threshold=' overlay_threshold]; end
cmd = [cmd ...
    ':edgethickness=0' ...
    ':color=150,150,150' ...
    ' -cam Zoom ' zoomFactor ' Azimuth ' az ' Elevation ' el ' Roll ' ro];
if screenshot; cmd = [cmd ' --screenshot ' ssPath]; end

% move to subject's FreeSurfer segmentation directory and execute command
cd(fullfile('/','share','kalanit','biac2','kgs','3Danat','FreesurferSegmentations',subjID));
unix(cmd);

% move back to starting directory
cd(homeDir);

end
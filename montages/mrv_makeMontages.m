function [img_final] = mrv_makeMontages(inputz)

% ras, 03/2008.
% kgs 03/2008
% jv 2008/04 evolved into sub-function with related main
% vn 2014 - changed for the kids study.
% bj 2016 - montage for thickness study
% mn 2021 - changed into a more general format

% Description: creates montages of mrVista meshes, with options for
% displaying ROIs and parameter maps in different ways.

% NOTE: Requires the subplot_tight.m function

%% Inputs:
% inputz struct 

%% Required fields
% (1) inputz.dataDir 
%   Path to the data where mrvista sessions are stored, such as
%   inputz.dataDir ='/oak/stanford/groups/kalanit/biac2/kgs/projects/myProject/myData/'
%   Note, the default is that within the data dir, there is one directory for each
%   mrVista session (Note, see below under "Other" if you have a nested directory structure)
% (2) inputz.outputDir
%   Path indicating where the montage should be saved
% (3) inputz.montageFilename
%   Name of montage image file: 
% (4) inputz.sess
%   cell of sessions, such as: inputz.sess = {'session1', 'session2'}
% (5) inputz.hemisphere
%   name of hemisphere to display, either inputz.hemisphere ='rh' or 'lh'
% (6) inputz.meshname
%   Name of mesh, such as: inputz.meshname =  'lh_inflated_200_1.mat';
% (7) inputz.nrows
%   number of rows in montage, such as, inputz.nrows = 1
% (8) inputz.ncols
%   number of columbs in montage ,such as, inputz.ncols= 10

%% Initializinig
% select either a scan number
%  inputz.scan
%   scan number in mrVista, for example: inputz.scan = 1;
%   this is relevant if you have multiple GLMs for example
% Or:  inputz.GLMName 
%   set the name of a GLM. When a name of a GLM is set, the scan will be
%   chosen based on the name of the GLM and the scan number will be ignored


%% optional fields: 

%% VIEW
% inputz.meshAngle
%   view to display mesh, these can be created and saved in mrVIsta in
%   advance, such as: inputz.meshAngle='lh_lateral';
%   if not set, goes to standard view in mrVista (lh =medial and rh= lateral view).

%% ROIS
% inputz.rois, for example: inputz.rois = {'lh_pFus_faces.mat', 'lh_mFus_faces.mat'}
% inputz.roiDrawMethod, set the way the ROIs should be drawn
%   This can be inputz.roiDrawMethod= 'boxes', 'perimeter', 'filled
%   perimeter', or 'patches'
% inputz.roiColors: matrix with dimensions nr of rois x RGB-values such as
%   inputz.roiColors = [1 0 0; 0 1 0]
% inputz.roiMask: to use the ROI as a mask. You can load a parameter map
%   and it will be restricted to the ROI. Number of ROIs in inputz.rois can only be 1.
%   inputz.roiMask=1;

%% Parameter maps

% inputz.map, name of parameter map to display, such as
%   inputz.map ='Word_vs_all_except_Number.mat';
% inputz.colorMap, name of color map to use, such as inputz.colorMap=
%   'autumnCmap' or 'winterCmap'. For full list see, mrVista--> Color
%   Map--> Parameter ColorMap
% inputz.setColorMap, option to set the colormap to certain values,
%   inputz.setColorMap= [-5 5];
% inputz.threshold, to threshold a parameter map at certain values, such as
%   inputz.threshold= [3 10];


%% LIGHT
% This changes the way the mesh appears (to get a gray mesh set these to
% the same value for each, such as, inputz.L.ambient = [.5 .5 .5];)
% inputz.L.ambient = [.5 .5 .5];
% inputz.L.diffuse = [.3 .3 .3];

%% Other
% inputz.displaySessionName = 1;
%   to display the session name on the mesh

% inputz.dataDirStructure = 'nested'
%   indicate if the data Dir structure is nested, such as for
%   Kids_AcrossYears, where all sessions of a given subject
%   are stored within a folder called "subjid".


%% Set up mesh prefereces
setpref('mesh', 'layerMapMode', 'all');
setpref('mesh', 'overlayLayerMapMode', 'mean');
setpref('mesh', 'overlayModulationDepth', 0.2);
setpref('mesh', 'roiDilateIterations', 0);
setpref('mesh', 'dataSmoothIterations', 2);
setpref('mesh', 'clusterThreshold', 0);
setpref('mesh', 'coTransparency', 0);


%% loop through sessions

for i =1:length(inputz.sess)

    %% init session  
    session = inputz.sess{i};
    
    %  set up session Dir
    if isfield(inputz, 'dataDirStructure')
        if strcmp(inputz.dataDirStructure, 'nested')
            subjID = char(extractBefore(session, '_'));
            sessionDir = [inputz.dataDir '/' subjID '/' session];
        end % maybe add other cases of data structures here later
    else
        sessionDir = [inputz.dataDir '/' session];
    end
    % go to session dir
    cd(sessionDir);
    
    % select scan based on GLM Name
    if isfield(inputz, 'GLMName')
       hG = initHiddenGray('GLMs');
       dtStruct = viewGet(hG,'dtstruct');
       whichGLM = contains({dtStruct.scanParams.annotation}, inputz.GLMName );
       scan = find(whichGLM);
       hG = setCurScan(hG,scan);
    else
        % initialize based on scan number
        hG = initHiddenGray('GLMs',inputz.scan);
    end
    
    %% load the user prefs -- meshColorOverlay needs a 'ui' field
    hG.ui = load('Gray/userPrefs.mat');
    hG.ui.dataTypeName= 'GLMs'; % in case ui preferences are different
    

    %%  Load the mesh & set view  
    cd('3DAnatomy')
    
    % add dir to path, some of the ROIs were not found previously causing
    % issues that wrong ROIs were displaced on the meshes
    addpath(genpath(pwd))
       
    % load the mesh
    hG = meshLoad(hG, inputz.meshname, 1);
    
    % set the view settings
    [mesh1, settings]=meshRetrieveSettings(hG.mesh{1}, inputz.meshAngle);
    % first, we set the hemisphere, by setting the cursor position's 3rd dim.
    if isequal(lower(inputz.hemisphere), 'rh')
        hG.loc = [100 100 1];
    else
        hG.loc = [100 100 200];
    end

   %% recompute vertex
    vertexGrayMap = mrmMapVerticesToGray(...
        meshGet(mesh1, 'initialvertices'),...
        viewGet(hG, 'nodes'),...
        viewGet(hG, 'mmPerVox'),...
        viewGet(hG, 'edges'));
    
    hG.mesh{1} = meshSet(hG.mesh{1}, 'vertexgraymap', vertexGrayMap);
    hG=refreshScreen(hG,1); 
    
    cd(sessionDir);
    
    
   %% Load Parameter map
   if isfield(inputz, 'map')
        mapPath = fullfile(sessionDir, 'Gray', 'GLMs', inputz.map);
        hG= loadParameterMap(hG, mapPath);

        % update the mesh
        meshColorOverlay(hG);
        
        if isfield(inputz, 'colorMap')
            % set colormap
            hG.ui.mapMode=setColormap(hG.ui.mapMode, inputz.colorMap); 
        end

        if isfield(inputz, 'setColorMap') % clip color map
            hG.ui.mapMode.clipMode = inputz.setColorMap;
        end
        
        if isfield(inputz, 'threshold') % threshold
             hG.ui.displayMode='map';
             hG=setMapWindow(hG, [inputz.threshold(1) inputz.threshold(2)]);
        end

        % update the mesh
        meshColorOverlay(hG);
   end
    
    
    %% Find and Load ROIs, set roi colors
     
    if isfield(inputz, 'rois')
        for r=1:length(inputz.rois)
            roiName = inputz.rois{r};
            
            % load ROI
            [hG , ok] = loadROI(hG, roiName); 
            
            if ok==1
                if isfield(inputz, 'roiColors')
                    hG.ROIs(1, hG.selectedROI).color = inputz.roiColors(r, :);
                    meshColorOverlay(hG); 
                end
                if isfield(inputz, 'roiDrawMethod')
                    hG.ui.roiDrawMethod = inputz.roiDrawMethod; 
                    meshColorOverlay(hG); 
                end
                
                if isfield(inputz, 'roiMask')
                    if length(inputz.rois)>1
                        sprintf('To use an ROI as a mask, select only 1 ROI')
                    else
                        hG.ROIs(1, hG.selectedROI).name = [roiName(1:end-4) '_mask'];
                        meshColorOverlay(hG); 
                    end
                end
            else
                sprintf('%s not found for %s', roiName, session )
            end
            
        end
    end
      

    %% set the lighting
    if isfield(inputz, 'L')
        meshLighting(hG, hG.mesh{1}, inputz.L, 1);
    end
    
    
    %% update everything one more time
    meshColorOverlay(hG);
    meshUpdateAll(hG);
    
    % Also recompute vertex one more time
    vertexGrayMap = mrmMapVerticesToGray(...
        meshGet(hG.mesh{1}, 'initialvertices'), ...
        viewGet(hG, 'nodes'), ...
        viewGet(hG, 'mmPerVox'), ...
        viewGet(hG, 'edges') ); 
    hG.mesh{1} = meshSet(hG.mesh{1}, 'vertexgraymap', vertexGrayMap); 
    hG = viewSet(hG, 'Mesh', hG.mesh{1}); 
    
    
    %% add image to the montage image

    img_temp= mrmGet(hG.mesh{1}, 'screenshot' ) ./ 255;
    image_crop=img_temp(150:499,100:400, :);
    img{i}=image_crop;
    img_final=image_crop;
    hG = meshDelete(hG, Inf); %close all meshes
    
    % modify plot settings
    plotNum = i;
    sp = subplot_tight(inputz.nrows,inputz.ncols,plotNum,[0.04, 0.01]);
    imagesc(img{i});
    set(gca,'CameraViewAngle',get(gca,'CameraViewAngle')-.1);
    set(gcf,'color','w');
    axis image;
    axis off;
    
    % display session name
    if isfield(inputz, 'displaySessionName')
        text(60,10,session,'FontSize',7,'Color','k','Interpreter','none')
    end
    
    % Save position of the subplot 
    lastSubplotPos = get(sp, 'position');

    clear global
      
end

% adjust position of the last subplot
set(sp, 'position', lastSubplotPos);

% save the montage
cd(inputz.outputDir);
set(gcf,'PaperPositionMode','auto');
print ('-dpng', '-r300', inputz.montageFilename);
 





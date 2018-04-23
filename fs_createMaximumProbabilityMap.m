function  MPM_output = createMaximumProbabilityMap(labelnames,hem,outname,surfacename,thresh,labelPath,surfacePath,nrNeighborsSmoothing)
%
% This function creates an MPM from the freesurfer probabilistic labels for
% each of the labels that are entered as input to the function.
% The purpose of the MPM is to assign each vertex on the cortical surface uniquely to a single
% label based on the label with the highest probability.
% Each label entered will result in an MPM map, and it will be used to
% compare to the other labels when their MPM maps are created.
% For a vertex to be assigned to an MPM in needs to have a probabiluty exceeding the input threshold
% 0. Each label is first thresholded with the input threshold 
% Then we need to make decisions about overlapping vertices
% Decisions are made in 2 steps:
% 1. Assign the vertex to the label with the higher probability 
% 
% SOLVING AMIBIGUITY (if the probability of the vertex is the same across labels)
% 1. If a vertex holds the same probability for two labels, we calculate the average probability 
% across the neighboring vertices for each of the labels and choose the one with the higher average 
% probabily; If the average probability of the neighbors is the same; repeat the process with larger neighborhoods
% until there is a resolution
%
% As a final step we remove isolated voxels which we believe are noise
% Thus, after MPMs are created, each one is searched for vertices that have less
% than at least one 3rd degree neighbor (4 vertices need to be connected)
% belonging to the same MPM and reassign them to the MPM with the second
% highest probability
%
% INPUT TO FUNCTION:
% labelnames =      a list (cell string) of probabilistic labels that are used to create the MPMsmaps.
%                   do not include .label in the filename (e.g. 'lh.FG1')
% outname =         suffix that will be added to the output MPM label
% surfacename =     the name of the cortical surface that the labels are based on. it will be used to get
%                   iformation about neighboring vertices for ambiguous cases  (e.g. 'lh.orig')
% thresh =          proability threshold for a vertex to be included in the MPM
%
% labelPath =       path to the label directory (e.g.
%                   '/biac2/kgs/3Danat/FreesurferSegmentations/fsaverage-bkup/label/CBA/cROIs/averages/label_fixed/')
%                   to the actual directory where the label is
% surfacePath =     path to the directory containing the cortical surface
%                   (e.g. '/biac2/kgs/3Danat/FreesurferSegmentations/fsaverage/surf/')
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EXAMPLE INPUT



%
% OUTPUT:
% MPM labels are saved to the labelpath directory
% MPM_output: one MPM per label
%
% MB Jan 2016
% KW & KGS Aug 2016
% MR Nov 2016

%% initialization

addpath('/biac2/kgs/dataTools/FreeSurferv5.3.c/matlab/')

source = [];
MPM_src = [];

if ~isempty(labelPath)
    labels = fullfile(labelPath,labelnames);
end
if ~isempty(surfacePath)
    surface = fullfile(surfacePath,surfacename);
end

%% read in surface the labels belong to
[~, surf_faces] = read_surf(surface); % FreeSurfer matlab function that gives for each vertex the faces (triangles) it is part of

%% load all labels for MPM creation
for ind = 1:length(labels)
    
    % read the src label
    tmp = num2cell(read_label_kgs([labels{ind} '.label']));
    
    % the label file has 5 columns: first column are the vertices
    source{ind}.index = tmp(:,1); % vertex index on mesh
    source{ind}.coords = tmp(:,2:4); % xyz coordinates
    source{ind}.vals = tmp(:,5); % probability values
    
    source_unthres{ind}.index = tmp(:,1);
    source_unthres{ind}.coords = tmp(:,2:4);
    source_unthres{ind}.vals = tmp(:,5);
    
    % remove the entries of the current label that are below the threshold
    fprintf(1,' num vertices in %s ROI %d, ', labelnames{ind}, length(source{ind}.index));
    less = find(cell2mat(source{ind}.vals) < thresh);
    fprintf(1,' num vertices below threshold %d\n', length(less));
    source{ind}.index(less) = [];
    source{ind}.coords(less,:) = [];
    source{ind}.vals(less) = [];
    fprintf(1,' after thresholding num vertices in ROI: %d\n', length(source{ind}.index));
end
clear tmp less

%% start MPM creation for each of the labels iteratively

labelcombs = nchoosek(1:length(source),2);

source_orig = source; % keep original labels for later
for l = 1:length(labelcombs)
    sourcenow = source{labelcombs(l,1)};
    sourcename = labelnames{labelcombs(l,1)};
    target = source{labelcombs(l,2)};
    targetname = labelnames{labelcombs(l,2)};
    disp('-------');
    disp(['labels to compare: ' sourcename ' and ' targetname]);
    
    
    % find  vertices that are common to both the source and the target
    [C, Is, It]=intersect(cell2mat(sourcenow.index),cell2mat(target.index)); % c is the value, is/it is the index in respective label
    fprintf(1,'num common voxels between %s and %s : %d \n',sourcename,targetname, length(C));
    
    sourceval=cell2mat(sourcenow.vals(Is)); % intersecting vertices in source
    targetval=cell2mat(target.vals(It)); % intersecting vertices in target
    
    % of the intersecting vertices find the ones that have lower probability in source or the target
    findVoxlowerS=find(sourceval<targetval); % index of vertices that are lower in source
    findVoxlowerT=find(sourceval>targetval); % index vertices lower in target
    fprintf(1,'%d voxels have lower value in %s \n',length(findVoxlowerS),sourcename);
    fprintf(1,'%d voxels have lower value in %s \n',length(findVoxlowerT),targetname);
    
    % find  intersecting vertices with equal probability
    findVoxAmbig = find(sourceval==targetval); % indexes of vertices showing the same probability (of intersection list!, not label list)
    fprintf(1,'%d voxels have equal values\n',length(findVoxAmbig));
    
    % solve ambiguous vertices by averaging across their neighbors
    % find neighbors of source and target to make decision for ambiguous voxels
    findSneighlower = []; findTneighlower = [];
    cAmbigRemS = []; cAmbigRemT = [];

             fprintf(1,'...busy...\n');
    
    for amb = 1:length(findVoxAmbig)

   ambigVertex = cell2mat(sourcenow.index(Is(findVoxAmbig(amb))));
        Sneighborsval = cell2mat(sourcenow.vals(Is(findVoxAmbig(amb)))); % initialize average neighborhood with value of the vertex in source label
        Tneighborsval = cell2mat(target.vals(It(findVoxAmbig(amb)))); % initialize average neighborhood with value of the vertex in target label
        degreeNeighbors = 0;
        neighborsOnSurf = ambigVertex; %start loop by looking for neighbors of the vertex in question
        
        
        while (Sneighborsval== Tneighborsval)
            
            degreeNeighbors = degreeNeighbors+1;
            [neighbors,~] = find(ismember(surf_faces,neighborsOnSurf)); % rowindexes of faces the contain vertex
            faces = surf_faces(neighbors,:); % faces that have vertex as one corner
            neighborsOnSurf = unique([faces(:); neighborsOnSurf]); % adding new degree neighbor to the ones we already have
            % mean value of neighborhood in source              
            Svals = zeros(length(neighborsOnSurf),1); % initialization average neighbors           
            unthresh_neighvalsS =  cell2mat(source_unthres{labelcombs(l,1)}.vals(ismember(cell2mat(source_unthres{labelcombs(l,1)}.index),neighborsOnSurf))); % neighborvalues from unthresholded map
            Svals(1:length(unthresh_neighvalsS),1) = unthresh_neighvalsS;
            Sneighborsval = mean(Svals);
            
            % mean value of neighborhood in target
            Tvals = zeros(length(neighborsOnSurf),1); % initialization average neighbors           
            unthresh_neighvalsT =  cell2mat(source_unthres{labelcombs(l,2)}.vals(ismember(cell2mat(source_unthres{labelcombs(l,2)}.index),neighborsOnSurf))); % neighborvalues from unthresholded map
            Tvals(1:length(unthresh_neighvalsT),1) = unthresh_neighvalsT;
            Tneighborsval = mean(Tvals);
            
            % exit the loop if all neighbors are included (number of
            % neighbors = number of vertices in label)
            if(length(Svals) == length(cell2mat(sourcenow.vals)))
                disp('exit search for neighbors as number of neighbors equals label size for the source');
                break;
            elseif(length(Tvals) == length(cell2mat(target.vals)))
                disp('exit search for neighbors as number of neighbors equals label size for the target');
                break;
            end
            
        end
        
        %
        if(Sneighborsval<Tneighborsval)
            cAmbigRemS = [cAmbigRemS degreeNeighbors];
            findSneighlower = [ findSneighlower; findVoxAmbig(amb)]; % collection of indexes of vertices to delete from source
        elseif(Sneighborsval>Tneighborsval)
            cAmbigRemT = [cAmbigRemT degreeNeighbors];
            findTneighlower = [findTneighlower; findVoxAmbig(amb)];% collection of indexes of vertices to delete from target
        end
        
    end
    
    cRS = hist(cAmbigRemS,max(cAmbigRemS)); % number vertices that were removed from source after each incremental neighborhood increase, indices indicate degree of neighbors
    cRT = hist(cAmbigRemT,max(cAmbigRemT)); % number vertices that were removed from target after each incremental neighborhood increase
    if (isempty(cRS))
        cRS = 0;
    end
    if (isempty(cRT))
        cRT = 0;
    end
    fprintf(1,'number of vertices removed from %s after averaging neighbors:\n',sourcename); disp(cRS);
    fprintf(1,'number of vertices removed from %s after averaging neighbors:\n',targetname); disp(cRT);
    
    
    
    %% delete vertices from labels that had a lower value
    
    % source
    delS = [findVoxlowerS; findSneighlower];
    sourcenow.index(Is(delS)) = [];
    sourcenow.coords(Is(delS),:) = [];
    sourcenow.vals(Is(delS)) = [];
    fprintf(1,'num vertices in %s: %d\n', sourcename, length(sourcenow.index));
    source{labelcombs(l,1)} = sourcenow;
    
    % target
    delT = [findVoxlowerT; findTneighlower];
    target.index(It(delT)) = [];
    target.coords(It(delT),:) = [];
    target.vals(It(delT)) = [];
    fprintf(1,'num vertices in %s: %d\n', targetname, length(target.index));
    source{labelcombs(l,2)} = target;
    
end

clearvars -except source hem labelnames source_orig surf_faces outname labelPath nrNeighborsSmoothing

% Now that MPMs are created; detect and decide about isolated speckles
%% check if all vertices in source now have a neighbor in same label

single = 0;
singleReassign = 0;
singleDelete = 0;

for s = 1:length(source)
    vertices = cell2mat(source{s}.index);
    neighborsOnSurf = [];
    for n = 1:length(vertices)
        alreadychecked = [];
        targets = vertices(n);
        % check for degree neighbors determined with integer nrNeighborsSmoothing
        for z = 1:nrNeighborsSmoothing
            alreadychecked = [alreadychecked;vertices(n)];
            [neighbors,~] = find(ismember(surf_faces,targets)); % rowindexes of faces the contain vertex/neighbors of that vertex
            faces = surf_faces(neighbors,:); % faces that have vertex as one corner
            neighborsOnSurf = unique(faces(:));
            
           % neighborsOnSurf(neighborsOnSurf==vertices(n)) = []; % delete vertex self from the neighbors list
           toDelete = find(ismember(neighborsOnSurf,alreadychecked));
           neighborsOnSurf(toDelete) = []; % track vertices i have already checked so we dont go circular with the neighborhood search
            alreadychecked = [alreadychecked;neighborsOnSurf];
            neighinlabel = ismember(neighborsOnSurf,vertices); % which of the neighors are also in the label
            targets = neighborsOnSurf(neighinlabel); % vertex numbers of neighbors in label
            
            % if we find a vertex without neighbors
            if(isempty(find(neighinlabel)))
                
                single = single+1;
                vertexlabel = [];
                vertexlabel_ind = [];
                for f = 1:length(source_orig)
                    if(f==s) % do not look in own original label
                        continue;
                    end
                    temp = find(cell2mat(source_orig{f}.index)==vertices(n)); % try to find vertex in other original labels
                    if(~isempty(temp)) % if vertex is found in other orig label,
                        % collect (1)vertex number with (2)probability value (3:5) coords and (6)source_orig where we found it
                        vertexlabel = [vertexlabel; cell2mat(source_orig{f}.index(temp)) cell2mat(source_orig{f}.vals(temp)) cell2mat(source_orig{f}.coords(temp,:)) f];
                        vertexlabel_ind = [vertexlabel_ind; f]; % index of source_orig we found the vertex in
                    end
                end
                
                % assign the vertex to the next highest label, or delete
                % if not found in any other label (original label)
                if(~isempty(vertexlabel))
                    [maxL,~] = find(vertexlabel == max(vertexlabel(:,2))); % find which of the labels, if multiple, has highest probability
                    whichSource = vertexlabel_ind(maxL,:);
                    
                    % if we find the vertex in multiple labels with the
                    % same probability, do neighborhood search like in the
                    % loop above
                    if(length(whichSource)>1)
                        degreeNeighborsA= 0;
                        neighborsOnSurfA = vertexlabel(1,1);
                        
                        % increase neighborhood until higher value is found
                        maxN = vertexlabel(:,2);
                        while (length(maxN)>1)
                            degreeNeighborsA = degreeNeighborsA+1;
                            [neighborsA,~] = find(ismember(surf_faces,neighborsOnSurfA)); % rowindexes of faces the contain vertex
                            facesA = surf_faces(neighborsA,:); % faces that have vertex as one corner
                            neighborsOnSurfA = unique([facesA(:); neighborsOnSurfA]); % adding new degree neighbor to the ones we already have
                            
                            % for each label the vertex was found in search for neighbors in label and collect neighborhood values
                            for x = 1:length(whichSource)
                                % mean value of neighborhood
                                Ninlabel{x} = ismember(neighborsOnSurfA,cell2mat(source_orig{whichSource(x)}.index));
                                SneighborsA{x} = neighborsOnSurfA(Ninlabel{x}); % the surface neighbors that are also in the label
                                index_val =  ismember(cell2mat(source_orig{whichSource(x)}.index),SneighborsA{x});
                                NvalsA{x} = cell2mat(source_orig{whichSource(x)}.vals(index_val)); % probability values of the  neighbors
                                SneighborsvalA(x) = mean(NvalsA{x});
                            end
                            [~,maxN] = find(SneighborsvalA == max(SneighborsvalA)); % label index with maximum value of vertexlabel
                        end
                        
                        % assign vertex to the label which has heighest neighborhood value
                        whichSource = vertexlabel_ind(maxL(maxN),:);
                        maxL = maxL(maxN);
                    end
                    toAssign = vertexlabel(maxL,:); % label the vertex should be assigned to
                    
                    % add vertex to the the label with heighest probability
                    % of the ones with neighbors
                    S_end = length(cell2mat(source{whichSource}.index));
                    source{whichSource}.index(S_end+1,1) = num2cell(toAssign(1));
                    source{whichSource}.vals(S_end+1,1) = num2cell(toAssign(2));
                    source{whichSource}.coords(S_end+1,:) = num2cell([toAssign(3) toAssign(4) toAssign(5)]);
                    singleReassign = singleReassign+1;
                    fprintf(1,'loose voxel: vertex removed from %s and added to %s after averaging neighbors:\n',labelnames{s},labelnames{whichSource}); disp(z);

                else
                    singleDelete = singleDelete+1;
                end
                
                % delete vertex without neighbors from its source
                ind = find(cell2mat(source{s}.index) == vertices(n));
                source{s}.index(ind) = [];
                source{s}.coords(ind,:) = [];
                source{s}.vals(ind) = [];
                
                break % break neighborhood search if this degree already had no neighbors
            end
        end
        
    end
end
disp(['single: ' mat2str(single)]);
disp(['deleted: ' mat2str(singleDelete)]);
disp(['reassigned: ' mat2str(singleReassign)]);

% save labels
for sa = 1:length(source)
    temp = strsplit(labelnames{sa},'.');
    labelfile = fullfile(labelPath, ['MPM_' hem '_' temp{2} '_' outname '.label']);
    write_label_kgs(cell2mat(source{sa}.index), cell2mat(source{sa}.coords), cell2mat(source{sa}.vals), labelfile); % if we distribute this revert to the FS function write_label
end
MPM_output=source;


end




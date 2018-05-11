
function fs_addmgz2label(fs_path, results_path, hemis, subj_dirs, templates, labels)
% this function takes an mgz overlay/parameter map file and extracts the
% values for all the vertices in specified label files
%
% INPUT:
% fs_path: string with the general freesurfer path
% results_path: string with the path where you want the results to be
% stored
% hemis: cell in form of {'lh'}, {'rh'} or {'rh', 'lh'}
% subj_dirs: cell with freesurfer directories of subjects
% templates: cell array containing a string for the overlay name for each
% hemisphere of interest
% labels: cell array containing cells with the labels for each hemisphere
% of interest
% NOTE that hemis, labels and templates must be in the same order wrt to
% hemisphere! (see input example)
%
% OUTPUT:
% for each labels, a .mat file is saved. The structure of the variable
% saved is n x 5 where n is the number of vertices, column 1 is the vertex
% number, columns 2-4 are xyz coordinates and column 5 is the extract
% values from the overlay for each vertex
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Example Input: 
% %% set up the variables
% 
% fs_path = '/biac2/kgs/3Danat/FreesurferSegmentations/'; %freesurfer path
% results_path = '/biac2/kgs/projects/V1myelination/results/endpts/freesurfer/'; 
% 
% % specify the map you want to extract values from 
% rh_template = 'rh.eccen-template-2.5-0220.sym.mgh';
% lh_template = 'lh.eccen-template-2.5.sym.mgh';
% templates = {rh_template, lh_template}; 
% 
% % specify the ROIs/labels you'd like to get the values for
% rh_labels = {'rh.dti_rh_IOG_endpts.label','rh.dti_rh_pFus_endpts.label'};
% lh_labels = {'lh.dti_lh_IOG_endpts.label','lh.dti_lh_pFus_endpts.label'};
% labels = {rh_labels, lh_labels}; 
% 
% hemis = {'rh','lh'}; 
% 
% % freesurfer directories of subjects
% subj_dirs   = {'AD25_edited', 'AI24_edited', 'JP23_edited'};
%
% % call the function
% fs_addmgz2label(fs_path, results_path, hemis, subj_dirs, templates, labels)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% checking that the number of groups of lables/templates actually matches
% the specified number of hemis
assert(length(labels) == length(hemis))
assert(length(templates) == length(hemis))

%% okay let's do it
for s = 1:length(subj_dirs)
    
    cur_subj_dir = subj_dirs{s};
    
    for h = 1:length(hemis)
        clear cur_labels cur_template
        
        cur_labels = labels{h};
        cur_template = templates{h};
        
        %load the overlay/map of interest
        parameter_map = load_mgh(fullfile(fs_path, cur_subj_dir, '/surf/', cur_template));

        for l = 1:length(cur_labels)
            clear label newlabel vertices coreROI outname

            if exist(fullfile(fs_path, subj_dirs{s}, '/label/', cur_labels{l}),'file')

                label = read_label_kgs(fullfile(fs_path, cur_subj_dir, '/label/', cur_labels{l}));

                % the label file has the vertex number in the first column, which
                % corresponds to the row indexing in the mgz file, which has the functional
                % values we want

                % fill 5th column of the label file with the mgz values
                vertices = label(:,1); % the vertices that we need to get the values for
                label(:,5) = parameter_map(vertices); % getting the mgz values by indexing with vertices (much faster than looping over all label vertices)

                % voila label has all the values!

                % save as a .mat files
                strparts = strsplit(cur_labels{l},'.'); %strip extension from name of label file
                coreROI = strparts{end-1};
                outname = [results_path, cur_subj_dir,'_', coreROI, '.mat'];
                save(outname, 'label');
                
            else
                warning([fullfile(subj_dirs{s}, '/label/', cur_labels{l}) ' does not exist'])
            end

        end
       
    end
end
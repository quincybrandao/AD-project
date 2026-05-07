% This script scans the Brainstorm database to collect the most recent average files
% (data_*average*.mat) for each subject and condition.
% It automatically selects the latest version based on the file timestamp.
% The output provides formatted cell arrays (sFiles_...) that can be copied 
% directly into Brainstorm processes 

% --- CONFIGURATION ---
TargetFolders = {'Probe_L4_Correct', 'Probe_L8_Correct', 'Retention_L4', 'Retention_L8'};
Subjects = {'sub-01', 'sub-02', 'sub-04', 'sub-05', 'sub-09', 'sub-10', 'sub-12'};

% Result containers
FinalProbeL4 = {}; FinalProbeL8 = {};
FinalRetL4 = {};   FinalRetL8 = {};

fprintf('--- Collecting the latest average files ---\n');

for iSub = 1:length(Subjects)
    sName = Subjects{iSub};
    for iFolder = 1:length(TargetFolders)
        fName = TargetFolders{iFolder};
        
        % Search for the most recent average file
        searchPattern = [sName '/' fName '/data_*average*.mat'];
        foundFiles = dir(fullfile(bst_get('ProtocolInfo').STUDIES, searchPattern));
        
        if ~isempty(foundFiles)
            % Sort by date (descending) to grab the latest version
            [~, idx] = sort([foundFiles.datenum], 'descend');
            newestFile = [sName '/' fName '/' foundFiles(idx(1)).name];
            
            % Distribute into the correct list
            if contains(fName, 'Probe')
                if contains(fName, 'L4'), FinalProbeL4{end+1} = newestFile;
                else, FinalProbeL8{end+1} = newestFile; end
            elseif contains(fName, 'Retention')
                if contains(fName, 'L4'), FinalRetL4{end+1} = newestFile;
                else, FinalRetL8{end+1} = newestFile; end
            end
        else
            fprintf('❌ NOT FOUND: %s in %s\n', sName, fName);
        end
    end
end

% --- OUTPUT FOR BRAINSTORM ---
fprintf('\n--- COPY THESE LISTS ---\n\n');

lists = {FinalProbeL4, 'sFiles_Probe_L4'; FinalProbeL8, 'sFiles_Probe_L8'; ...
         FinalRetL4, 'sFiles_Ret_L4'; FinalRetL8, 'sFiles_Ret_L8'};

for i = 1:size(lists, 1)
    currentList = lists{i,1};
    if ~isempty(currentList)
        fprintf('%s = {\n', lists{i,2});
        % Using a loop to ensure correct formatting regardless of list length
        for j = 1:length(currentList)
            if j < length(currentList)
                fprintf('    ''%s'', ...\n', currentList{j});
            else
                fprintf('    ''%s''};\n\n', currentList{j});
            end
        end
    end
end
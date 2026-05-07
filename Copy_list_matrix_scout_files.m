% This script searches for 'matrix_scout' files (ROI/Scout time series) across 
% specified subjects and conditions in the Brainstorm database.
% It automatically picks the most recent file (latest timestamp) in each folder.
% The output is a set of formatted lists (sFiles_...) that can be directly 
% copied and pasted into the Brainstorm pipeline editor.

% --- CONFIGURATION ---
TargetFolders = {'Probe_L4_Correct', 'Probe_L8_Correct', 'Retention_L4', 'Retention_L8'};
Subjects = {'sub-01', 'sub-02', 'sub-04', 'sub-05', 'sub-09', 'sub-10', 'sub-12'};

% Result containers
FinalProbeL4 = {}; FinalProbeL8 = {};
FinalRetL4 = {};   FinalRetL8 = {};

fprintf('--- Searching for matrix_scout files ---\n');

% Get the path to the Brainstorm studies
ProtocolInfo = bst_get('ProtocolInfo');
StudiesPath = ProtocolInfo.STUDIES;

for iSub = 1:length(Subjects)
    sName = Subjects{iSub};
    for iFolder = 1:length(TargetFolders)
        fName = TargetFolders{iFolder};
        
        % Search for all matrix_scout files in this specific directory
        searchDir = fullfile(StudiesPath, sName, fName);
        foundFiles = dir(fullfile(searchDir, 'matrix_scout_*.mat'));
        
        if ~isempty(foundFiles)
            % Sort by date to pick the ABSOLUTE LATEST version
            [~, idx] = sort([foundFiles.datenum], 'descend');
            
            % Use the exact filename found on disk
            actualFileName = foundFiles(idx(1)).name;
            
            % Brainstorm path format: 'SubjectName/FolderName/FileName'
            bstFilePath = [sName '/' fName '/' actualFileName];
            
            % Sort into the correct list based on folder name
            if contains(fName, 'Probe')
                if contains(fName, 'L4'), FinalProbeL4{end+1} = bstFilePath;
                else, FinalProbeL8{end+1} = bstFilePath; end
            elseif contains(fName, 'Retention')
                if contains(fName, 'L4'), FinalRetL4{end+1} = bstFilePath;
                else, FinalRetL8{end+1} = bstFilePath; end
            end
            fprintf('✅ Found for %s: %s\n', sName, actualFileName);
        else
            % Only report if the folder exists but the file is missing
            if exist(searchDir, 'dir')
               fprintf('⚠️  NO SCOUT in: %s/%s\n', sName, fName);
            end
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
        for j = 1:length(currentList)
            if j < length(currentList)
                fprintf('    ''%s'', ...\n', currentList{j});
            else
                fprintf('    ''%s''};\n\n', currentList{j});
            end
        end
    end
end
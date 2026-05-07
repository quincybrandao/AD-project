% This script performs a "brute force" check on Signal Space Projection (SSP) status across a list of Brainstorm files.
% It iterates through the provided files, locates the corresponding channel files in the database, 
% and identifies which SSP projectors are currently marked as active (Status = 1).
% Results are printed in a formatted table showing the Subject, Status, and specific Projector names.

% --- CONFIGURATION ---
numFiles = length(sFilesSSP);
ProtocolInfo = bst_get('ProtocolInfo');
STUDIES_DIR = ProtocolInfo.STUDIES; % Path to your Brainstorm data
fprintf('\n--- BRUTE FORCE SSP CHECK ---\n');
fprintf('%-15s | %-15s | %-s\n', 'Subject', 'Status', 'Projectors');
fprintf('----------------------------------------------------------------------\n');
for i = 1:numFiles
    subName = 'Unknown';
    try
        % 1. Get the relative path of the data file
        relPath = sFilesSSP{i}; 
        parts = strsplit(relPath, '/');
        subName = parts{1}; 
        % 2. Manually build the path to the channel files
        % We look for the .mat file starting with 'channel_' in the same folder
        dataDir = fileparts(fullfile(STUDIES_DIR, relPath));
        channelFiles = dir(fullfile(dataDir, 'channel*.mat'));
        
        if isempty(channelFiles)
            fprintf('%-15s | [ERROR]         | No channel.mat found in folder\n', subName);
            continue;
        end
        
        % Load the first channel file we find
        ChannelFileFull = fullfile(dataDir, channelFiles(1).name);
        mat = load(ChannelFileFull);
        
        activeList = {};
        
        % 3. Check the Projector variable very carefully
        if isfield(mat, 'Projector') && ~isempty(mat.Projector)
            % If it is a cell, convert to struct or skip
            if iscell(mat.Projector)
                % In Brainstorm, a cell is usually a sign of "no projectors"
                activeList = {}; 
            elseif isstruct(mat.Projector)
                for iP = 1:length(mat.Projector)
                    % Check if Status exists and is 1
                    p = mat.Projector(iP);
                    if isfield(p, 'Status') && isequal(p.Status, 1)
                        activeList{end+1} = p.Comment;
                    end
                end
            end
        end
        
        % 4. Print results
        if isempty(activeList)
            fprintf('%-15s | [NOT ACTIVE]    | No active SSP found\n', subName);
        else
            projectorString = strjoin(activeList, ', ');
            fprintf('%-15s | [OK]            | %s\n', subName, projectorString);
        end
        
    catch ME
        fprintf('%-15s | [ERROR]         | Error: %s\n', subName, ME.message);
    end
end
fprintf('----------------------------------------------------------------------\n');
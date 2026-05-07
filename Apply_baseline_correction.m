% This script performs an automated Batch Baseline Correction (-500ms to 0ms) 
% across all subjects in the current Brainstorm protocol.
% It specifically targets folders containing 'Retention' or 'Probe' conditions.
% It includes an exclusion list to skip specific subjects and uses the 
% DC Offset subtraction method ('dc') to overwrite existing epochs.

% --- CONFIGURATION ---
% ADJUST THESE: Subject numbers you want to skip
ExcludeList = [6, 7, 13, 27, 36, 39, 44, 50, 51, 56, 69, 76]; 

% Retrieve all studies from the current protocol
[~, sStudies] = bst_get('ProtocolStudies');

fprintf('Starting Batch Baseline Correction (-500ms to 0ms)...\n');
fprintf('Excluding subjects: %s\n', num2str(ExcludeList));
fprintf('------------------------------------------------------------\n');

for i = 1:length(sStudies)
    sStudy = sStudies(i);
    
    % 1. Basic checks: Does the study exist and have an assigned subject?
    if isempty(sStudy) || ~isfield(sStudy, 'BrainStormSubject') || isempty(sStudy.BrainStormSubject)
        continue;
    end
    
    % 2. Extract subject number from the name (e.g., 'sub-01' -> 1)
    subName = sStudy.BrainStormSubject;
    subNumStr = regexp(subName, '\d+', 'match');
    if isempty(subNumStr)
        continue; 
    end
    subNum = str2double(subNumStr{1});
    
    % 3. Filter based on ExcludeList
    if ismember(subNum, ExcludeList)
        continue;
    end
    
    % 4. Filter by Condition (Only Retention and Probe folders)
    conditionName = sStudy.Condition;
    if ~(contains(conditionName, 'Retention') || contains(conditionName, 'Probe'))
        continue;
    end
    
    % 5. Check if there are data files present in this folder
    if isempty(sStudy.Data)
        continue;
    end
    
    % 6. Collect all data file names in this condition
    allDataFiles = {sStudy.Data.FileName};
    
    % 7. Execute Baseline Correction
    try
        fprintf('Processing: %s | Condition: %s (%d files)\n', subName, conditionName, length(allDataFiles));
        
        bst_process('CallProcess', 'process_baseline', allDataFiles, [], ...
            'baseline',    [-0.500, 0], ... % 500ms pre-stimulus
            'sensortypes', 'EEG', ...
            'method',      'dc', ...        % 'dc' is standard Mean Baseline subtraction
            'overwrite',   1);              % Overwrites existing files to save space
            
    catch ME
        fprintf('      ERROR for %s (%s): %s\n', subName, conditionName, ME.message);
    end
end

fprintf('------------------------------------------------------------\n');
disp('DONE! Baseline correction has been applied to all selected subjects.');
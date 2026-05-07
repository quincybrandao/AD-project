% This script automates the detection, event-renaming, and epoching of Brainstorm data.
% 1. It searches for specific subjects, prioritizing 'interpbad' (interpolated) files over raw files.
% 2. It creates complex triggers (e.g., distinguishing Retention for Load 4 vs. Load 8).
% 3. It checks for correctness by looking at subsequent 'response_correct' triggers.
% 4. Finally, it imports the epochs into the Brainstorm database.

% --- STEP 1: CONFIGURATION & EXCEPTIONS ---
% ADJUST THESE: List subject numbers to skip
ExcludeList = [6, 7, 13, 27, 36, 44, 50, 51, 56, 69, 76]; 

% ADJUST THESE: The range of subjects you want to process
SubjectRange = 1:80; 

FilePaths = {};

for i = SubjectRange
    if ismember(i, ExcludeList)
        continue;
    end
    
    subID = sprintf('%02d', i);
    
    % --- PATH FINDER LOGIC ---
    % ADJUST THESE: If your folder naming convention is different
    possibleFolders = {['sub-', subID], ['sub-', subID, '_exclude']};
    foundPath = '';
    fileTypeUsed = '';
    
    for f = 1:length(possibleFolders)
        folderName = possibleFolders{f};
        
        % 1. Check for INTERPBAD version (Interpolated channels)
        % ADJUST THESE: Change the string if your process names differ
        innerFolder_interp = ['@rawsub-', subID, '_task-sternberg_eeg_band_notch_resample_Montage_Fcz_interpbad'];
        fileName_interp = ['data_0raw_sub-', subID, '_task-sternberg_eeg_band_notch_resample_Montage_Fcz_interpbad.mat'];
        testPath_interp = fullfile(folderName, innerFolder_interp, fileName_interp);
        
        if exist(file_fullpath(testPath_interp), 'file')
            foundPath = testPath_interp;
            fileTypeUsed = 'INTERPBAD';
            break;
        end
        
        % 2. Fallback to normal RAW
        innerFolder_raw = ['@rawsub-', subID, '_task-sternberg_eeg_band_notch_resample_Montage_Fcz'];
        fileName_raw = ['data_0raw_sub-', subID, '_task-sternberg_eeg_band_notch_resample_Montage_Fcz.mat'];
        testPath_raw = fullfile(folderName, innerFolder_raw, fileName_raw);
        
        if exist(file_fullpath(testPath_raw), 'file')
            foundPath = testPath_raw;
            fileTypeUsed = 'RAW';
            break;
        end
    end
    
    if ~isempty(foundPath)
        fprintf('Subject %s → using: %s\n', subID, fileTypeUsed);
        FilePaths{end+1} = foundPath;
    else
        fprintf('WARNING: Could not find subject %s (no interpbad or raw).\n', subID);
    end
end

% --- STEP 2: AUTOMATION (TRIGGERS + EPOCHING) ---
fprintf('Starting batch for %d subjects...\n', length(FilePaths));

for iFile = 1:length(FilePaths)
    DataFile = FilePaths{iFile};
    [~, ~, DataName] = bst_fileparts(DataFile);
    fprintf('\n[%d/%d] Processing: %s\n', iFile, length(FilePaths), DataFile);
    
    try
        DataMat = in_bst_data(DataFile);
    catch
        continue;
    end
    
    % --- PART A: EVENT RENAMING LOGIC ---
    % ADJUST THESE: Change these labels to match YOUR actual event names
    events = DataMat.F.events;
    labelCorrect = 'response_correct'; 
    newNames = {'Retention_L4', 'Retention_L8', 'Probe_L4_Correct', 'Probe_L8_Correct'};
    newTimes = {[], [], [], []};
    
    allTimes = [];
    for i = 1:length(events)
        for j = 1:length(events(i).times)
            allTimes(end+1,:) = [events(i).times(j), i];
        end
    end
    if isempty(allTimes), continue; end
    [~, sortIdx] = sort(allTimes(:,1));
    sortedEvents = allTimes(sortIdx, :);
    
    currentLoad = ''; 
    for i = 1:size(sortedEvents, 1)
        time = sortedEvents(i,1);
        labelName = events(sortedEvents(i,2)).label;
        
        % Logic for Sternberg Task (Load 4 vs Load 8)
        if strcmpi(labelName, 'load_4'), currentLoad = 'L4'; end
        if strcmpi(labelName, 'load_8'), currentLoad = 'L8'; end
        
        % Assign Retention triggers based on preceding Load
        if strcmpi(labelName, 'retention') && ~isempty(currentLoad)
            if strcmp(currentLoad, 'L4')
                newTimes{1}(end+1) = time;
            else
                newTimes{2}(end+1) = time;
            end
        end
        
        % Assign Probe triggers ONLY if followed by a correct response
        if strcmpi(labelName, 'probe') && ~isempty(currentLoad)
            isCorrect = false;
            % Look ahead for the correct response trigger (max 3 seconds)
            for k = i+1:min(i+25, size(sortedEvents, 1))
                if (sortedEvents(k,1) - time) > 3.0, break; end 
                if strcmpi(events(sortedEvents(k,2)).label, labelCorrect)
                    isCorrect = true;
                    break;
                end
            end
            
            if isCorrect
                if strcmp(currentLoad, 'L4')
                    newTimes{3}(end+1) = time;
                else
                    newTimes{4}(end+1) = time;
                end
            end
        end
    end

    % Save new events back to the structure
    for iNew = 1:length(newNames)
        if ~isempty(newTimes{iNew})
            sNew = db_template('event');
            sNew.label = newNames{iNew};
            sNew.times = newTimes{iNew};
            sNew.epochs = ones(1, length(newTimes{iNew}));
            sNew.color = rand(1,3); 
            
            existIdx = find(strcmpi({DataMat.F.events.label}, newNames{iNew}));
            if isempty(existIdx)
                DataMat.F.events(end+1) = sNew;
            else
                DataMat.F.events(existIdx) = sNew;
            end
        end
    end
    
    bst_save(file_fullpath(DataFile), DataMat, 'v6');

    % --- PART B: EPOCHING ---
    % ADJUST THESE: Time window and baseline settings
    EpochEvents = {'Retention_L4', 'Retention_L8', 'Probe_L4_Correct', 'Probe_L8_Correct'};
    
    bst_process('CallProcess', 'process_import_data_event', DataFile, [], ...
        'subjectname', '', ...
        'condition', '', ...
        'eventname', strjoin(EpochEvents, ', '), ...
        'timewindow', [], ...
        'epochtime', [-0.500, 2.000], ... % 500ms pre-stim, 2000ms post-stim
        'createcond', 1, ...
        'igshort', 1, ...
        'usectfcomp', 1, ...
        'usessp', 1, ...
        'baseline', [-0.500, 0]); 
end
disp('BATCH COMPLETE! All subjects processed with custom triggers and epochs.');
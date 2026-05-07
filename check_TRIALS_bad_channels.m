% This script scans all trial files (data_*.mat) for each subject to detect "Bad Channels".
% It provides a detailed report of which specific trial files contain bad channels
% and outputs a final summary distinguishing between "Clean" subjects and subjects 
% with active ChannelFlags set to -1.
% Averages are automatically skipped to focus on raw/processed trial data.

% ============================================
% Check BAD CHANNELS in all trial files
% + SUMMARY PER SUBJECT
% ============================================
ProtocolInfo = bst_get('ProtocolInfo');

% List of subjects to include in the analysis
validSubs = {'sub-01','sub-02','sub-04','sub-05','sub-09','sub-10','sub-12','sub-14',...
             'sub-16','sub-18','sub-22','sub-24','sub-29','sub-35','sub-42','sub-45',...
             'sub-46','sub-54','sub-60','sub-61','sub-65','sub-67','sub-68','sub-70',...
             'sub-72','sub-77'};

fprintf('--- Check BAD CHANNELS in trial files ---\n');

subjectsWithBad = {};
subjectsClean   = {};

for iSub = 1:length(validSubs)
    sub = validSubs{iSub};
    subFolder = fullfile(ProtocolInfo.STUDIES, sub);
    
    if ~exist(subFolder, 'dir')
        fprintf('❌ %s → folder not found\n', sub);
        continue;
    end
    
    % Search for all data files within the subject folder
    files = dir(fullfile(subFolder, '**', 'data_*.mat'));
    subHasBad = false;
    
    for iFile = 1:length(files)
        filePath = fullfile(files(iFile).folder, files(iFile).name);
        
        % Skip average files
        if contains(files(iFile).name, 'average')
            continue;
        end
        
        data = load(filePath, 'ChannelFlag');
        
        if isfield(data, 'ChannelFlag')
            if any(data.ChannelFlag == -1)
                % Load channel names for reporting
                channelFile = fullfile(files(iFile).folder, 'channel.mat');
                if exist(channelFile, 'file')
                    ch = load(channelFile, 'Channel');
                    chanNames = {ch.Channel.Name};
                    badNames = chanNames(data.ChannelFlag == -1);
                    badStr = strjoin(badNames, ', ');
                else
                    badStr = 'channel.mat missing';
                end
                
                fprintf('❌ %s → %s\n', sub, files(iFile).name);
                fprintf('   Bad: %s\n', badStr);
                subHasBad = true;
            end
        end
    end
    
    % Store for final summary
    if subHasBad
        subjectsWithBad{end+1} = sub;
    else
        subjectsClean{end+1} = sub;
    end
end

% ===============================
% 🔥 FINAL SUMMARY
% ===============================
fprintf('\n==============================\n');
fprintf('SUMMARY\n');
fprintf('==============================\n');

fprintf('\n❌ Subjects WITH bad channels:\n');
if isempty(subjectsWithBad)
    fprintf('None\n');
else
    for i = 1:length(subjectsWithBad)
        fprintf('- %s\n', subjectsWithBad{i});
    end
end

fprintf('\n✅ Subjects WITHOUT bad channels (Clean):\n');
if isempty(subjectsClean)
    fprintf('None\n');
else
    for i = 1:length(subjectsClean)
        fprintf('- %s\n', subjectsClean{i});
    end
end
% This script identifies "Bad Channels" across multiple subjects in a Brainstorm protocol.
% It filters data based on specific naming conventions (e.g., '_Montage_Fcz') 
% and a predefined list of valid subjects. 
% For each subject, it compares the ChannelFlag in the data file with the channel names, 
% reporting the number and names of disabled channels.
% Finally, it provides a summary table and checks for consistency across the group.

% ============================================
% Check BAD CHANNELS per subject (Brainstorm RAW)
% ============================================
ProtocolInfo = bst_get('ProtocolInfo');
ProtocolStudies = bst_get('ProtocolStudies');
ProtocolStudies = ProtocolStudies.Study;

% List of subjects to include in the analysis
validSubs = {'sub-01','sub-02','sub-04','sub-05','sub-09','sub-10','sub-12','sub-14',...
             'sub-16','sub-18','sub-22','sub-24','sub-29','sub-35','sub-42','sub-45',...
             'sub-46','sub-54','sub-60','sub-61','sub-65','sub-67','sub-68','sub-70',...
             'sub-72','sub-77'};

report = {};
fprintf('--- Start BAD CHANNEL check ---\n');

for iStudy = 1:length(ProtocolStudies)
    sStudy = ProtocolStudies(iStudy);
    
    if isempty(sStudy.Data)
        continue;
    end
    
    fileName = sStudy.Data(1).FileName;
    
    % Filter by file naming convention and valid subject list
    if contains(fileName, '_Montage_Fcz') && any(contains(fileName, validSubs))
        
        % Full path to data file
        dataFullPath = fullfile(ProtocolInfo.STUDIES, fileName);
        
        % Path to channel.mat
        studyFolder = fileparts(dataFullPath);
        channelFile = fullfile(studyFolder, 'channel.mat');
        
        if exist(dataFullPath, 'file') && exist(channelFile, 'file')
            % Load data file (for ChannelFlag)
            data = load(dataFullPath, 'ChannelFlag');
            
            % Load channel names
            ch = load(channelFile, 'Channel');
            chanNames = {ch.Channel.Name};
            
            if isfield(data, 'ChannelFlag')
                flags = data.ChannelFlag;
                
                % Safety check (in case of length mismatch)
                if length(flags) ~= length(chanNames)
                    fprintf('⚠️ Length mismatch: %s\n', fileName);
                    continue;
                end
                
                % Identify bad channels (Flag = -1)
                badIdx = find(flags == -1);
                badNames = chanNames(badIdx);
                
                report{end+1,1} = fileName;
                report{end,2}   = length(badIdx);
                report{end,3}   = strjoin(badNames, ', ');
                
                if isempty(badIdx)
                    fprintf('✔ %s → NO bad channels\n', fileName);
                else
                    fprintf('❌ %s → %d bad: %s\n', fileName, length(badIdx), strjoin(badNames, ', '));
                end
            else
                fprintf('⚠️ No ChannelFlag found in: %s\n', fileName);
            end
        else
            fprintf('❌ File missing: %s\n', fileName);
        end
    end
end

% ============================================
% Summary
% ============================================
if isempty(report)
    disp('❌ No matching data found.');
else
    resTable = cell2table(report, 'VariableNames', {'File','NumBad','BadChannels'});
    fprintf('\n--- SUMMARY ---\n');
    
    % List subjects with bad channels
    hasBad = resTable.NumBad > 0;
    if any(hasBad)
        fprintf('\n❌ Subjects with bad channels:\n');
        disp(resTable(hasBad, :));
    else
        fprintf('\n✅ No subjects have bad channels.\n');
    end
    
    % Check for consistency in bad channel patterns
    uniqueBadPatterns = unique(report(:,3));
    if length(uniqueBadPatterns) > 1
        fprintf('\n⚠️ Inconsistent bad channel patterns detected between subjects!\n');
        fprintf('👉 This may affect grand averaging or group statistics.\n');
    else
        fprintf('\n✅ Bad channels are consistent across all subjects.\n');
    end
end
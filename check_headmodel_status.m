% This script provides an overview of the Head Model status for specified subjects and conditions.
% It checks each condition folder in the Brainstorm protocol to verify if a head model exists,
% if it is correctly selected as the active model, and displays the model type (e.g., Overlapping Spheres, OpenMEEG).


% --- CONFIGURATION --- HEAD MODEL OVERVIEW
Subjects = {'sub-01','sub-02','sub-04','sub-05','sub-09','sub-10','sub-12','sub-14',...
             'sub-16','sub-18','sub-22','sub-24','sub-29','sub-35','sub-42','sub-45',...
             'sub-46','sub-54','sub-60','sub-61','sub-65','sub-67','sub-68','sub-70',...
             'sub-72','sub-77'};

Conditions = {'Probe_L4_Correct', 'Probe_L8_Correct', 'Retention_L4', 'Retention_L8'};

fprintf('--- HEAD MODEL STATUS OVERVIEW ---\n\n');

for iSub = 1:length(Subjects)
    sName = Subjects{iSub};
    fprintf('**%s**:\n', sName);
    
    for iCond = 1:length(Conditions)
        cName = Conditions{iCond};
        
        % Find the study (folder) in Brainstorm
        [sStudy, iStudy] = bst_get('StudyWithCondition', [sName '/' cName]);
        
        if isempty(sStudy)
            fprintf('   - %-20s: ⚠️ Folder not found\n', cName);
            continue;
        end
        
        % Check if a HeadModel is present
        if isempty(sStudy.HeadModel)
            fprintf('   - %-20s: ❌ MISSING\n', cName);
        else
            % Identify the currently active HeadModel
            iHeadModel = sStudy.iHeadModel;
            if iHeadModel > 0
                modelType = sStudy.HeadModel(iHeadModel).Comment;
                fprintf('   - %-20s: ✅ %s\n', cName, modelType);
            else
                fprintf('   - %-20s: ❓ No active model selected\n', cName);
            end
        end
    end
    fprintf('-----------------------------------\n');
end
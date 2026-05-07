**Script Descriptions**
- Apply_baseline_correction.m: Performs baseline correction (-500ms to 0ms) on epoch files. It overwrites the existing data with the corrected version.

- Copy_list_Average_Condition_files.m: Scans the database for the most recent sensor-level average files (data_average.mat) and prints a formatted list in the command window for easy copy-pasting into the Brainstorm process box.

- Copy_list_matrix_scout_files.m: Searches for the latest scout time-series files (matrix_scout_*.mat) and prints a formatted list in the command window for use in further analysis.

- process_triggers_epochs.m: Automates event renaming and creates epochs from raw data files. It uses logic to categorize events by task load and response accuracy.

- check_headmodel_status.m: Checks all condition folders to verify if a head model file is present and selected as active.

- check_TRIALS_bad_channels.m: Scans every individual trial/epoch file to check for channels marked as bad (-1) in the ChannelFlag array.

- check_bad_channels.m: Checks the general channel.mat files to report which subjects have bad channels.

- Check_SSP_Active.m: Checks the channel.mat files to see which Signal Space Projection (SSP) filters are currently enabled.



**Instructions for Use**
1. Prerequisites: Brainstorm must be installed and added to your MATLAB path. The relevant protocol should be loaded before running any scripts.

2. Setup: Most scripts include a configuration section at the top where you can define the subject list, folder names, or exclusion criteria. Update these variables to match your directory structure.

3. Running Scripts: Run the scripts directly from the MATLAB Command Window or Editor.

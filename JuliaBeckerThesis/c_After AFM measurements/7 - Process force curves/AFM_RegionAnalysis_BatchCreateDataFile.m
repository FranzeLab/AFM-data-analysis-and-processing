%% AFM_RegionAnalysis_BatchCreateDataFile.m          by Julia Becker, 01/04/2020
% For detailed description, see AFM_RegionAnalysis_Mapping.m
% This will make the 'Data.mat' file (without region analysis or heatmap)
% for a bunch of experiments in one go.
    
clear variables
close all
diary on

%% Let user choose which overarching folder to read
uiwait(msgbox(sprintf("Select the overarching folder you want to analyse.")))
PathName_big = uigetdir('', 'Select the overarching section folder (#XX_XX)');

%% Make inventory of all folders inside the overarching folder
invent = dir(PathName_big);
invent = invent([invent.isdir]);
folders = {invent.name}';
folders(contains(folders, {'..','.'})) = [];
folders(:) = fullfile(PathName_big, folders(:));
clear PathName_big invent

%%
for e = 1:size(folders,1)
    %% Take first folder from list and get data
    PathName = folders{e,1};
    disp(' ')
    disp(folders{e,1}(152:end))
    
    %% Simple or complex experiment?
    % Simple: one experiment without multiple conditions
    % Complex: one experiment with different conditions in multiple subfolders
    
    ui0 = questdlg('Is this a simple or complex experiment?', 'Type of experiment', 'Simple', 'Complex', 'Simple');
    if strcmp(ui0, 'Simple')
        source = fullfile(PathName, 'region analysis', 'Data.mat');
    elseif strcmp(ui0, 'Complex')
        source = fullfile(PathName, 'region analysis_all', 'Data.mat');
    end
    
    %% Check whether to import or reconstruct "data"
    ui1 = 'Reconstruct';
    clear quest
    
    if strcmp(ui1, 'Reconstruct') == 1
        clear ui1
        data = GetData(PathName);
        data = GetDetails(data);
        PrepareComplex(PathName, ui0)
        disp(strcat("Original dataset: ", num2str(size(data,1)) ," curves"))
        
        %% Copy full dataset to "data_full" as backup
        data_full = data;
        
        %% Handling of several curves from the same x/y position
        [data, length_dupl] = RemoveDuplicates(data);
        disp(strcat("Duplicate removal: ", num2str(length_dupl) ," curves removed"))
        clear length_dupl
        
        %% Delete curves too far from force setpoint
        cutoff = 0.1;                                   % Set the maximal permissible relative deviation from the force setpoint
        [data, deviate] = RemoveWrongForce(data, cutoff);
        disp(strcat("Inacceptable force: ", num2str(size(deviate,1)) ," curves removed. Cutoff was ", num2str(cutoff.*100), "%."))
        clear deviate
        disp(strcat("Remaining: ", num2str(size(data,1)) ," curves."))        
        
        %% Save workspace variables
        save(source, '-regexp', '^(?!(source|folders|e|PathName)$).')
        
    else
        load(source)
        clear ui1
    end
    clearvars -except folders e
end

diary off

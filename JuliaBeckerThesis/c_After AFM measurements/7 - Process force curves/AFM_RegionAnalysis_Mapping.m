%% AFM_RegionAnalysis_Mapping.m          by Julia Becker, 14/10/2021
% This script combines data about analysed AFM measurements from an
% experiment into a big table ('data'). It checks for several measurements
% at the same x/y coordinates and only keeps one (duplicate removal). It
% will also check how the actual reached force for each measurement
% compares to the setpoint force and will remove measurements which deviate
% by more than a relative value specified by the user ('cutoff', preset to
% 0.1). As a backup, 'data_full' includes all measurement files before any
% removals have been done. If a 'Data.mat' file already exists, this script
% will ask whether to load this one instead of making a new one.
% 
% The script can be used to do a region analysis and plot elasticity
% heatmaps. It will calculate some descriptive stats for the dataset and
% display an overview so the user can choose good thresholds for plotting.
% 
% The script can be run in two configurations: 'simple' and 'complex'.
% Choose 'simple' if your experiment comprises one set of measurements with
% the same settings. Choose 'complex' if your experiment comprises several
% subfolders with different maps/settings (e. g. timelapse or a different
% measurement settings).
% 
% If there's a systematic foldername of the experimental folder (or
% subfolders), the script will deduce the animal number (following #), the
% setpoint force (followed by nN), the extend speed (followed by µm or um)
% and the orientation (if 'horizontal', 'sagittal', 'transverse' or
% 'coronal') (all separated by _ or -) from the it and include it in 'data'.
%
% To avoid the script asking for manual inputs, some things can be
% specified in the code directly: 
%   - Region analysis:  'layer_names' - see comment there
%   - Heatmap plotting:
%       - 'markertype','markersize', 'bar_intervals', 'colourmap' - see
%            comments there
%       - answers to questions being asked before plotting - see there
%
% BEFORE USING THIS SCRIPT:
% - Have your data ordered in the standard folder setup
% - Run batchforce.m
% - Sort your force curves (AssessFits_batchforce_SortCurves.m)
%
% OUTPUT:
% - Data.mat in 'region analysis' (simple) or 'region analysis_all' (complex)
% - Annotated images of region analysis in the above folders
% - Heatmaps in 'elasticity maps' (simple) or 'combined/elasticity maps'

clear variables
close all

%% Let user choose which folder to read and get data
PathName = uigetdir('', 'Select the section folder (#XX_XX)');

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
if exist(source, 'file') == 2
    quest = sprintf("Do you want to load the saved 'Data.mat' or reconstruct 'data'?\n\nCAVE If you reconstruct, the existing 'Data.mat' will be overwritten!");
    ui1 = questdlg(quest,'Data.mat already exists','Load','Reconstruct', 'Load');
else
    ui1 = 'Reconstruct';
end
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
    save(source, '-regexp', '^(?!(source|PathName)$).')
    uiwait(msgbox("Script will continue when you click 'Okay'."))
    
else
    load(source)
    clear ui1
end

%% Load conversion variables and overview image, if needed
if ismember('x_image', data.Properties.VariableNames) == 0
    [data, I] = GetImageCoordinates(data, PathName, ui0, source);
end 

if strcmp(ui0, 'Simple') == 1
    I = imread(fullfile(PathName, 'Pics', 'calibration', 'overview.tif'));
elseif strcmp(ui0, 'Complex') == 1
    I = imread(fullfile(PathName,'calibration_all', 'overview.tif'));
end

%% Display image and plot measurement points
ShowImage(I)
plot(data.x_image(:), data.y_image(:), 'b.', 'MarkerSize', 8, 'LineWidth', 2);
uiwait(msgbox("Grid points will disappear when you click 'Okay'."))

%% Region analysis, if requested
ShowImage(I)
ui2 = questdlg('Do you want to do a region analysis?', 'Region analysis', 'Yes', 'No', 'Yes');

if strcmp(ui2, 'No') == 1
    if length(unique(data.roi)) > 1
        ui3 = questdlg('Regions are already annotated for this dataset. Do you want to remove these?', 'Overwrite existing data?', 'Keep', 'Remove', 'Keep');
        if strcmp(ui3, 'Remove') == 1
            data.roi(:) = 0;
            layer_names = string([]);              
            layer_numbers = size(layer_names,1);
        end
    else
        data.roi(:) = 0;
        layer_names = string([]);              
        layer_numbers = size(layer_names,1);
    end
elseif strcmp(ui2, 'Yes') == 1
    
    %% Option to predefine layer_names and layer_number - refer to comments if unwanted
    layer_names = string([]);               % to predefine: e.g. layer_names = string(["WhiteMatter"; "GreyMatter"]);    to manually define later: layer_names = string([]); 
    layer_numbers = [];             % if layer_names predefined: layer_numbers = size(layer_names,1);            to manually define later: layer_numbers = [];
  
    %%
    ui3 = questdlg('Which type of region analysis do you want to do?', 'Region analysis', 'Standard', 'Unbiased', 'Standard');
    if strcmp(ui3, 'Standard') == 1
        [data, layer_numbers, layer_names, colours, colour_scheme] = RegionAnalysis_Standard(data, I, source, layer_numbers, layer_names);
        save(source, 'data', 'ui3', 'layer_numbers', 'layer_names', 'colours', 'colour_scheme', '-append')
    elseif strcmp(ui3, 'Unbiased') == 1
        [data, annotations, layer_numbers, layer_names, colours, colour_scheme] = RegionAnalysis_Unbiased(data, I, source, layer_numbers, layer_names);
        save(source, 'data', 'ui3', 'layer_numbers', 'layer_names', 'colours', 'colour_scheme', 'annotations', '-append')
    end
    uiwait(msgbox("Image will close when you click 'Okay'."))
end
close all
save(source, 'data', '-append')

%% Calculate statistical parameters for dataset
[stats, stats_overview] = DescriptiveStats(data,PathName, layer_numbers);
disp(stats_overview)                                % Summary of stats for all measurements (per subfolder) so user can choose heatmaps values well
save(source, 'stats', 'stats_overview', '-append')

%% Select region for elasticity map
if exist('x_lim','var') == 0
    ui4 = questdlg('Do you want to crop the image before plotting a heatmap?','Cropping','Yes','No','Yes');
    if strcmp(ui4,'Yes') == 1
        [x_lim, y_lim] = ZoomToSelectedRectangle(I);
    else
        x_lim = [1 size(I,2)];
        y_lim = [1 size(I,1)];
    end
    clear ui4
    save(source, 'x_lim', 'y_lim', '-append')
end

%% Set markertype, markersize, intervals for labels on colourbar and the colourmap used
if exist('markertype','var') == 0           % 's' for square, 'o' for circle
    markertype = 's';
end

if exist('markersize','var') == 0
    markersize = 650;                       % try ~600-800
end
bar_intervals = 100;                        % interval for ticks on colourbar
colourmap = 'hot';                          % for all default colourmaps, see https://uk.mathworks.com/help/matlab/ref/colormap.html --> Input arguments --> map

[markersize] = OptimiseMarkersize(data, I, markertype, markersize, bar_intervals, x_lim, y_lim);
save(source, 'markertype', 'markersize', 'bar_intervals', 'colourmap', '-append')

%% Plot heatmap - read description of function to see how to use varargin and avoid questions. Enter the answers to the questions as additional input variables after 'colourmap':
% e. g. PlotMap(...,  [1 0 0 0], {2, [500 400]}, {1, [500 10 28]}))

PlotMap(data, I, ui0, PathName, layer_names, markertype, markersize, bar_intervals, colourmap, x_lim, y_lim)

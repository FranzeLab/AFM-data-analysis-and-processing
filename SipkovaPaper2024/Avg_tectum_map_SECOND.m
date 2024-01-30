%% Make generalised map from a number of norm_AFM.mat or norm_HCR.mat files   by Jana Sipkova, 28/01/2024
% Script to make a normalised averaged map of an ROI (in this case the optic tectum). 
% You need to have run the AFM_grid_tectum_analysis.m or HCR_grid_tectum_analysis.m 
% scripts on your original data before to have the input files.

% Depending on whether you are analysing norm_AFM.mat or norm_HCR.mat files
% please comment out the appropriate lines, denoted by %%AFM%% or %%HCR%%

% input: 
%      - AFM_norm.mat or HCR_norm.mat files in enclosing folder/subfolders

%% Read in all XXX_norm.mat files in the enclosing folder/subfolders and put into one variable called Value
uiwait(msgbox(sprintf("Select the overarching folder you want to analyse.\n\n All norm_AFM.mat or norm_HCR.mat files inside this folder will be found.")))
PathName_big = uigetdir('/Users/janasipkova/', "Choose the overarching folder");

% Browse for a file, from a specified "starting folder" = PathName
% Get the name of the file that the user wants to use.
FileList = dir(fullfile(PathName_big, '**/norm_AFM.mat')); %%AFM%%
%FileList = dir(fullfile(PathName_big, '/**/*norm_HCR.mat')); %%HCR%%
Value = [];
for iFile = 1:numel(FileList)
  FileName = fullfile(FileList(iFile).folder, FileList(iFile).name);
  fprintf(1, 'Now reading %s\n', FileName);
  replicate = FileList(iFile).name;
  Field = struct2table(load(FileName));
  Replicate = repmat({replicate}, size(Field,1), 1);
  Merge = [Field Replicate];
  Value = cat(1, Value, Merge);
end
Value = splitvars(Value,'norm_AFM','NewVariableNames', {'x', 'y', 'stiffness'}); %%AFM%%
%Value = splitvars(Value,'norm_HCR','NewVariableNames', {'y', 'x', 'Grey_value'}); %%HCR%%
Value.Properties.VariableNames{4} = 'Replicate';
Value.Replicate = categorical(Value.Replicate);

%% Get a new grid of the area
pointsize = 10;
scatter(Value.x, Value.y, pointsize, Value.Replicate) % all points from all maps
hold on;
outline = boundary(Value.x, Value.y); % create boundary around the points & polygon
area = polyshape(Value.x(outline),Value.y(outline));
plot(area);

% create grid within the outline
xv = area.Vertices(:,1);
yv = area.Vertices(:,2);
newGrid = polygrid(xv, yv, 12); %%AFM%% %value here (12) might need to be modified depending on the spacing of your measurements
%newGrid = polygrid(xv, yv, 150); %%HCR%%
plot(newGrid(:, 1),newGrid(:,2), '.k');

%% AFM %% - Reassign stiffness values to new grid
nearestXY = dsearchn(newGrid, [Value.x, Value.y]); %find nearest grid value to each point from norm_AFM.mat files
stiffGrid = [newGrid(nearestXY,:) Value.stiffness];
stiffGrid(any(isnan(stiffGrid),2),:) = [];
% make new table with grid value and associated average stiffness
[C,ia,idx] = unique(stiffGrid(:,[1,2]),'rows');
val = accumarray(idx,stiffGrid(:,3),[],@mean); 
%val = accumarray(idx,stiffGrid(:,3),[],@median); %can choose median values instead
finStiffGrid = [C val];

%save the final grid
SavingDir = PathName;
finStiffGrid_file = "XXX.csv"; %choose the filename
csvwrite(finStiffGrid_file,finStiffGrid)
finStiffGrid_file_mat = "XXX.mat"; %choose the filename
save(finStiffGrid_file_mat,'finStiffGrid');

%% HCR %% - Reassign intensity values to new grid
nearestXY = dsearchn(newGrid, [Value.x, Value.y]); %find nearest grid value to each point from norm_HCR.mat files
intGrid = [newGrid(nearestXY,:) Value.Grey_value];
intGrid(any(isnan(intGrid),2),:) = [];
% make new table with grid value and associated average grey value
[C,ia,idx] = unique(intGrid(:,[1,2]),'rows');
val = accumarray(idx,intGrid(:,3),[],@mean);
sd = accumarray(idx,intGrid(:,3),[],@std); %standard deviation
sem = accumarray(idx,intGrid(:,3),[],@(x) std(x)/sqrt(length(x))); %standard error
%val = accumarray(idx,intGrid(:,3),[],@median);
finIntGrid = [C val sd sem];

%save the final grid
SavingDir = PathName;
finIntGrid_file = "XXX.csv"; %choose the filename
csvwrite(finIntGrid_file,finIntGrid)
finIntGrid_file_mat = "XXX.mat"; %choose the filename
save(finIntGrid_file_mat,'finIntGrid');

%% Variables for heatmap

ms = 32; %marker size, may need to be modified depending on your screen display

%threshold = maximum value of your heatmap; can set to an absolute value or
%do it based on the maximum intensity/stiffness value in your grid
threshold = 1000; 
%threshold = ceil(max(finStiffGrid(:,3))); %%AFM%%
%threshold = ceil(max(finIntGrid(:,3))); %%HCR%%

%% AFM averaged normalised map %%

for j = 1:length(threshold)
    
    %% Set up colour scale
    heatmap_scale = hot(threshold(j));     % using Matlab colormap array 'hot' - this can be changed
    %heatmap_scale = gray(threshold(j));     % using Matlab colormap array 'grey' - this can be changed
    
    %% Make heatmap based on stiffness value for all grid points
    %imshow(I);
    axis image
    hold on;
     
    for i = 1:size(finStiffGrid,1)
        if isnan(finStiffGrid(i,3)) == 0
            elasticity = round(finStiffGrid(i,3));
            if elasticity ~= 0
                if elasticity > threshold(j)
                    elasticity = threshold(j);
                end
                colour_spec = heatmap_scale(elasticity,:);
            elseif elasticity == 0
                colour_spec = [0 0 0];
            end
            plot(finStiffGrid(i,1), -finStiffGrid(i,2), 's', 'MarkerSize', ms, 'LineWidth', 0.1, 'Color', colour_spec, 'MarkerFaceColor', colour_spec); % Use 'MarkerSize', 11.8, 'LineWidth', 0.1 for uncropped images from Zyla and 100 �m grid
            xlim([-2.2 2.2])
            ylim([-2 2.05])
        end
    end

    %% Include colour scale bar
    colormap(heatmap_scale)
    colorbar
    colorbar_ticklabels = [0:250:threshold(j)];
    colorbar_ticks = colorbar_ticklabels/threshold(j);
    colorbar('Ticks',colorbar_ticks,'TickLabels',colorbar_ticklabels, 'FontSize', 18)
    
    clear cb
   
end

%% HCR averaged normalised map %%

for j = 1:length(threshold)
    
    %% Set up colour scale
    %heatmap_scale = hot(threshold(j));     % using Matlab colormap array 'hot' - this can be changed
    heatmap_scale = flipud(gray(threshold(j)));     % using Matlab colormap array 'grey' - this can be changed
    
    %% Make heatmap based on intensity value for all grid points
    %imshow(I);
    axis image
    hold on;
     
    for i = 1:size(finIntGrid,1)
        if isnan(finIntGrid(i,3)) == 0
            fluorescence = round(finIntGrid(i,3));
            if fluorescence ~= 0
                if fluorescence > threshold(j)
                    fluorescence = threshold(j);
                end
                colour_spec = heatmap_scale(fluorescence,:);
            elseif fluorescence == 0
                colour_spec = [0 0 0];
            end
            plot(finIntGrid(i,1), finIntGrid(i,2), 's', 'MarkerSize', ms, 'LineWidth', 0.1, 'Color', colour_spec, 'MarkerFaceColor', colour_spec);
            xlim([-0.05 1.05])
            ylim([-1.05 0.05])
        end
    end
   
    %% Include colour scale bar
    colormap(heatmap_scale)
    colorbar
    colorbar_ticklabels = [0:100:threshold(j)];
    colorbar_ticks = colorbar_ticklabels/threshold(j);
    colorbar('Ticks',colorbar_ticks,'TickLabels',colorbar_ticklabels, 'FontSize', 18)
    
    clear cb
   
end

%% Function for making grid in polyshape
%inPoints = getPolygonGrid(xv,yv,ppa) returns points that are within a 
%concave or convex polygon using the inpolygon function.
%xv and yv are columns representing the vertices of the polygon, as used in
%the Matlab function inpolygon
%ppa refers to the points per unit area you would like inside the polygon. 
%Here unit area refers to a 1.0 X 1.0 square in the axes. 
%Example: 
% L = linspace(0,2.*pi,6); xv = cos(L)';yv = sin(L)'; %from the inpolygon documentation
% inPoints = getPolygonGrid(xv, yv, 10^5)
% plot(inPoints(:, 1),inPoints(:,2), '.k');
function [inPoints] = polygrid( xv, yv, ppa)
	N = sqrt(ppa);
%Find the bounding rectangle
	lower_x = min(xv);
	higher_x = max(xv);
	lower_y = min(yv);
	higher_y = max(yv);
%Create a grid of points within the bounding rectangle
	inc_x = 1/N;
	inc_y = 1/N;
	
	interval_x = lower_x:inc_x:higher_x;
	interval_y = lower_y:inc_y:higher_y;
	[bigGridX, bigGridY] = meshgrid(interval_x, interval_y);
	
%Filter grid to get only points in polygon
	in = inpolygon(bigGridX(:), bigGridY(:), xv, yv);
%Return the co-ordinates of the points that are in the polygon
	inPoints = [bigGridX(in), bigGridY(in)];
end

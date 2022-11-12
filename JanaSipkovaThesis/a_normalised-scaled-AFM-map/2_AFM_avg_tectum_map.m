%% Make generalised map from a number of norm_AFM.mat files   by Jana Sipkova, 22/05/2022
% Script for the fine maps of the tectum. Script allows you to create one
% generalised map from a number of maps of a specific region. You need to
% have run the AFM_grid_tectum_analysis.m script on your original data
% before.

% input: 
%      - AFM_norm.mat files in enclosing folder/subfolders

%% Read in all AFM_norm.mat files in the enclosing folder/subfolders and put into one variable called Value
uiwait(msgbox(sprintf("Select the overarching folder you want to analyse.\n\n All norm_AFM.mat files inside this folder will be found.")))
PathName_big = uigetdir('/Volumes/Jana_Lab/PhD Data/AFM_new/Analysed/', "Choose the overarching folder");

% Browse for a file, from a specified "starting folder" = PathName
% Get the name of the file that the user wants to use.
FileList = dir(fullfile(PathName_big, '**/norm_AFM.mat'));
Value = [];
for iFile = 1:numel(FileList)
  FileName = fullfile(FileList(iFile).folder, FileList(iFile).name);
  fprintf(1, 'Now reading %s\n', FileName);
  replicate = extractAfter(FileList(iFile).folder,"mapping/");
  Field = struct2table(load(FileName));
  Replicate = repmat({replicate}, size(Field,1), 1);
  Merge = [Field Replicate];
  Value = cat(1, Value, Merge);
end
Value = splitvars(Value,'norm_AFM','NewVariableNames', {'x', 'y', 'stiffness'});
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
newGrid = polygrid(xv, yv, 12); %figure out the distance between grid points!!
plot(newGrid(:, 1),newGrid(:,2), '.k');

%% Reassign stiffness values to new grid
nearestXY = dsearchn(newGrid, [Value.x, Value.y]); %find nearest grid value to each point from norm_AFM.mat files
stiffGrid = [newGrid(nearestXY,:) Value.stiffness];
stiffGrid(any(isnan(stiffGrid),2),:) = [];
% make new table with grid value and associated average stiffness
[C,ia,idx] = unique(stiffGrid(:,[1,2]),'rows');
val = accumarray(idx,stiffGrid(:,3),[],@mean); 
%val = accumarray(idx,stiffGrid(:,3),[],@median);
finStiffGrid = [C val];

%% Plot in heatmap

ms = 32;
%threshold = ceil(max(finStiffGrid(:,3)));
threshold = 1000;

for j = 1:length(threshold)
    
    %% Set up colour scale
    heatmap_scale = hot(threshold(j));     % using Matlab colormap array 'hot' - this can be changed
    %heatmap_scale = gray(threshold(j));     % using Matlab colormap array 'grey' - this can be changed
    
    %% MAKE HEATMAP INCLUDING ALL MEASUREMENT POINTS
    % Plot points on image based on their elasticity value
    %imshow(I);
    axis image
    hold on;
    %set(gcf, 'Position', get(0, 'Screensize'));
     
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
            % Use 'MarkerSize', 11.8, 'LineWidth', 0.1 for uncropped images from Zyla, 100 �m grid, 32x
            % Julia's laptop: use 's', markersize 7, linewidth 7.5
            % if you want dots not squares: ('.', 'MarkerSize', 30) - need to play with setting depending on screen/image size
        end
    end

   
    %% Include colour scale bar
    colormap(heatmap_scale)
    colorbar
    colorbar_ticklabels = [0:250:threshold(j)];
    colorbar_ticks = colorbar_ticklabels/threshold(j);
    colorbar('Ticks',colorbar_ticks,'TickLabels',colorbar_ticklabels, 'FontSize', 18)
    
    clear cb
% 
%     %% Save the figure
%     heatmap_name = fullfile(path_sec, 'elasticity maps', strcat('all points_maxindent_scaledto', num2str(threshold(j)),'.png'));
%     saveas(gcf,heatmap_name);
% 
%     heatmap_name = fullfile(path_sec, 'elasticity maps', strcat('all points_maxindent_scaledto', num2str(threshold(j)),'.fig'));
%     saveas(gcf,heatmap_name);
%     clear heatmap_name
   
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

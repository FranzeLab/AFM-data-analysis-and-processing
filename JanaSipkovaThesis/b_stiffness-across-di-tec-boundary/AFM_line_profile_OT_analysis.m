%% AFM_line_profile_analysis.m          by Jana Sipkova, 26/06/2020
% This script allows you to retrieve the stiffness of all measurements
% within a certain distance (distance_to_OT_in_m) of a line you draw (e.g.
% the optic tract). You also draw another line for a boundary of something 
% (e.g. the tectum), and the intersect between the two lines is calculated,
% which then becomes the 0 distance point.
%
% input: 
%      - image file (ath5) which is used by the user to draw the boundaries
%      of the OT and the tectum
%      - data.mat file from the output of AFM_RegionAnalysis_Mapping.m from
%      Julia, which has the stiffness values and x and y stage coordinates
%      - conv.x and conv.y variables from AFMgrid_variables.mat from the 
%      output of MakeAFMmap_alldirections.m from Julia, for calculating
%      microns to pixels
%
% output:
%      - OT_coordinates.mat = your trace of the OT
%      - tectum_coordinates.mat = your trace of the tectum
%      - line_profile.csv = 3 columns, 1) index of the original OT
%      coordinate, 2) distance of the coordinate to the tectum/diencephalon
%      boundary, 3) stiffness measurement within a certain distance of the
%      coordinate
%
%% Open fluorescence image (ath5 label) of the user's choice
% Browse for a file, from a specified "starting folder" = PathName
PathName = uigetdir('/Users/janasipkova/Dropbox (Cambridge University)/Franze lab/Data/AFM/tectum_mapping/', "Choose the folder");
% Get the name of the file that the user wants to use.
defaultFileName = fullfile(PathName, 'Pics', 'calibration', '*.*');
[baseFileName, folder] = uigetfile(defaultFileName, 'Select a file');
if baseFileName == 0
  % User clicked the Cancel button.
  return;
end

fullFileName = fullfile(folder, baseFileName);
ath5 = imread(fullFileName);

%% Mark the trajectory of the OT and save the coordinates on the image
imshow(ath5);
hold on
message = sprintf('Draw a line along OT\n\nThe XY coordinates will be saved.');
uiwait(msgbox(message));
clear message

line_OT = drawassisted('Closed', false);
OT_coordinates = line_OT.Position;
line_OT.Visible = 'off';
OT_coordinates = flipud(OT_coordinates);
OT_coordinates = unique(OT_coordinates, 'rows', 'stable');

%%OPTIONAL: check that the coordinates look right
imshow(ath5)
axis on
hold on
plot(OT_coordinates(:,[1]),OT_coordinates(:,[2]), 'r+', 'MarkerSize', 10, 'LineWidth', 2);

%save OT_coordinates.mat variable
OT_file = fullfile(PathName,'OT_coordinates');
save(OT_file,'OT_coordinates');

%1) coordinates are in pixels, 
%2) coordinates are in the order as you drew them (top row is most recent 
%waypoint, bottom row is closer to the chiasm)
%3) the slower you draw, the more points. Points are evenlly spaced

%% Determine tectum position and find point of intersect between OT
imshow(ath5);

hold on
message = sprintf('Draw a line along the telencephalon/tectum boundary\n\nThe XY coordinates will be saved.');
uiwait(msgbox(message));
clear message

line_tectum = drawassisted('Closed', false);
tectum_coordinates = line_tectum.Position;
line_tectum.Visible = 'off';

%save OT_coordinates.mat variable
tectum_file = fullfile(PathName,'tectum_coordinates');
save(tectum_file,'tectum_coordinates');

%%OPTIONAL: check that the coordinates look right
imshow(ath5)
axis on
hold on
plot(tectum_coordinates(:,[1]),tectum_coordinates(:,[2]), 'b+', 'MarkerSize', 10, 'LineWidth', 2);

%find the points in OT which intersect tectum boundary
[xi,yi] = polyxpoly(OT_coordinates(:,[1]),OT_coordinates(:,[2]),tectum_coordinates(:,[1]),tectum_coordinates(:,[2]));

imshow(ath5)
hold on
plot(xi,yi, 'r+', 'MarkerSize', 20, 'LineWidth', 2);

%first point across the intersection points if needed
tec_dien_boundary = [xi(1),yi(1)];
%% Import data file and image-to-stage coordinate files
load(fullfile(PathName, 'region analysis', 'Data.mat'))
load(fullfile(PathName, 'AFMgrid_variables.mat'), 'conv_x', 'conv_y')
conv = mean([conv_x, conv_y]);

%% Convert OT coordinates to distances along the OT from tectum/diencephalon boundary

%calculate distances of all OT coordinates to the intersection with the
%tectum boundary; hence have distances from the tectum in pixels
dist_OT_tectum = sqrt((OT_coordinates(:,[2]) - tec_dien_boundary(:,[2])).^2 + (OT_coordinates(:,[1]) - tec_dien_boundary(:,[1])).^2);

%edit OT_coordinates_5um to have a value every 5um
% dist_along_OT_in_m = 5*10^(-6); %want to sample the stiffness every 5um 
% sampling_pixels = dist_along_OT_in_m*conv;
% 
% %edit OT_coordinates_5um to have a value every 5um
% spacing_pos =[0:sampling_pixels:max(dist_OT_tectum)].';
% spacing_neg = -spacing_pos;
% spacing_pos = flipud(spacing_pos);
% spacing_neg(1,:) = [];
% spacing = vertcat(spacing_pos,spacing_neg);

%% Find all measurement points within 30 um of the OT
%convert 30um distance to OT to pixel distance
distance_to_OT_in_m = 30*10^(-6);
distance_pixels = distance_to_OT_in_m*conv; %dist in pixels to OT

%search data for image coordinates which are distance_pixels within the OT
measurements = data{:, {'x_image','y_image'}};
[Idx,D] = rangesearch(measurements,OT_coordinates,distance_pixels);

%some OT coordinates will not have any measurements closeby....
find(cellfun('isempty',Idx)) %find points with no measurements closeby
%get rid of points with no measurements closeby in Idx and
%dist_OT_tectum
Idx_full = Idx(~cellfun('isempty',Idx));
dist_OT_tectum_full = dist_OT_tectum(~cellfun('isempty',Idx));

%for each row in Idx (which has the indices/row numbers of those
%coordinates within the distance range), get the stiffness values
clear i
for i = 1:size(Idx_full, 1)
    stiffness{i,:} = data.modulus([Idx_full{i}],:);
end

%% Preparing the .csv file for plotting

%dist_OT_tectum currently is ordered with row 1 being in the tectum, and
%the last row is closer to the chiasm. Find the 0 point (at tectal boundary)
%and make all distance values afterwards be negative
index_tec_dien = find(dist_OT_tectum_full == 0);
dist_OT_tectum_neg(:,1) = dist_OT_tectum_full;
dist_OT_tectum_neg(index_tec_dien:size(dist_OT_tectum_neg,1),:) = -dist_OT_tectum_neg(index_tec_dien:size(dist_OT_tectum_neg,1),:);

%add position in table, distance from tectum and the stiffness data
clear i
clear k
index_pos=[];
multi_dist=[];
for i = 1:size(stiffness, 1)
    for k = 1:size(stiffness{i},1)
        index_pos = [index_pos, i];
        multi_dist = [multi_dist, dist_OT_tectum_neg(i)];
    end
end

line_profile(:,1) = index_pos.'; %adds the original row position as another column
line_profile(:,2) = multi_dist.'; %adds distance from tectum as another column
line_profile(:,3) = cell2mat(stiffness);

%% File saving and export
final_file = fullfile(PathName,'line_profile.csv');
csvwrite(final_file,line_profile)

%% Quick visualisation check - OPTIONAL
plot (line_profile(:,2),line_profile(:,3),'r+', 'MarkerSize', 10, 'LineWidth', 2)
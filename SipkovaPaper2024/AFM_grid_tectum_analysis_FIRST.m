%% AFM_grid_tectum_analysis.m          by Jana Sipkova, 22/05/2022
% This script allows you to retrieve a coordinate grid with associated
% stiffness values across a certain area which you trace. You also have the
% option to rotate and flip the image. You get output files in both microns
% and a normalised value. Importantly, if e.g. you're missing half of the
% outline area in measurements, this is taken into account, and those grid
% points will just be associated with a NaN stiffness value.

% For example, I use it to outline the tectum of the Xenopus brain, then 
% rotate/flip the embryo so that the A-P axis is along the X-axis, and D-V
% axis is along the Y axis.
%
% input: 
%      - image file (brightfield) which is used by the user to draw the
%      boundaries of the tectum
%      - data.mat file from the output of AFM_RegionAnalysis_Mapping.m from
%      Julia, which has the stiffness values and x and y stage coordinates
%      - conv.x and conv.y variables from AFMgrid_variables.mat from the 
%      output of MakeAFMmap_alldirections.m from Julia, for calculating
%      microns to pixels
%
% output:
%      - tectum_stiffness.csv = 3 columns, 1st = X coordinates, 2nd = Y
%      coordinates, 3rd = Stiffness values in Pa
%      - norm_tectum_stiffness.csv = as previous, but X and Y are
%      normalised
%      - norm_AFM.mat = same as norm_tectum_stiffness.csv but .mat => can
%      be used as input for the AFM_avg_tectum_map.m script
%
%% Open brightfield image of the user's choice
% Browse for a file, from a specified "starting folder" = PathName
PathName = uigetdir('/Users/janasipkova/', "Choose the folder");
% Get the name of the file that the user wants to use.
defaultFileName = fullfile(PathName, 'Pics', 'calibration', '*.*');
[baseFileName, folder] = uigetfile(defaultFileName, 'Select a file');
if baseFileName == 0
  % User clicked the Cancel button.
  return;
end

fullFileName = fullfile(folder, baseFileName);
brightfield = imread(fullFileName);

%% Create outline of the tectum
imshow(brightfield);
hold on
message = sprintf('Draw the outline of the tectum\n\nThe XY coordinates will be saved.');
uiwait(msgbox(message));
clear message

outline_tectum = drawassisted('Closed', false);
tec_coordinates = outline_tectum.Position;
outline_tectum.Visible = 'off';
tec_coordinates = flipud(tec_coordinates);
tec_coordinates = unique(tec_coordinates, 'rows', 'stable');

%%OPTIONAL: check that the coordinates look right
imshow(brightfield)
axis on
hold on
%plot(tec_coordinates(:,[1]),tec_coordinates(:,[2]), 'r+', 'MarkerSize', 10, 'LineWidth', 2);

outline = polyshape(tec_coordinates); % turn points into polygon
plot(outline)
%1) coordinates are in pixels, 
%2) coordinates are in the order as you drew them
%3) the slower you draw, the more points. Points are evenlly spaced

%% Import data file and image-to-stage coordinate files, and the grid coordinate system
load(fullfile(PathName, 'region analysis', 'Data.mat'))
load(fullfile(PathName, 'AFMgrid_variables.mat'), 'conv_x', 'conv_y', 'results')
conv = mean([conv_x, conv_y]);

%% Get all the grid measurement points within the polygon
AFMgrid_all_x = results(:,1);  % x of ALL grid measurement points (also those missing stiffness measurements)
AFMgrid_all_y = results(:,2);  % y of ALL grid measurement points (also those missing stiffness measurements)
isin = isinterior(outline,AFMgrid_all_x,AFMgrid_all_y); 
idxin = find(isin); % index of pixels that intersect with tectum outline

%get all coordinates of those indices, as well as the modulus
AFMgrid = [AFMgrid_all_x(idxin),AFMgrid_all_y(idxin)];

%plot them on the map
close all
imshow(brightfield)
hold on
plot(outline)
plot(AFMgrid(:,1),AFMgrid(:,2), 'r+', 'MarkerSize', 10, 'LineWidth', 2);
axis equal

%% Get all the coordinates associated with a stiffness value, add the other ones so that the grid spans the entire tectum, but we also have the stiffness values
AFM_measured_xy = table2array(data(:,[24,25])); %get measured stiffness values and corresponding image coordinates
AFM_measured_stiffness = table2array(data(:,5));
[AFM_measurements_overlap,idx_AFM_measured] = intersect(floor(AFM_measured_xy), floor(AFMgrid),'stable', 'rows');
Measured_stiffness = AFM_measured_stiffness(idx_AFM_measured, :);
AFMgrid_NaN = setdiff(floor(AFMgrid), floor(AFM_measured_xy),'stable', 'rows'); %returns stable order, return the rows from AFMgrid that are not in AFM_measured_xy, with no repetitions.
AFM_all_tec = cat(1, AFM_measurements_overlap, AFMgrid_NaN);
Grid_stiffness = cat(1, Measured_stiffness, NaN(length(AFMgrid_NaN), 1));

%% Rotate image around
hIm = imshow(brightfield);
sz = size(brightfield);

% Determine the position and size of the Rectangle ROI as a 4-element vector of the form [x y w h]. 
% The ROI will be drawn at the center of the image and have half of the image width and height.
pos = [(sz(2)/4) + 0.5, (sz(1)/4) + 0.5, sz(2)/2, sz(1)/2];

% Create a rotatable Rectangle ROI at the specified position and set the Rotatable property to true. 
% You can then rotate the rectangle by clicking and dragging near the corners. 
% As the ROI moves, it broadcasts an event MovingROI. By adding a listener for that event and a 
% callback function that executes when the event occurs, you can rotate the image in response to 
% movements of the ROI.

h = drawrectangle('Rotatable',true,...
    'DrawingArea','unlimited',...
    'Position',pos,...
    'FaceAlpha',0);

h.Label = 'Rotate rectangle to rotate image';
addlistener(h,'MovingROI',@(src,evt) rotateImage(src,evt,hIm,brightfield));

message = sprintf('Rotate the box and image using one of the rectangle vertices until it is at the correct angle. Click ok when done.');
    uiwait(msgbox(message));
    clear message
    
%% Get angle and transform coordinates of the tectum outline
global angle
RotatedIm = imrotate(brightfield,angle);   % rotation of the main image (im)
RotMatrix = [cosd(angle) sind(angle); -sind(angle) cosd(angle)]; 
ImCenterA = [(length(brightfield)/2);(length(brightfield)/2)]';        % Center of the main image
ImCenterB = [(length(RotatedIm)/2);(length(RotatedIm)/2)]';  % Center of the transformed image

AFM_all_tec_rot = (AFM_all_tec-ImCenterA)*RotMatrix'+ImCenterB;
%checking that the coordinates have been calculated correctly
imshow(RotatedIm)
axis on
hold on
plot(AFM_all_tec_rot(:,1),AFM_all_tec_rot(:,2), 'r+', 'MarkerSize', 10, 'LineWidth', 2);

%% checking coordinates
plot(AFM_all_tec(:,1),AFM_all_tec(:,2), 'b+', 'MarkerSize', 10, 'LineWidth', 2);
plot(AFM_all_tec([1],[1]),AFM_all_tec([1],[2]), 'w+', 'MarkerSize', 10, 'LineWidth', 2);
plot(AFM_all_tec_rot([1],[1]),AFM_all_tec_rot([1],[2]), 'w+', 'MarkerSize', 10, 'LineWidth', 2);
%% Is image correctly oriented?
% Yes: Anterior is to the left, posterior to the right
% No: Posterior is to the left
imshow(RotatedIm)
ui0 = questdlg('Is the image correclty oriented (Anterior to the left)?', 'Yes', 'No');
if strcmp(ui0, 'No')
    FinalIm = flipdim(RotatedIm ,2);
    imshow(FinalIm) %flip the image horizonally
    AFM_all_tec_final = AFM_all_tec_rot;
    AFM_all_tec_final(:,1) = (AFM_all_tec_rot(:,1) - ImCenterB(1))*-1 + ImCenterB(1);
elseif strcmp(ui0, 'Yes')
    FinalIm = RotatedIm;
    AFM_all_tec_final = AFM_all_tec_rot;
end

% checking that the coordinates have been calculated correctly
imshow(FinalIm)
axis on
hold on
plot(AFM_all_tec_final(:,1),AFM_all_tec_final(:,2), 'r+', 'MarkerSize', 10, 'LineWidth', 2);

%% checking coordinates
plot(AFM_all_tec_final([1],[1]),AFM_all_tec_final([1],[2]), 'w+', 'MarkerSize', 10, 'LineWidth', 2);
%% Convert coordinates to microns
AFM_all_tec_microns = AFM_all_tec_final*conv/10^(6);

% checking that the coordinates have been calculated correctly
imshow(FinalIm)
axis on
hold on
plot(AFM_all_tec_microns(:,1),AFM_all_tec_microns(:,2), 'w+', 'MarkerSize', 10, 'LineWidth', 2);

%% checking coordinates
plot(AFM_all_tec_microns([1],[1]),AFM_all_tec_microns([1],[2]), 'b+', 'MarkerSize', 10, 'LineWidth', 2);
%% Normalise tectum size to 0 to 1
norm_AFM = normalize(AFM_all_tec_final); %from 0-1
plot(norm_AFM(:,1),-norm_AFM(:,2), 'b+', 'MarkerSize', 10, 'LineWidth', 2);

%checking coordinates
axis on
hold on
plot(norm_AFM([1],[1]),-norm_AFM([1],[2]), 'r+', 'MarkerSize', 10, 'LineWidth', 2);
%% Save coordinates and corresponding stiffness
SavingDir = PathName;
norm_AFM(:,3) = Grid_stiffness;
final_file = fullfile(SavingDir,'norm_tectum_stiffness.csv');
csvwrite(final_file,norm_AFM)

%saving the .mat file for the normalised maps
norm_tectum_file = fullfile(SavingDir,'norm_AFM');
save(norm_tectum_file,'norm_AFM');

not_norm_AFM = AFM_all_tec_final;
not_norm_AFM(:,3) = Grid_stiffness;
final_file_nn = fullfile(SavingDir,'tectum_stiffness.csv');
csvwrite(final_file_nn, not_norm_AFM)

%% rotateImage function

function rotateImage(src,evt,hIm,im)

% Only rotate the image when the ROI is rotated. Determine if the
% RotationAngle has changed
if evt.PreviousRotationAngle ~= evt.CurrentRotationAngle

    % Update the label to display current rotation
    src.Label = [num2str(evt.CurrentRotationAngle,'%30.1f') ' degrees'];

    % Rotate the image and update the display
    im = imrotate(im,evt.CurrentRotationAngle,'nearest','crop');
    hIm.CData = im;

end

global angle
angle = src.RotationAngle;

end
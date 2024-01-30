%% HCR_grid_tectum_analysis.m          by Jana Sipkova, 28/01/2024
% This script allows you to retrieve a coordinate grid with associated
% grey values across a certain area which you trace (in this case the optic tectum). 
% You get output files in normalised x and y values. Importantly, if e.g. you're 
% missing half of the outline area in measurements, this is taken into 
% account, and those grid points will just be associated with a NaN value.
%
% input: 
%      - image file which you want to analyse (image)
%      - .roi file of the selection of interest (in this case the optic
%      tectum)
%
% output:
%      - norm_tectum_HCR.csv = 3 columns, 1st = X coordinates, 2nd = Y
%      coordinates, 3rd = Grey value in A.U. X and Y are normalised
%      - norm_HCR.mat = same as norm_tectum_HCR.csv but .mat => can
%      be used as input for the Avg_tectum_map.m script
%
%% Open .tif image which where the brain has already been rotated and the tectum outlined in ImageJ
% Browse for a file, from a specified "starting folder" = PathName
PathName = '/Users/janasipkova/' %set your PathName to something appropriate
% Get the name of the file that the user wants to use.
defaultFileName = fullfile(PathName, '*.*');
[baseFileName, folder] = uigetfile(defaultFileName, 'Select a file');
if baseFileName == 0
  % User clicked the Cancel button.
  return;
end

fullFileName = fullfile(folder, baseFileName);
image = double(imread(fullFileName));

%% Import outline of the tectum from ImageJ roi file
fullROIfile = fullFileName(1:end-4)+".roi";
outline_tectum = ReadImageJROI(fullROIfile);
tec_coordinates = outline_tectum.mnCoordinates;

%optional steps to see the image, the coordinates of your ROI and the
%mask made based on your ROI
imshow(image); 
axis on
hold on
%plot(tec_coordinates(:,1), tec_coordinates(:,2), 'r+', 'MarkerSize', 10, 'LineWidth', 2)
%outline = polyshape(tec_coordinates); % turn points into polygon
%plot(outline)
mask = roipoly(image, tec_coordinates(:,1), tec_coordinates(:,2));
plot(mask)

%% Crop image according to the mask and normalise ROI size 0 to 1
[r, c] = find(mask);
row1 = min(r);
row2 = max(r);
col1 = min(c);
col2 = max(c);
croppedImage = image(row1:row2, col1:col2);
imshow(croppedImage); %choose whether to see your cropped image

%converting the image into a normalised grid, with the associated grey value
[r, c] = find(true(size(croppedImage)));
norm_HCR = [r(:), c(:), croppedImage(:)];
norm_HCR(:,1) = -normalize(norm_HCR(:,1), 'range'); %from 0-1
norm_HCR(:,2) = normalize(norm_HCR(:,2), 'range'); %from 0-1
norm_HCR(any(isnan(norm_HCR), 2), :) = []; %remove all rows with NaN

%checking that the grid shape looks as expected based on the mask
%previously (since the NaNs are now deleted)
scatter(norm_HCR(:,2), norm_HCR(:,1)); 
%in norm_HCR: 1st column are grid row, 2nd column are grid columns

%% Save coordinates and corresponding grey values
SavingDir = PathName; %saving the file to your PathName folder
final_file = fullFileName(1:end-4)+"_norm_tectum_HCR.csv"
csvwrite(final_file,norm_HCR)

%saving the .mat file for the normalised maps
norm_tectum_file = fullFileName(1:end-4)+"_norm_HCR.mat";
save(norm_tectum_file,'norm_HCR');
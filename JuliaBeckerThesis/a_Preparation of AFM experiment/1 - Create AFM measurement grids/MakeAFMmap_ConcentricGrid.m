%% MakeAFMmap_ConcentricGrid.m           11/01/2021 Julia Becker
% This script creates a concentric grid of measurement points around a
% centre point.
% 
% required INPUT:
% 	- Script asks for folder of experiment. In contrast to other map-making
%     scripts,'overview.tif' (RGB colour) in 'Pics/calibration' is not required
%   - Give centre coordinates and distances in µm as displayed in the JPK
%     software
%   - Indicate whether to measure centre-to-periphery or periphery-to-centre
%   - Indicate whether to measure clockwise or counterclockwise
% 
% OUTPUT:
%   - .txt file containing measurement coordinates
%   - .mat file containing work space variables
% 
% Caution!
%   - This script does not establish conversion variables. If you want to
%     plot your map on top of your overview images, make sure you establish
%     conversion variables with a different script.

clear variables
close all

%% User input
x_center = 100;             % Center of sphere, x coordinate in µm
y_center = 1000;            % Center of sphere, y coordinate in µm
spacing = 20;               % between radii, in µm
extension_max = 230;        % maximum distance from centre, in µm

% Measure (1) from center to periphery or (2) from periphery to centre?
in_out = 1;

% Measure (1) clockwise or (2) counter-clockwise?
rot_dir = 1;

%% SELECT SECTION FOLDER
path_sec = uigetdir('','Select section folder (#XX_secX)');

%%
% Calculate number of radii
num_rad = floor(extension_max/spacing);

% Define number of points on radii
num_points = NaN(num_rad+1,4);            % first column: number of radius, second column: number of points on this radius, third column: number of points within a quarter (90°) of this radius, fourth column: ° between axis
num_points(1:num_rad+1,1) = 0:num_rad;
num_points(1,2) = 1;
num_points(2:num_rad+1,2) = [6:6:6*num_rad];
num_points(1:num_rad+1,3) = num_points(1:num_rad+1,2)/4;
num_points(1:num_rad+1,4) = 360./num_points(1:num_rad+1,2);


%% For each radius, calculate the points
% First colum: x coordinates, second column: y coordinates
results = NaN(sum(num_points(:,2)),2);

counter = 1;

for i = 1:size(num_points,1)   % iterate over radii
    for j = 1:num_points(i,2)       % iterate over points on individual radius
        
        c = spacing*(i-1);                            % distance from centre = hypothenuse of triangle
        alpha = num_points(i,4)*(j-1);              % angle inside triangle
        
        x = sind(alpha)*c;
        y = cosd(alpha)*c;
        
        if rot_dir == 2
            x = -x;             % invert for counter-clockwise direction
        end
        
        results(counter,1) = x;
        results(counter,2) = y;
        clear c alpha a b x y
        counter = counter + 1;
    end
end

if in_out == 2
    results = flipud(results);
    results(:,1) = -1*results(:,1);
end

%% Add position of center from user input
results(:,1) = results(:,1) + x_center;
results(:,2) = results(:,2) + y_center;

%% Make figure to show order of points
% Comment section out to suppress output
figure
axis equal
xlim([x_center-extension_max, x_center+extension_max])
ylim([y_center-extension_max, y_center+extension_max])
hold on
for i = 1:size(results,1)
scatter(results(i,1),results(i,2),20,'b','filled')
pause(0.05)
end

%% Convert results coordinates from µm to m
results = results./1000000;

%% Save point list
dlmwrite(fullfile(path_sec, 'AFMgrid.txt'),results,'delimiter',' ','precision','%1.7f')

%% Save the variables
save(fullfile(path_sec, 'AFMgrid_variables.mat'))


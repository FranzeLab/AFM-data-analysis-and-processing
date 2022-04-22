%% MakeAFMmap_RectangularGrid_standard.m            17/07/2019 Julia Becker
% This script allows the user to tailor a rectangular AFM measurement grid.
% Based on three landmark points for which the stage coordinates are known,
% this script establishes conversion variables between the stage and the
% overview image. The user can choose the corner points of the grid and the
% resolution in x and y. Subsequently, certain areas/measurement points can
% be excluded to tailor the grid shape to the user's needs. It is optional
% to add additional points from outside the grid. Finally, the order in
% which the grid should be measured can be set by the user.
%
% required INPUT:
%   - script asks for folder of experiment which needs to contain
%   'overview.tif' (RGB colour) in 'Pics/calibration'
%   - Give landmark point coordinates in µm! 

clearvars
close all

%% SELECT SECTION FOLDER
path_sec = uigetdir('','Select section folder (#XX_secX)');

%% IMPORT AND DISPLAY IMAGE
filename_image = fullfile(path_sec,'Pics', 'calibration', 'overview.tif'); % Get the full filename, with path prepended.
if exist(filename_image, 'file') ~= 2
    warndlg(sprintf(char("The overview image was not found. Make sure it's stored like this:\n\t\t--> Pics --> calibration --> overview.tif")))
end
I = imread(filename_image);

%% Display image
image(I);
axis on
axis image
set(gcf, 'Position', get(0, 'Screensize'));

%% DECIDE WHETHER TO MAKE NEW CONVERSION VARIABLES OR LOAD PREVIOUS ONES
userselect1 = '';
while exist(userselect1) == 0
    userselect1 = questdlg('Do you want to load the previously determined conversion parameters between stage and image?','Loading options','Yes','No','Yes');
    if strcmp('Yes',userselect1) == 1
        if exist(fullfile(path_sec,'Pics','calibration', 'conversion_variables.mat'), 'file') ~= 2
            warndlg(sprintf(char("The conversion variables were not found. Make sure they are stored like this:\n\t\t--> Pics --> calibration --> conversion_variables.mat")))
        end
        load(fullfile(path_sec,'Pics','calibration','conversion_variables.mat'))
        break
        
    elseif strcmp('No',userselect1) == 1
        %%
        message = sprintf('Please select three landmark points for which the\nexact stage coordinates are known and indicate these in µm\nas the JPK software displays them (e.g. 7027.4).');
        uiwait(msgbox(message));
        clear message
 
        %% USER INPUT OF LANDMARK POINTS
        %% Make user select the first landmark point and input the stage coordinates for this point
        message = sprintf('1st landmark point - zoom now if needed, then click okay.');
        uiwait(msgbox(message));
        clear message
        
        [x1,y1] = ginput(1);    % store image coordinates of selected point
        user_val = inputdlg({sprintf('What is the ... of this point in the motorised stage coordinate system?\n\n     X coordinate'),sprintf('     Y coordinate')});
        a1 = str2num(user_val{1})./1000000
        b1 = str2num(user_val{2})./1000000
        %% Make user select the second landmark point and input the stage coordinates for this point
        message = sprintf('2nd landmark point - zoom now if needed, then click okay.');
        uiwait(msgbox(message));
        clear message
        
        [x2,y2] = ginput(1);    % store image coordinates of selected point
        user_val = inputdlg({sprintf('What is the ... of this point in the motorised stage coordinate system?\n\n     X coordinate'),sprintf('     Y coordinate')});
        a2 = str2num(user_val{1})./1000000
        b2 = str2num(user_val{2})./1000000
        %% Make user select the third landmark point and input the stage coordinates for this point
        message = sprintf('3rd landmark point - zoom now if needed, then click okay.');
        uiwait(msgbox(message));
        clear message
        
        [x3,y3] = ginput(1);    % store image coordinates of selected point
        user_val = inputdlg({sprintf('What is the ... of this point in the motorised stage coordinate system?\n\n     X coordinate'),sprintf('     Y coordinate')});
        a3 = str2num(user_val{1})./1000000
        b3 = str2num(user_val{2})./1000000
        
        %% CALCULATE FACTORS WHICH ALLOW CONVERSION FROM STAGE COORDINATE SYSTEM INTO THE IMAGE COORDINATE SYSTEM
        
        %% Put points together in vectors
        A = [a1; a2; a3];
        B = [b1; b2; b3];
        X = [x1; x2; x3];
        Y = [y1; y2; y3];
        
        %% Make matrix of stage coordinates
        AB = NaN(3);
        AB(:,1) = A(:);
        AB(:,2) = B(:);
        AB(:,3) = 1;
        
        %% Invert the matrix and calculate the factors
        AB_I = inv(AB);
        MNR = AB_I*X;
        OPS = AB_I*Y;
        
        m = MNR(1);
        n = MNR(2);
        r = MNR(3);
        
        o = OPS(1);
        p = OPS(2);
        s = OPS(3);
        
        M = [m n; o p];
        break
        
    else
        uiwait(msgbox('This is not a valid input. Please try again.'))
    end
end

%% Allows user to save the conversion variables for future use
if strcmp('No', userselect1) == 1
    userselect2 = questdlg('Do you want to save the conversion parameters between stage and image for future use?','Saving options','Yes','No','Yes');
    if strcmp('Yes',userselect2) == 1
        save(fullfile(path_sec,'Pics','calibration', 'conversion_variables.mat'),'m','n','o','p','r','s','M','MNR','OPS')
    end
end

%% Display image
imshow(I);
axis image
hold on;
set(gcf, 'Position', get(0, 'Screensize'));

%% MAKE A GRID
%% Get corner points for grid

ui = 'No';

while strcmp('No', ui) == 1;
    imshow(I);
    hold on
    message = sprintf('Select the top left corner point');
    uiwait(msgbox(message));
    [x_corner1, y_corner1] =  ginput(1);
    plot(x_corner1, y_corner1, 'r.', 'MarkerSize', 10, 'LineWidth', 2, 'Color', 'm');
    
    message = sprintf('Select the bottom right corner point');
    uiwait(msgbox(message));
    [x_corner2, y_corner2] =  ginput(1);
    plot(x_corner2, y_corner2, 'r.', 'MarkerSize', 10, 'LineWidth', 2, 'Color', 'm');
    
    ui = questdlg('Happy with this?','Accuracy','Yes','No','Yes');
end
clear ui

%%
stage_zero = inv(M)*[0-r;0-s];
stage_100x = inv(M)*[100-r;0-s];
stage_100y = inv(M)*[0-r;100-s];

x_100_pixel_in_meter = sqrt((stage_zero(1,1)-stage_100x(1,1))^2+(stage_zero(2,1)-stage_100x(2,1))^2);
y_100_pixel_in_meter = sqrt((stage_zero(1,1)-stage_100y(1,1))^2+(stage_zero(2,1)-stage_100y(2,1))^2);

conv_x = 100/x_100_pixel_in_meter;
conv_y = 100/y_100_pixel_in_meter;

resolution = inputdlg({sprintf('Which resolution should your grid have in µm?\n\n     in X direction'),sprintf('     in Y direction')});
resolution_x = str2num(resolution{1,1})/1000000;
resolution_y = str2num(resolution{2,1})/1000000;

dist_x = resolution_x*conv_x;
dist_y = resolution_y*conv_y;

%% Determine x and y steps
x_steps = floor((x_corner2 - x_corner1) / dist_x);
y_steps = floor((y_corner2 - y_corner1) / dist_y);

%% Determine x and y grid coordinates
grid_x = NaN((x_steps + 1),1);
grid_y = NaN((y_steps + 1),1);

clear i 
for i = 1:size(grid_x,1)
    grid_x(i,1) = x_corner1 + (i-1)*dist_x;
end

for i = 1:size(grid_y,1)
    grid_y(i,1) = y_corner1 + (i-1)*dist_y;
end
clear i 

%% Put x and y grid coordinates together to make all grid coordinates
grid = NaN(((x_steps+1)*(y_steps+1)),3);        % activation status of point
grid = zeros(((x_steps+1)*(y_steps+1)),4);      % identifier for manually added points

clear i
k = 0;
for i = 1:(y_steps+1)
    grid((1+k):((x_steps+1)+k),1) = grid_x;
    grid((1+k):((x_steps+1)+k),2) = grid_y(i,1);
    k = k+(x_steps+1);
end
clear i k
grid(:,3) = 1;

grid1 = grid(:, 1:2); % Duplicate grid without 3rd column for dsearchn function

%%
imshow(I);
clear i
for i = 1:size(grid,1)
    if grid(i,3) == 1
        plot(grid(i,1), grid (i,2), 'r.', 'MarkerSize', 10, 'LineWidth', 2, 'Color', 'r');
    else plot(grid(i,1), grid (i,2), 'r.', 'MarkerSize', 10, 'LineWidth', 2, 'Color', 'b');
    end
end

act_points = size(grid,1);
an = strcat(num2str(act_points)," active measurements");
hText = text(50,50,an,'FontSize',12, 'Color', 'w');

%% Add additional points manually
ui = questdlg('Do you want to manually select additional points','Additional points','Yes','No','Yes');
added_points = 0;
if strcmp ('Yes', ui) == 1
    message = sprintf('Please define as many additional points as you like with left clicks in the order they should finally be measured.\nRight click when you are done.');
    uiwait(msgbox(message));
    
    while 1;
        hold on
        [x_test, y_test] =  ginput(1);
        
        key = get(gcf, 'SelectionType');
        if strcmpi(key, 'alt')
            break
        end
        
        plot(x_test, y_test, 'r.', 'MarkerSize', 10, 'LineWidth', 2, 'Color', 'r');
        added_points = added_points+1;
        
        delete(hText);
        act_points = size(grid,1)+added_points;
        an = strcat(num2str(act_points)," active measurements");
        hText = text(50,50,an,'FontSize',12, 'Color', 'w');
        
        grid(size(grid,1)+1,:) = [x_test y_test 1 1];    % adds one row with new point after last row

    end
    grid1 = grid(:,1:2);
end

%% Deselect/reselect points of the previously established grid
message = sprintf('You can now deselect/reselect gropus of points by drawing regions.\nSelected points are displayed in red, deselected ones in blue.\nFurther changes of individual points can be done in the next step.\nClick left to start, click right when you are done.');
uiwait(msgbox(message));
clear message

% (De-)Activation based on a user-selected area
i = 1;
[bli,bla] =  ginput(1); % to remove 'alt' as the last key that was pressed on the figure from memory otherwise while loop won't run
clear bli bla

while 1;
    hold on
     
    key = get(gcf, 'SelectionType');
    if strcmpi(key, 'alt')
        break
    end
    
    annotations{i,1} = drawassisted('Closed', true);
    mask{i,1} = createMask(annotations{i,1},I);
    annotations{i,1}.Visible = 'off';
    
    clear k
    for k = 1:size(grid,1)
        if mask{i,1}(round(grid(k,2)),round(grid(k,1))) == 1
            
            % Change activation value (third column of grid) to opposite
            if grid(k,3) == 1
                grid(k,3) = 0;
                plot(grid(k,1), grid (k,2), 'r.', 'MarkerSize', 10, 'LineWidth', 2, 'Color', 'b')
            elseif grid(k,3) == 0
                grid (k,3) = 1;
                plot(grid(k,1), grid (k,2), 'r.', 'MarkerSize', 10, 'LineWidth', 2, 'Color', 'r');
            else
                message = sprintf('Check third column of grid!\nValue other than 1 or 0 present.');
                uiwait(msgbox(message));
            end
        end
    end
    
    delete(hText);
    act_points = sum((grid(:,3)==1));
    an = strcat(num2str(act_points)," active measurements");
    hText = text(50,50,an,'FontSize',12, 'Color', 'w');
    
    i = i+1;
end
clear i k

message = sprintf('You can now deselect/reselect points by clicking close to them.\nSelected points are displayed in red, deselected ones in blue.\nRight click when you are done.');
uiwait(msgbox(message));
clear message

%% (De-)Activation based on individual user-selected points
while 1;
    hold on
    
    [x_test, y_test] =  ginput(1);
    
    key = get(gcf, 'SelectionType');
        if strcmpi(key, 'alt')
            break
        end
      
    %% Find closest grid point to test point
    test = [x_test, y_test];
    clear k
    k = dsearchn(grid1, test);
    
    %% Change activation value (third column) of grid point closest to test
    % point
    if grid(k,3) == 1
        grid(k,3) = 0;
        plot(grid(k,1), grid (k,2), 'r.', 'MarkerSize', 10, 'LineWidth', 2, 'Color', 'b');
    elseif grid(k,3) == 0
        grid (k,3) = 1;
        plot(grid(k,1), grid (k,2), 'r.', 'MarkerSize', 10, 'LineWidth', 2, 'Color', 'r');
    else
        message = sprintf('Check third column of grid!\nValue other than 1 or 0 present.');
        uiwait(msgbox(message));
    end
    
    delete(hText);
    act_points = sum((grid(:,3)==1));
    an = strcat(num2str(act_points)," active measurements");
    hText = text(50,50,an,'FontSize',12, 'Color', 'w');
   
end

%% Calculate result matrix which only contains 'activated' points (activation value = 1)
results = grid;
condition = grid(:,3)==0;
results(condition,:) = [];

%% Ordering points according to user instructions

results1 = results(find(results(:,4)==0),:);
results2 = results(find(results(:,4)==1),:);

% Check if activated grid points exist
if isempty(results1) == 0
    while 1
        ui2 = inputdlg({sprintf('How would you like the grid points ordered?\n\n     1 - top to bottom\n     2 - bottom to top\n     3 - right to left\n     4 - left to right\n\nPlease enter the number of the correct option.\n')});
        if isempty(intersect(ui2,{'1','2','3','4'}))
            uiwait(msgbox('Invalid input - Please try again!'));
        else
            ui2 = str2num(ui2{1,1});
            break
        end
    end
    
    % Check if manually added points exist, too
    if isempty(find(results(:,4)==1)) == 0
        while 1
            ui3 = inputdlg({sprintf('Should manually added points be measured before or after the grid?\n\n     1 - before\n     2 - after\n\n')});
            if isempty(intersect(ui3,{'1','2'}))
                uiwait(msgbox('Invalid input - Please try again!'));
            else
                ui3 = str2num(ui3{1,1});
                break
            end
        end
    end
    
    prim = [2;2;1;1];
    sec = [1;1;2;2];
    prim_ord = {'ascend';'descend';'descend';'ascend'};
    sec_ord_1 = {'descend';'descend';'ascend';'ascend'};
    sec_ord_2 = {'ascend';'ascend';'descend';'descend'};
    
    prim = table(prim);
    sec = table(sec);
    prim_ord = table(prim_ord);
    sec_ord_1 = table(sec_ord_1);
    sec_ord_2 = table(sec_ord_2);
    
    S = [prim sec prim_ord sec_ord_1 sec_ord_2];
    
    results1 = sortrows(results1,[S.prim(ui2) S.sec(ui2)],{S.prim_ord{ui2} S.sec_ord_1{ui2}});
    
    clear i j k
    j = results1(1,S.prim(ui2));
    j1 = 1;
    k1 = 1;
    k = 0;
    
    for i = 1:size(results1, 1)
        if results1(i,S.prim(ui2)) == j
            k = k+1;
        else
            if mod(j1,2) == 0
                results1(k1:k,S.sec(ui2)) = sortrows(results1(k1:k,S.sec(ui2)),S.sec_ord_2{ui2});
            end
            k = k+1;
            j1 = j1+1;
            k1 = k;
            j = results1(k,S.prim(ui2));
        end
    end
    
    if mod(j1,2) == 0
        results1(k1:k,S.sec(ui2)) = sortrows(results1(k1:k,S.sec(ui2)),S.sec_ord_2{ui2});
    end
    
    clear i j j1 k k1
    
    %% Make results_ordered
    % If there are no manually added points
    if isempty(find(results(:,4)==1)) == 1
        results_ordered = results1;
    % If there are manually added points: put them at beginning or end
    elseif isempty(find(results(:,4)==1)) == 0
        if ui3 == 1
            results_ordered = [results2; results1];
        elseif ui3 == 2
            results_ordered = [results1; results2];
        end
    end
    
% If all grid points have been deactivated, use only manually added points    
else
    results_ordered = results2;          
end

%% Optional: Plot grid in the order of measurements.
% Might need to adjust pause time depending on number of measurements
imshow(I);
axis on
axis image
hold on;
set(gcf, 'Position', get(0, 'Screensize'));

for i = 1:size(results_ordered,1)
    plot(results_ordered(i,1), results_ordered(i,2),'r.', 'MarkerSize', 7, 'LineWidth', 2, 'Color', 'r');
    pause(0.1);                 % Comment this out to create the image without having grid points appear in the indicated order
end

%% Convert point list back into stage coordinates
results_stage = NaN(size(results_ordered,1),2);

clear i
for i = 1:size(results_stage, 1)
    res_x_y = inv(M)*[(results_ordered(i,1)-r);(results_ordered(i,2)-s)];
    results_stage(i,1) = res_x_y(1,1);
    results_stage(i,2) = res_x_y(2,1);
end

%% Save point list
dlmwrite(fullfile(path_sec, 'AFMgrid.txt'),results_stage,'delimiter',' ','precision','%1.7f')

%% Save figure of measurement grid
figure_name = fullfile(path_sec, 'AFMgrid.tif');
saveas(gcf,figure_name);

%% Save the variables
save(fullfile(path_sec, 'AFMgrid_variables.mat'))

%% Inform user of resulting measurement grid size
x_dim = (max(results(:,1)) - min(results(:,1)))/dist_x +1;
y_dim = (max(results(:,2)) - min(results(:,2)))/dist_y +1;

msgbox(['The measurement grid will be ' num2str(y_dim) ' x ' num2str(x_dim) ', and ' num2str(size(results_ordered,1)) ' measurements in total.'])

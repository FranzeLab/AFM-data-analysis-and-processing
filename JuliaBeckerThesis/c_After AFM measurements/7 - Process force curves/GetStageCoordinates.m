function [stage_coord] = GetStageCoordinates(image_coord, PathName, ui0)
%GETSTAGECOORDINATES Loads conversion variables and converts image to stage
%coordinates
% 
%     - 'image_coord' must be a two-column vector, where the first column
%     corresponds to the x and the second column to the y image coordinates.
%     - the output 'stage_coord' has the same format as the input

if size(image_coord,2) ~= 2
    error('Error. \nInput must be a 2-column vector, instead there were %s columns.',num2str(size(image_coord,2)))
end

if strcmp(ui0, 'Simple') == 1
    load(fullfile(PathName, 'Pics', 'calibration', 'conversion_variables.mat'),'M','r','s')
elseif strcmp(ui0, 'Complex') == 1
    load(fullfile(PathName, 'calibration_all', 'conversion_variables.mat'),'M','r','s')
end
    
stage_coord = NaN(size(image_coord));    
for i = 1:size(stage_coord, 1)
    res_x_y = inv(M)*[(image_coord(i,1)-r);(image_coord(i,2)-s)];
    stage_coord(i,1) = res_x_y(1,1);
    stage_coord(i,2) = res_x_y(2,1);
    clear res_x_y
end

end


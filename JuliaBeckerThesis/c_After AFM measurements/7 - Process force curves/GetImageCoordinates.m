function [data, I] = GetImageCoordinates(data, PathName, ui0, source)    % by Julia Becker, 01/04/2020
%GETIMAGECOORDINATES Loads conversion variables and overview image,
%creates new data column of image coordinates and a roi column set to '0'
if strcmp(ui0, 'Simple') == 1
    load(fullfile(PathName, 'Pics', 'calibration', 'conversion_variables.mat'))
    I = imread(fullfile(PathName, 'Pics', 'calibration', 'overview.tif'));
elseif strcmp(ui0, 'Complex') == 1
    load(fullfile(PathName, 'calibration_all', 'conversion_variables.mat'))
    I = imread(fullfile(PathName,'calibration_all', 'overview.tif'));
end

x_image(:,1) = m.*data.x(:) + n.*data.y(:) + r;
y_image(:,1) = o.*data.x(:) + p.*data.y(:) + s;
roi = zeros(height(data),1);
amend = table(x_image, y_image, roi);
data = [data amend];

save(source, 'data', 'I', '-append')
clear amend x_image y_image roi
end


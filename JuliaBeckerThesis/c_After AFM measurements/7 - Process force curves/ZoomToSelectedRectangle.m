function [x_lim, y_lim] = ZoomToSelectedRectangle(I)                % JB 17/06/2021
%ZOOMTOSELECTEDRECTANGLE Interactive choice of zoom window which can be
%different shape to input image
%   After you have selected and adjusted your zoom rectangle, right click
%   and select "Crop image" to continue

%figure
%ShowImage(I)
uiwait(msgbox("Select a rectangle and adjust, then right-click and click on 'Crop image'."))
[~,rect] = imcrop(I);

x_lim = [rect(1) rect(1)+rect(3)];
y_lim = [rect(2) rect(2)+rect(4)];
close(gcf)
end


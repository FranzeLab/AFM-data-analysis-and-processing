function [markersize] = OptimiseMarkersize(data, I, markertype, markersize, bar_intervals, x_lim, y_lim)    % by Julia Becker, 14/10/2021
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

ui = markersize;

threshold = ceil(max(data.modulus));
heatmap_scale = hot(threshold);

data1 = data;
data1.modulus = round(data1.modulus);
data1(isnan(data1.modulus),:) = [];
data1(find(data1.modulus == 0),:) = [];
data1.modulus(find(data1.modulus > threshold)) = threshold;

colour_spec = heatmap_scale(data1.modulus(:),:);

ShowImage(I)
set(gca,'XLim',x_lim)
set(gca,'Ylim',y_lim)
s = scatter(data1.x_image(:), data1.y_image(:), markersize, colour_spec(:,:), 'filled', markertype);

while 1
    ui = inputdlg(sprintf("Please enter a markersize.\n\nIf you are happy with the previous one, enter 'done'."), 'Find good markersize', [1 55], {num2str(markersize)});  
    if strcmp(ui, 'done') == 1
        close all
        break
    else
        markersize = str2double(ui);
     
        s.Visible = 'off';
        s = scatter(data1.x_image(:), data1.y_image(:), markersize, colour_spec(:,:), 'filled', markertype);
        s.Visible = 'on';
        
        % Include colour scale bar
        colormap(heatmap_scale)
        colorbar
        colorbar_ticklabels = [0:bar_intervals:threshold];
        colorbar_ticks = colorbar_ticklabels/threshold;
        colorbar('Ticks',colorbar_ticks,'TickLabels',colorbar_ticklabels, 'FontSize', 18)
        clear cb
    end
    
end


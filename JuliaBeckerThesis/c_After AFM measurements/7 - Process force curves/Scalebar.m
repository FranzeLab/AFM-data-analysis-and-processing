function Scalebar(bar_length, bar_thickness, fontsize, PathName)        % JB 14/10/2021
%SCALEBAR Will add a scalebar and label in the lower left corner of the
%plot
%   Input:
%         - bar_length:       in µm, will convert the text label to mm if entered number >= 1000 
%         - bar_thickness:    line width as a parameter of linspec, 5 is recommended
%         - fontsize:         20 is recommended; if set to 0, no label is produced

% Load conversion variables to extract distance conversion
load(fullfile(PathName,'Pics','calibration','conversion_variables.mat'),'M','r','s')
stage_zero = inv(M)*[0-r;0-s];
stage_100x = inv(M)*[100-r;0-s];
stage_100y = inv(M)*[0-r;100-s];

x_100_pixel_in_meter = sqrt((stage_zero(1,1)-stage_100x(1,1))^2+(stage_zero(2,1)-stage_100x(2,1))^2);
y_100_pixel_in_meter = sqrt((stage_zero(1,1)-stage_100y(1,1))^2+(stage_zero(2,1)-stage_100y(2,1))^2);

conv_x = 100/x_100_pixel_in_meter;
conv_y = 100/y_100_pixel_in_meter;
conv = (conv_x + conv_y)/2;             % pixel per meter - averaged as may slightly vary in x and y

clear M r s stage_zero stage_100x stage_100y x_100_pixel_in_meter y_100_pixel_in_meter conv_x conv_y

% Convert scalebar length to meter and calculate actual length in data units
bar = bar_length/10^6;
bar = bar*conv;           % now bar_length is in data units

% Place scalebar at bottom right corner
x = get(gca,'XLim');
y = get(gca,'YLim');

x_dist = 80;   % distance from right edge - 100
y_dist = 80;   % distance from bottom edge - 120

gca;
hold on
plot([x(2)-x_dist-bar x(2)-x_dist],[y(2)-y_dist y(2)-y_dist],'Color','w','LineWidth',bar_thickness)

% Create text label
if fontsize ~= 0
    if bar_length >= 1000
        num = bar_length/1000;
        txt = strcat(num2str(num), " mm");
    else
        num = bar_length;
        txt = strcat(num2str(num), " µm");
    end
    clear num
    
    x_box = x(2)-x_dist-0.5*bar;
    y_box = y(2)-y_dist+5;
    
    text(x_box, y_box, txt,'FontSize',fontsize,'FontWeight','bold','Color','w','HorizontalAlignment','center','VerticalAlignment','top')
end
end


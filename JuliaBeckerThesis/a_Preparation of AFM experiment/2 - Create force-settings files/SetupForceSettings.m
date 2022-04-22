%% SetupForceSettings.m                     08/12/2020 Julia Becker  
% This script creates .force-settings files for the JPK software which
% allow to automatically read in and/or alter AFM measurement settings
% during an AFM experiment.

% CAVE! You need to have calibrated your cantilever before running this
% script as it requires the spring constant and sensitivity values.

% required INPUT:
%   - Please adjust all parameters in the "user input" section according to
%     your needs. In particular, spring constant and sensitivity need to be
%     set to the calibration values of the current cantilever.
%   - First dialogue to choose folder:
%     Experimental folder where files should be created
%   - Second dialogue to choose file:
%     Indicate location of template file ("template.force-settings"). It's
%     recommended to change the code to avoid manual input for this once
%     the location of the template file is not going to change.

% OUTPUT:
%   - .txt files to determine the order in which to read in the force
%     settings
%       - order_force-settings.txt
%             - iteration over non-creep settings
%       - order_force-settings_creep.txt
%             - iteration over creep settings
%   - .force-settings files for JPK software
%       - *nN_*um.force-settings
%             - excluding creep segment
%       - *nN_*um_creep.force-settings
%             - including creep segment

clearvars
close all

%% %%%%%%%%%%% START OF USER INPUTS %%%%%%%%%% %%%
%% Get experimental folder
path = uigetdir;

%% Sensitivity and spring constant
sensitivity = 43.22;               % nm/V 
springconst = 2.583;              % N/m

%% Number of "measurement blocks" - How many times do you want to iterate over the different force settings (max)?
num_of_repeats = 1;

%% Pulling length and number of points (in extend curve)
pull_length = 100;                                  % in µm
num_of_points_extend = 2500;
num_of_points_retract = num_of_points_extend;       %./10;

%% Gains for creep
igain = '3.0';
pgain = '1.0E-4';

%% Which force setpoints in nN?
stpts = [30; 90; 150; 300; 600; 1200];

%% Which extend speeds in µm/s?
spds = [20; 100; 400; 800; 1200];

%% Which retract speeds in µm/s?
speed_retract = [800; 800; 800; 800; 800];    % in µm/s - set retract speed manually for each extend speed setting
% speed_retract = spds;                         % to set it to the same as extend speed


%% %%%%%%%%%%% END OF USER INPUTS %%%%%%%%%% %%%
%% Make conditions by combining force setpoints and speeds
conditions = NaN(length(stpts).*length(spds),1);

counter = 1;

for i = 1:length(stpts)
    for k = 1:length(spds)
        conditions(counter,1) = stpts(i,1);
        conditions(counter,2) = spds(k,1);
        conditions(counter,3) = speed_retract(k,1);
        counter = counter+1;
    end
end

setpoint = conditions(:,1);
setpoint = table(setpoint);
speed = conditions(:,2);
speed = table(speed);
speed_retract =  conditions(:,3);
speed_retract =  table(speed_retract);

clear conditions counter i k 
condition = [setpoint speed speed_retract];

%% Make filenames
filename = cell(size(condition.speed));
filename = table(filename);
condition = [condition filename];

for i = 1:height(condition)
    condition.filename{i} = strcat(num2str(condition.setpoint(i)), 'nN_', num2str(condition.speed(i)), 'um');  
end
clear i

filename2 = condition.filename;
filename2(:) = strcat(filename2(:),'_creep.force-settings');
filename2 = table(filename2);
condition = [condition filename2];

filename3 = condition.filename;
filename3(:) = strcat(filename3(:),'.force-settings');
filename3 = table(filename3);
condition = [condition filename3];

%% Read in template file
[template_file,template_path] = uigetfile('*.force-settings','Select the template force-settings file','template.force-settings');
template = readfile_fe(fullfile(template_path,template_file));
template = template';
template = template(1:end-1);
clear template_file template_path

%% Replace lines in template according to conditions
pull_length2 = pull_length./10^6;

for i = 1:height(condition)
%% Make replacements
current = template;
duration_extend = pull_length./condition.speed(i);
duration_retract = pull_length./condition.speed_retract(i);
force_setpoint = condition.setpoint(i)./springconst./sensitivity;
if force_setpoint > 20
    warndlg(strcat("Using a setpoint of ", num2str(condition.setpoint(i)), " nN exceeds the reasonable photo diode limit of ~20  V! Use lower setpoint or stiffer cantilever."))
    pause
end

% EXTEND
current{31} = strcat('force-settings.segment.0.duration=',num2str(duration_extend));
current{34} = strcat('force-settings.segment.0.num-points=',num2str(num_of_points_extend));
current{35} = strcat('force-settings.segment.0.setpoint=',num2str(force_setpoint,15));
current{39} = strcat('force-settings.segment.0.z-start=',num2str(pull_length2, '%1.1E'));

% CREEP
current{41} = strcat('force-settings.segment.1.i-gain=',igain);
current{45} = strcat('force-settings.segment.1.p-gain=',pgain);

% RETRACT
current{49} = strcat('force-settings.segment.2.duration=',num2str(duration_retract));
current{52} = strcat('force-settings.segment.2.num-points=',num2str(num_of_points_retract));
current{57} = strcat('force-settings.segment.2.z-start=',num2str(pull_length2, '%1.1E'));

%% Save as _creep.force-settings
file = fullfile(path, condition.filename2(i));
fileID = fopen(file{1},'w');
fprintf(fileID,'%s\n',current{:});
fclose(fileID);

%% Now remove creep part and save as non-creep
current(40:48,:) = [];
current = strrep(current,'force-settings.segment.2.','force-settings.segment.1.');
current = strrep(current,'force-settings.segment.3.','force-settings.segment.2.');
current = strrep(current,'force-settings.segments.size=4','force-settings.segments.size=3');

%% Save as .force-settings
file = fullfile(path, condition.filename3(i));
fileID = fopen(file{1},'w');
fprintf(fileID,'%s\n',current{:});
fclose(fileID);
end

%% Write .txt file for order of .force-settings files
file = fullfile(path, 'order_force-settings_creep.txt');
fileID = fopen(file,'w');
for i = 1:num_of_repeats
    fprintf(fileID,'%s\n',condition.filename2{:});
end
fclose(fileID);

file = fullfile(path, 'order_force-settings.txt');
fileID = fopen(file,'w');
for i = 1:num_of_repeats
    fprintf(fileID,'%s\n',condition.filename3{:});
end
fclose(fileID);
function [data] = GetDetails(data)    % by Julia Becker, 01/04/2020
%GETDETAILS Tries to retrieve animal number, setpoint, speed, orientation
% from the path

for i = 1:height(data)
    pathparts = strsplit(data.folder{i}, filesep);
    pathparts = pathparts(1, end-2:end-1);
    pathparts = strjoin(pathparts, '_');
    pathparts = strsplit(pathparts, {'_', '-'});
%     pathparts = strsplit(data.file{i}, {'_', '-'});
    
    % Find animal number
    if isempty(find(contains(pathparts,'#'))) == 0
        animal = pathparts{find(contains(pathparts,'#'))};
        animal = str2double(strrep(animal, '#', ''));
        data.animal(i,1) = animal;
    end
    
    % Find setpoint
    if isempty(find(contains(pathparts,'nN'))) == 0
        setpoint = pathparts{find(contains(pathparts,'nN'))};
        setpoint = str2double(strrep(setpoint, 'nN', ''));
        data.setpoint(i,1) = setpoint;
        if abs(data.setpoint(i) - data.setpoint_N(i).*10^9) > 1
            warndlg('The setpoint in the folder name and the setpoint from the .txt header differ by more than 1 nN. Is your folder labelled correctly?')
        end
    end
    
    % Find speed
    if isempty(find(contains(pathparts,{'µm','um','µms'}))) == 0
        speed = pathparts{find(contains(pathparts,{'µm','um','µms'}))};
        speed = strrep(speed,'µm','');
        speed = strrep(speed,'um','');
        speed = strrep(speed,'µms','');
        speed = str2double(speed);
        data.speed(i,1) = speed;
    end
    
    % Find animal number
    if isempty(find(contains(pathparts,{'sagittal','horizontal','transverse','coronal'}))) == 0
        orientation = pathparts{find(contains(pathparts,{'sagittal','horizontal','transverse','coronal'}))};
        if strcmp(orientation, 'coronal') == 1
            orientation = 'transverse';
        end
        data.orient{i,1} = orientation;
    end
    
    clear animal setpoint speed orientation
end
end


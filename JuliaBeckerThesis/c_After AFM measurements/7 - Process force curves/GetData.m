function [data] = GetData(PathName)    % by Julia Becker, 01/04/2020
%GETDATA     Imports all .mat file and additional information
%   Also reads sensitivity, spring constant and setpoint in V from .txt
%   file and computes bead radius used.
%% Get all .txt files in 'files and labfile' in this folder
invent = dir(fullfile(PathName,'**','files and labfile','*.mat'));   % JB 31/10/19 - changed from *.txt to *.mat

%% Make a table containing all .mat files similar to Ryan's output
folder = {invent.folder};
folder = folder(:);
file = {invent.name};
file = file(:);
data = table(folder, file);

% Check if file names come from more than one day
for i = 1:size(file,1)
date{i} = file{i}(12:end-17);
end

if length(unique(date)) > 1
    unique(date)
    warndlg('Data seem to come from more than one day - Please check!')
end

clear invent file folder date

%% sort the data file by filename
data = sortrows(data,'file');

%% Import .mat result files
for i = 1:height(data)
    load(fullfile(data.folder{i}, data.file{i}))
    results(i, :) = RESULTS(1, :);  % In case a detailed run was performed, only max indent is imported
    clear RESULTS
end
clear RESULTS i

%% Attach results variable to table and name columns
length_results = size(results,2);
column_names = {'indent_depth' 'force' 'modulus' 'hertzfactor' 'contactpointindex' 'bestcontactpointrms' 'contactpointposition' 'indent_time' 'x' 'y'};
results = array2table(results);
results.Properties.VariableNames = column_names(1:length_results);
data = [data results];

clear  length_results column_names results

%% %%%% IMPORT FORCE SETPOINT FROM .TXT FILES
for i = 1:size(data,1)
    [~,headerinfo] = Readfile(data.folder(i), strcat(data.file{i}(1:end-4), '.txt'));
    headerinfo = headerinfo{1,1};
    
    spt_index = find(contains(headerinfo,'setpoint'));
    spt = headerinfo(spt_index);
    spt_index2 = strfind(spt,':');
    for j = 1:length(spt_index2)
        spt{j,1} = spt{j,1}(spt_index2{j,1} + 2:end);
    end
    spt = str2double(spt);
    spt(isnan(spt) == 1) = [];
    
    sens_index = find(contains(headerinfo, 'sensitivity'));
    sens = headerinfo(sens_index);
    sens = replace(sens, '# sensitivity: ', '');
    sens = str2double(sens);
    
    spr_index = find(contains(headerinfo, 'springConstant'));
    spr = headerinfo(spr_index);
    spr = replace(spr, '# springConstant: ', '');
    spr = str2double(spr);
    
    setpoint_V(i,1) = spt;
    sensitivity(i,1) = sens;
    springconstant(i,1) = spr;
    fclose('all');
    
    clear headerinfo spt spt_index spt_index2 sens sens_index spr spr_index
end

clear i j

%% Calculate setpoint in N from above values
setpoint_N(:,1) = setpoint_V(:,1).*sensitivity(:,1).*springconstant(:,1);

setpoint_N = table(setpoint_N);
setpoint_V = table(setpoint_V);
sensitivity = table(sensitivity);
springconstant = table(springconstant);
beadradius = NaN(size(data,1),1);
beadradius = table(beadradius);

data = [data setpoint_N setpoint_V sensitivity springconstant beadradius];

if (max(data.setpoint_N) - min(data.setpoint_N)) > 2*10^-9
    warndlg('The force setpoints across all measurements deviate by more than 2 nN. Please check if these measurements are really all from the same experiment!')
end

clear setpoint_N setpoint_V sensitivity springconstant beadradius

data.beadradius(:) = (3/4*data.hertzfactor(:)./data.modulus(:)).^2;
data.beadradius = round(data.beadradius,8);

%% Add columns for animal number, orientation, setpoint and speed
animal = NaN(height(data),1);
orient = cell(height(data),1);
setpoint = NaN(height(data),1);
speed = NaN(height(data),1);
amend = table(animal, orient, setpoint, speed);

data = [data amend];
clear animal orient setpoint speed amend
end


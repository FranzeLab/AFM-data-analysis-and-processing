
function convert2csv 
%% Converts .mat files to .csv

% Version 27/11/2018 Alex Winkel

%% Select the files to be converted
clear
[FileName,PathName,~] = uigetfile({'*.mat','Matlab Results Files'},'Select file','C:\Users\alex_\Documents\MATLAB\comparison 2\correct indentation\data\less than\','MultiSelect','on');

% this iscell check is required, because if only one file is chosen it is not
% put into a field, but FileName is required to be in a field later on.
q = iscell(FileName);
if (q == 0)
    FileName = {FileName};
end
%% iteration over all files
[~,e] =  size(FileName); %Filename is a field of 1 x <number of files>, so here w = 1 and e = number of files
for i = 1:e 
    filename = strcat(FileName(i));
    nameroot = erase(filename,'.mat');
    csvname = strcat(nameroot,'.csv');
    pathfilei = strcat(PathName,filename);
    pathfileo = strcat(PathName,csvname);
    FileData = load(pathfilei{1});
    csvwrite(pathfileo{1},FileData.RESULTS);
    fprintf('%s saved.\n',csvname{1});
end
if (e == 1)
    fprintf('%i File converted in folder:\n%s\n', e, PathName);
else
    fprintf('%i Files converted in folder:\n%s\n', e, PathName);
clear FileData
end

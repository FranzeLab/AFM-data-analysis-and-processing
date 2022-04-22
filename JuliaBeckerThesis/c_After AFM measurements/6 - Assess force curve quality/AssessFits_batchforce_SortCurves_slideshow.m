%% AssessFits_batchforce_SortCurves_slideshow.m     23/04/2021 Julia Becker
% This script allows the user to view and sort all fitted force curves
% after batchforce.m. The *.png files of one experimental folder which show
% the rawdata and the fitted curve are displayed one after another as a
% slideshow. The user can set the speed for this with the variable
% "interval". Unless a button is pressed, the curve quality is assumed to
% be good. Pressing any button halts the slide show and allows the user to
% class the curves as following with pressing the following buttons:
%
%   - 'SPACE'               good
%   - 'd'                   delete curve 
%   - 'b'                   bad fit
%   - 's'                   steep 
%   - left arrow key        go back to previous curve 
%   - right arrow key       good curve + resume slide show
%
% If a key other than the above is pressed, the user is notified and has to
% reenter. A short message is displayed after key press to inform the user
% of the action being taken. The duration this message being displayed can
% be altered with variable "interval2".
% Curves marked to be deleted are deleted at the end of the script, curves
% marked to be 'bad' or 'steep' are moved to a new respective subfolder in
% 'files and labfile'.
%
% CAVE! The script cannot be easily stopped and resumed while sorting data
% from one folder without restarting completely. Make sure you have
% sufficient time to sort an entire folder at once. Above the top left of
% the force curve, there is an indication how far through all the force
% curves in the experimental folder the user currently is.
%
% Required INPUT
%   - Experimental folder
%   - optional:     alter display speed for curves
%   - optional:     alter display time for key press message
%
% OUTPUT:
%   - "plots_checked.csv" in the experimental folder which contains the
%     user's quality assessment for each force curve

clear variables
close all

%% USER SETTINGS
interval = 0.33;        % Every how many seconds should a new image be displayed?
interval2 = 0.5;        % How long should the information message be displayed?

%% Let user choose which folder to read
PathName = uigetdir('');

%% Get all .txt files in 'files and labfile' in this folder
invent = dir(fullfile(PathName,'files and labfile','*.mat'));   % JB 31/10/19 - changed from *.txt to *.mat 

%% Make a table containing all .mat files similar to Ryan's output
folder = {invent.folder};
folder = folder(:);
file = {invent.name};
file = file(:);
data = table(folder, file);

%%   Sort the data file by filename
data = sortrows(data,'file');
data2 = data;

%%  Add a new column for quality check status, default value of this column be "not checked"
quality = {};
quality(1:size(data2,1),1) = {'not checked'};
quality = table(quality);
data2 = [data2 quality];

%% Start slide show
clear value
i = 1;

%  empty figure to start automated figure display
figure
set(gcf, 'Position', get(0, 'Screensize'));
uiwait(msgbox('Please press right arrow key to start.'))
waitforbuttonpress;
value = double(get(gcf,'CurrentCharacter'));

while i < (size(data2,1)+1)
    
    %%      open .png plot from subfolder to look at
    figure(gcf)
    image_fullname = fullfile(data2.folder{i}, strcat(data2.file{i}(1:end-4), '.png'));
    I = imread(image_fullname);
    image(I);
    axis on
    axis image
    set(gcf, 'Position', get(0, 'Screensize'));
    ant = annotation('textarrow',[0.5 0.5],[0.5 0.5],'string',strcat("Plot ", num2str(i),'/', num2str(size(data2,1))),'HeadStyle','none','LineStyle','none','Position',[0.27 0.96 0 0],'FontSize',18);
    
    pause(interval)
    value = double(get(gcf,'CurrentCharacter'));
    
    if value == 29
        data2.quality{i,1} = 'good';
        i = i+1;
        delete(ant)
    else
        figure(gcf)
        while 1
            waitforbuttonpress;
            value = double(get(gcf,'CurrentCharacter'));
            if      value == 32
                data2.quality{i,1} = 'good';
                inform = msgbox('Good fit');
                pause(interval2)
                delete(inform); clear inform
                i = i+1;
                delete(ant)
                break
            elseif  value == 100;
                data2.quality{i,1} = 'DELETE';
                inform = msgbox('DELETE curve');
                pause(interval2)
                delete(inform); clear inform
                i = i+1;
                delete(ant)
                break
            elseif  value == 98;
                data2.quality{i,1} = 'bad fit';
                inform = msgbox('Bad fit');
                pause(interval2)
                delete(inform); clear inform
                i = i+1;
                delete(ant)
                break
            elseif  value == 115;
                data2.quality{i,1} = 'steep';
                inform = msgbox('Steep');
                pause(interval2)
                delete(inform); clear inform
                i = i+1;
                delete(ant)
                break
            elseif  value == 28;
                i = i-1;
                delete(ant)
                break
            elseif  value == 29;
                data2.quality{i,1} = 'good';
                inform = msgbox('Good fit - resume slide show');
                pause(interval2)
                delete(inform); clear inform
                i = i+1;
                delete(ant)
                break
            else
                inform = msgbox('Invalid key - please repeat.');
                pause(interval2)
                delete(inform); clear inform
            end
        end
    end
end
clear ant value

%% Check if all files have been checked, otherwise display warning
index_remaining = find(strcmp(data2.quality, 'not checked'));
if size(index_remaining,1) ~= 0
   warndlg(strcat("There are ", num2str(size(index_remaining,1)), " fits which haven't been assessed yet. Please check this."),'Warning');
end

%% Identify all the "bad fit", "DELETE" and "steep" lines from the variable
index_delete = find(strcmp(data2.quality, 'bad fit'));
index_deletecompletely = find(strcmp(data2.quality, 'DELETE'));
index_steep = find(strcmp(data2.quality, 'steep'));

%% Save variable as output table
table_checked_fullname = fullfile(PathName, 'plots_checked.csv');
writetable(data2,table_checked_fullname,'WriteRowNames', true)

%%
msgbox(sprintf('Congratulations, once again you defeated those nasty force curves!\n\nNow give me a little time to reorder your files...'))

%% Make new directories to sort plot images according to status
if isempty(index_delete) == 0
PathName_bad = fullfile(PathName, 'files and labfile', 'BadFC');
[~, ~, ~] = mkdir(PathName_bad);
end

if isempty(index_steep) == 0
PathName_steep = fullfile(PathName, 'files and labfile', 'Steep');
[~, ~, ~] = mkdir(PathName_steep);
end

if isempty(index_remaining) == 0
PathName_steep = fullfile(PathName, 'files and labfile', 'NotChecked');
[~, ~, ~] = mkdir(PathName_steep);
end

%% Identify and move bad curves
for i = 1:size(index_delete,1)
    
    % Move .png file
    From = fullfile(data2.folder{index_delete(i,1),1}, strcat(data2.file{index_delete(i,1),1}(1:end-4), '.png'));
    To = fullfile(data2.folder{index_delete(i,1),1},'BadFC', strcat(data2.file{index_delete(i,1),1}(1:end-4), '.png'));
    movefile(From, To)
    
    % Move matching .mat file
    From = fullfile(data2.folder{index_delete(i,1),1}, strcat(data2.file{index_delete(i,1),1}(1:end-4), '.mat'));
    To = fullfile(data2.folder{index_delete(i,1),1},'BadFC', strcat(data2.file{index_delete(i,1),1}(1:end-4), '.mat'));
    movefile(From, To)
    
    % Copy matching .txt file
    From = fullfile(data2.folder{index_delete(i,1),1}, strcat(data2.file{index_delete(i,1),1}(1:end-4), '.txt'));
    To = fullfile(data2.folder{index_delete(i,1),1},'BadFC', strcat(data2.file{index_delete(i,1),1}(1:end-4), '.txt'));
    copyfile(From, To)
end

%% Identify and DELETE really bad curves
for i = 1:size(index_deletecompletely,1)
    
    % Delete .png file
    delete(fullfile(data2.folder{index_deletecompletely(i,1),1}, strcat(data2.file{index_deletecompletely(i,1),1}(1:end-4), '.png')))
    
    % Delete matching .mat file
    delete(fullfile(data2.folder{index_deletecompletely(i,1),1}, strcat(data2.file{index_deletecompletely(i,1),1}(1:end-4), '.mat')))

    % Delete matching .txt file
    delete(fullfile(data2.folder{index_deletecompletely(i,1),1}, strcat(data2.file{index_deletecompletely(i,1),1}(1:end-4), '.txt')))

end

%% Identify and move steep curves
for i = 1:size(index_steep,1)
    
    % Move .png file
    From = fullfile(data2.folder{index_steep(i,1),1}, strcat(data2.file{index_steep(i,1),1}(1:end-4), '.png'));
    To = fullfile(data2.folder{index_steep(i,1),1},'Steep', strcat(data2.file{index_steep(i,1),1}(1:end-4), '.png'));
    movefile(From, To)
    
    % Move matching .mat file
    From = fullfile(data2.folder{index_steep(i,1),1}, strcat(data2.file{index_steep(i,1),1}(1:end-4), '.mat'));
    To = fullfile(data2.folder{index_steep(i,1),1},'Steep', strcat(data2.file{index_steep(i,1),1}(1:end-4), '.mat'));
    movefile(From, To)
    
    % Copy matching .txt file
    From = fullfile(data2.folder{index_steep(i,1),1}, strcat(data2.file{index_steep(i,1),1}(1:end-4), '.txt'));
    To = fullfile(data2.folder{index_steep(i,1),1},'Steep', strcat(data2.file{index_steep(i,1),1}(1:end-4), '.txt'));
    copyfile(From, To)
end

%% Identify and move files with missing plots
for i = 1:size(index_remaining,1)
    
    % Move matching .mat file
    From = fullfile(data2.folder{index_remaining(i,1),1}, strcat(data2.file{index_remaining(i,1),1}(1:end-4), '.mat'));
    To = fullfile(data2.folder{index_remaining(i,1),1},'NotChecked', strcat(data2.file{index_remaining(i,1),1}(1:end-4), '.mat'));
    movefile(From, To)
    
    % Copy matching .txt file
    From = fullfile(data2.folder{index_remaining(i,1),1}, strcat(data2.file{index_remaining(i,1),1}(1:end-4), '.txt'));
    To = fullfile(data2.folder{index_remaining(i,1),1},'NotChecked', strcat(data2.file{index_remaining(i,1),1}(1:end-4), '.txt'));
    copyfile(From, To)
end


%%
msgbox('Excellent, your files are now all neatly rearranged - script successfully completed!')

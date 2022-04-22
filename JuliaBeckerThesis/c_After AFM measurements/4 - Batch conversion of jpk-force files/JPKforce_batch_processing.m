%% JPKforce_batch_processing.m                  14/08/2020 Julia Becker
% This script makes the conversion of .jpk-force files into .txt files more
% efficient if data in many different subfolders need to be converted. Move
% all experimental folders you want to convert into one folder. Use a
% search to find all "*.jpk-force" in all subfolders and copy (don't move!)
% those into the top folder. Convert all of those .jpk-force files into
% .txt files with the JPK software. Move all the .txt files into the same
% top folder which contains the .jpk-force files (from the subfolder
% automatically created by the JPK software).
% Now run this script - all .txt files will be moved into the subfolder
% that contains the original .jpk-force file. The copied .jpk-force
% files in the top folder will be deleted.

% Required INPUT:
%   - Folder which contains all copied .jpk-force files directly inside it
%     and all subfolders with the original .jpk-force files inside those

%% Get outer directory which contains all files
folder = uigetdir;

%% Make inventory
dir_folder = dir(fullfile(folder, '/**/*.jpk-force'));

%% Create lookup for target folder of .txt files
target = {dir_folder.folder}';
idx = find(strcmp(target, folder) == 1);

clear bli
target = {dir_folder.name; dir_folder.folder}';
target(idx,:) = [];
clear idx

target(:,1) = strrep(target(:,1),'jpk-force','txt');

%% Index .txt files in the outer folder
bli = dir(fullfile(folder, '/**/*.txt'));
source = {bli.name}';
[~, idx] = setdiff(target(:,1),source);
target(idx,:) = [];

%% Move .txt files and delete the matching .jpk-force file in the outer directory
lookup(:,1) = fullfile(folder, target(:,1));
lookup(:,2) = fullfile(target(:,2), target(:,1));
lookup(:,3) = strrep(lookup(:,1), '.txt', '.jpk-force');

for i = 1:size(lookup,1)
movefile(lookup{i,1}, lookup{i,2})
delete(lookup{i,3})
end






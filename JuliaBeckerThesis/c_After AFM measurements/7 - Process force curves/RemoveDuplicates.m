function [data2, length_dupl] = RemoveDuplicates(data)    % by Julia Becker, 01/04/2020     % JB 19/11/2021, debugged
%REMOVEDUPLICATES Handles curves from identical x/y position
% Finds repeat measurements and keeps highest force one

%% Do all of the below individually for each experimental folder
folder = unique(data.folder);
data2 = table;
duplicates2 = [];

for k = 1:size(folder,1)
    
    data1 = data(find(strcmp(data.folder, folder(k,1))),:);
    
    %% Find curves from identical positions
    % Combine x and y position to a "position identifier"
    for i = 1:size(data1,1)
        position{i,1} = strcat(num2str(data1.x(i),'%-10.8f'),'_', num2str(data1.y(i),'%-10.8f'));    % JB 19/11/2021 included format spec into num2str to make sure coordinates don't get truncated if 0s at the end
    end
    
    % Find all positions which occur in experiment
    C = unique(position, 'stable');
    
    % Find all positions where more than one curve exists. Make a variable
    % "duplicates" where each line contains all curves from such a position.
    j = 1;
    for i = 1:size(C)
        bli = find(strcmp(position,C(i))==1);           % JB 19/11/2021 changed from 'contains' to 'strcmp' (as contains will also find longer strings containing a substring
        bli = bli';
        if length(bli) > 1
            duplicates(j,1:length(bli)) = bli;
            j = j+1;
        end
    end
    
    if exist('duplicates') == 0
        duplicates = [];
        duplicates_force = [];
    end
    
    duplicates(duplicates == 0) = NaN;
    duplicates = fliplr(duplicates);    % Not utterly essential. Will cause later curve to be kept instead of earlier one if force is identical.
    
    clear C j i bli position
    
    %% Find and retain the curve with the highest setpoint (as most likely the best one)
    % Find the actual indentation force for all duplicate measurements
    for row = 1:size(duplicates, 1)
        for column = 1:size(duplicates, 2)
            if isnan(duplicates(row, column)) == 0
                duplicates_force(row, column) = data1.force(duplicates(row, column));
            end
        end
    end
    duplicates_force(duplicates_force == 0) = NaN;
    clear row column
    
    % Find the measurement with the highest force out of each set of duplicates
    [~,index] = max(duplicates_force, [], 2);
    
    % Delete the index of this curve from the variable "duplicates"
    for i = 1:size(duplicates,1)
        duplicates(i, index(i,1)) = NaN;
    end
    clear index i duplicates_force
    
    duplicates = duplicates(:);
    duplicates(isnan(duplicates)) = [];
    
    % What remains in "duplicates" are the indexes of the lines of data1 which
    % have to be removed. Now delete those lines from "data1".
    data1(duplicates(:),:) = [];
    
    data2 = [data2; data1];
    duplicates2 = [duplicates2; duplicates];
    clear data1 duplicates
    
end

length_dupl = size(duplicates2,1);

end


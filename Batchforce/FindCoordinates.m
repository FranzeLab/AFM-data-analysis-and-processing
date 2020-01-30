function [pos_x,pos_y] = FindCoordinates(source)
%FINDCOORDINATES Finds x and y position in headerinfo from .txt file
%   source needs to be "headerinfo"

% Find x position
index_x = strfind(source{1,1}, '# xPosition: ');
if isempty(index_x)
    error('"# xPosition: " in header not found')
end
index_x = find(not(cellfun('isempty', index_x)));

pos_x = strrep(source{1,1}(index_x,1), '# xPosition: ', '');
pos_x = str2num(pos_x{1,1});

% Find y position
index_y = strfind(source{1,1}, '# yPosition: ');
if isempty(index_y)
    error('"# yPosition: " in header not found')
end
index_y = find(not(cellfun('isempty', index_y)));

pos_y = strrep(source{1,1}(index_y,1), '# yPosition: ', '');
pos_y = str2num(pos_y{1,1});

end


function[column1_index, column2_index, number_of_columns] = FindColumnsNeeded(source, column1, column2)
% In the context of batchforce, use FindColumnsNeeded(headerinfo, 'vDeflection', 'measuredHeight')

% Find line in headerinfo which specifies the column names
indexc = strfind(source{1,1}, '# columns: ');
if isempty(indexc)
    error('"# columns: " in header not found')
end
index = find(not(cellfun('isempty', indexc)));

% Separate column names, find number of columns
column_names = source{1,1}{index,1}(12:end-1); % end -1 as otherwise one additional space there
column_names = strsplit(column_names);
number_of_columns = size(column_names,2);

% Find out which column is 'column1'
search_column1 = strfind(column_names, column1);
column1_index = find(not(cellfun('isempty', search_column1)));

% Find out which column is 'column2'
search_column2 = strfind(column_names, column2);
column2_index = find(not(cellfun('isempty', search_column2)));

if isempty(column1_index|column2_index)
    error('Required rawdata columns not found')
end

function [rawdata, header] = readforcecurve_3_4_15 (filename) 

%% OPEN THE FILE
forcefile=fopen(filename{1,1});

%% count the number of headerlines
headerline_index = 1;
headerline_counter = 0;
while headerline_index == 1
    headerindicator = textscan(forcefile, '%c%*[^\n]', 1);
    if strcmp(headerindicator, '#') == 1
        headerline_index = 1;
        headerline_counter = headerline_counter + 1;
    elseif strcmp(headerindicator, '#') == 0
        headerline_index = 0;     
    end
end
headerline_counter
%% read the header and the rawdata
fseek(forcefile,0,'bof');
header = textscan(forcefile, '%[^\n]',...
    headerline_counter);
[rubbish, column_row] = GetHeaderValue(header,'columns');
columns_row_size = size(column_row);
column_number = columns_row_size(1) - 2;
fseek(forcefile,1,0);
basestr = '%f';
data_convert = [];
for i = 1 : column_number
    data_convert = [data_convert basestr];
end
rawdata = textscan (forcefile, data_convert);
        
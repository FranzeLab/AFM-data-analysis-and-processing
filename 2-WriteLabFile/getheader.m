function [header, LL] = getheader (filename) 

%% OPEN THE FILE
LL = length(filename)
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
%% get header

%fseek(forcefile,0,'bof')
%header = textscan(forcefile, '%[^\n]',headerline_counter)




%header = cell(LL);
for i=1:LL
    filename{1,i};
    forcefile=fopen(filename{1,i});
    fseek(forcefile,0,'bof');
    header{i} = textscan(forcefile, '%[^\n]',headerline_counter);
    fclose(forcefile);
end;

function[headervalue,header_row] = GetHeaderValue(header,info_name)
%% extracts a particular value from the header

headersize = size(header{1});
info_check = strfind(header{1}, info_name);
has_entry_vector = [];
for counter = 1:headersize
    q = size(info_check{counter});
    has_entry = find(q(1));
    if has_entry > 0
        has_entry_vector = [has_entry_vector counter];
    end
end

if length(has_entry_vector) == 1
    entry = textscan(header{1}{has_entry_vector(1)}, '%s');
    header_row = entry{1};
    headervalue_string = entry{1}{end};
elseif length(has_entry_vector)<1
    error('headervalue not found: %s', info_name)
elseif length(has_entry_vector)>1
    error('too many headervalues: %s', info_name)
end

[headervalue,conversion_success] = str2num(headervalue_string);
if conversion_success == 0
    headervalue = headervalue_string;
end
    

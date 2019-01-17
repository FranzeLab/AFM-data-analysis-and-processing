function[rawdata] = CleanData(orgrawdata, column1_index, column2_index)

% clean rawdata from messy start/finish
firstdatapoint = max(orgrawdata{1,column2_index});
q = find(orgrawdata{:,column2_index} > firstdatapoint - 25E-9);
if (~isempty(q))
    w = q(end);
else
    w = 1;
end
[maxrawdata,maxrawdataindex] = max(orgrawdata{1,column1_index});
rawdata{1,3} = orgrawdata{1,column2_index}(w:maxrawdataindex);
rawdata{1,2} = orgrawdata{1,column1_index}(w:maxrawdataindex);
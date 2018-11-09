function[rawdata] = CleanData(orgrawdata)

% clean rawdata from messy start/finish
firstdatapoint = max(orgrawdata{1,3});
q = find(orgrawdata{:,3} > firstdatapoint - 25E-9);
if (~isempty(q))
    w = q(end);
else
    w = 1;
end
[maxrawdata,maxrawdataindex] = max(orgrawdata{1,2});
rawdata{1,3} = orgrawdata{1,3}(w:maxrawdataindex);
rawdata{1,2} = orgrawdata{1,2}(w:maxrawdataindex);
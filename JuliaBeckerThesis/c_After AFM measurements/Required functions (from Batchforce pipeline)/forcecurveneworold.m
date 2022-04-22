function [neworoldforcecurve] = forcecurveneworold (filename)
% checks, if the forcecurve is new or old
% forcecurveneworold checks, if the first item on in the file specified by
% filename is "index" (new files), or "xPosition" (old files).
forcecurve = fopen(filename);
firstline = fgetl(forcecurve);
k = strfind(firstline, 'index:');
l = strfind(firstline, 'xPosition:');
    if (isempty(k) && ~isempty(l))
        neworoldforcecurve = 0;
    elseif (~isempty(k) && isempty(l))
        neworoldforcecurve = 1;
    else 
        disp('it could not be determined what type of force curve is in this file')
    end
fclose('all');

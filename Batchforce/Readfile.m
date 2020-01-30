function [rawdata, headerinfo] = Readfile(PathName,FileName) 
%% reads a force file

% The next loop check for different Versions of Headers with different
    % settings. It does NOT contain all possibilities, and will also have
    % to be given alternatives after JPK updates etc.
    filename = fullfile(PathName, FileName);
    fileend = filename{1,1}(end-2:end);
    if (1 == strcmp('txt',fileend))
        [rawdata,headerinfo] = readforcecurve_3_4_15(filename);
    elseif (1 == strcmp('out',fileend))
        % old = 0
        % new = 1
        neworoldforcecurve = forcecurveneworold(filename);
        %% read in the forcecurve according to forcecurvetype
        if (neworoldforcecurve == 0)
            [rawdata,headerinfo] = readoldforcecurve(filename);
        elseif (neworoldforcecurve == 1)
            [rawdata,headerinfo] = readnewforcecurve(filename);
        else
            disp('force curve could not be read')
        end
    else
        disp('unknown file extension')
    end

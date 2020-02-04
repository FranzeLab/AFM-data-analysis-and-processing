
function batchforce(varargin)
%% batchforce analyzes a batch of force curves obtained with a colloidal
%% probe. The model used is the Hertz-model (assuming a paraboloid indenter
%% rather than a spherical one). The program requires the force curves to
%% be relatively well behaved, though they can be pretty bad around the
%% contact point and it requires all force curves to be obtained with a
%% probe of the same size (though it can be a different cantilever). Also
%% the cantilevers should be calibrated and only certain headers can be
%% read.

% Version 23/10/18 Julia Becker; amended to specify which columns of the
% rawdata file should be analysed, default is now 'vDeflection' and
% 'measuredHeight'. Previously it was columns 2 and 3 regardless of name.
% Version 06/12/2018 Julia Becker: Now logging every curve which was
% analysed. Please amend user name as needed. If it is not amended from the
% default, the user will be prompted.
% 
% Version 13/01/20 Julia Becker: Includes time which indentation took in
% column 8, x position in column 9 and y position in column 10 of RESULTS.
% This requires a modified CleanData_inclTime.m function and a
% FindCoordinates.m function.
% 
% AKW other recent changes include:
% Contact Point in m in column 7
% Stopping if K goes below 1 Pa
% The option of how to deal with indentations that are over R/3: either
% warn and continue (w), or crop the indentation at R/3 (c).
% The possibility to run batchforce from the command line with 6 
% (or optionally [] 7) command line arguments:
% batchforce [PathName] log_user beadradius weight_user_index crop specialSelect resolution
% eg batchforce Alex 18640 n w 1 0
% contactpointfit changed to use sse instead of rmse which is much better 
% for steep curves


%% Change accordingly, please!
log_user = 'YourNameHere';

%% AKW: use input args if present and correct
% originally expceted 6, now implementing possibility to call batchforce
% with an input folder, too, hence optionally a 7th
% note that this assumes specialSelect = 1; untested with other numbers
ExpectedArgs = 6;
PathName = 0;
   
if nargin == ExpectedArgs
    log_user = varargin{1};
    beadradius = str2num(varargin{2});
    weight_user_index = varargin{3};
    crop = varargin{4};
    specialSelect = str2num(varargin{5});
    resolution = str2num(varargin{6});
elseif nargin == ExpectedArgs+1
    PathName = varargin{1};
    log_user = varargin{2};
    beadradius = str2num(varargin{3});
    weight_user_index = varargin{4};
    crop = varargin{5};
    specialSelect = str2num(varargin{6});
    resolution = str2num(varargin{7});
    ExpectedArgs = ExpectedArgs+1;
else    
    fprintf('Unexpected number of arguments, prompting for inputs\n');
end    
    
    
    

%% Select the force curves to be analyzed - ORIGINAL CELL REPLACED
if PathName == 0
    PathName = uigetdir('D:\data','Select folder containing txt exports from JPK DP');
end

% Get all .txt files in this folder
invent = dir(fullfile(PathName,'*.txt'));

% Make a cell containing all filenames, not including those that don't look
% like afm data files
FileName = {invent.name};
relevant = strfind(FileName,'force-save-');
irrelevant = find(cellfun(@isempty,relevant));
FileName(irrelevant) = [];

    
%% get the necessary inputs
existsd = exist('d:\','dir');
if existsd == 0
    fprintf('WARNING: D: does not exist. Logfile cannot be written\n');
    m=input('Do you want to continue, Y/N [Y]:','s');
    if m=='N' | m=='n'
       return       
    end
else
    while strcmp('YourNameHere',log_user) == 1 | strcmp('',log_user) == 1
        log_user = input('Please enter username for logfile >','s');
    end
end

log_userinput = {};
if nargin ~= ExpectedArgs
    beadradius = input('Beadradius in nm >');
end
log_userinput{1,1} = num2str(beadradius);
beadradius = beadradius*1E-9;
if nargin ~= ExpectedArgs
    weight_user_index = input('Should data points at deeper indentations be given more weight[y/n]?\n>>>','s');
end
log_userinput{1,2} = weight_user_index;
if strcmp('y',weight_user_index) == 1
    weight_user_index = 1;
elseif strcmp('n',weight_user_index) == 1
    weight_user_index = 0;
else
    error('no valid input')
end
if nargin ~= ExpectedArgs
    specialSelect = input('Select type of analysis:\n(1)  Complete analysis with tabulated output\n(2)  Specific output for one Indentation\n(3)  Specific output for one Force\n(4)  Check fits\n(5)  Residuals\n>>>');
end
log_userinput{1,3} = num2str(specialSelect);

if specialSelect == 3
    forceInput = input('To which force in nN do you wish to analyze?>>');
    log_userinput{1,4} = num2str(forceInput);
    forceInput = forceInput*1E-9;
    indentationInput = 0;
    assumedCP = input('Which contactpoint(index) do you assume? (0 for none)>>');
    log_userinput{1,5} = num2str(assumedCP);
    if assumedCP == 0
        detailedRun = 0;
    else detailedRun = 1;
    end
elseif specialSelect == 2
    indentationInput = input('To which indentation in microns do you want to analyze?>>');
    log_userinput{1,4} = num2str(indentationInput);
    indentationInput = indentationInput*1E-6;
    forceInput = 0;
    assumedCP = input('Which contactpoint(index) do you assume? (0 for none)>>');
    log_userinput{1,5} = num2str(assumedCP);
    if assumedCP == 0
        detailedRun = 0;
    else detailedRun = 1;
    end
elseif specialSelect == 1
    if nargin ~= ExpectedArgs
        crop = input('How should batchforce handle indentations that are greater then R/3? \nTo warn and continue enter w\nTo crop and re-fit enter c\n>>>','s');
    end
    log_userinput{1,4} = crop;
    if strcmp('w',crop) == 1
        crop_logical = 0;
    elseif strcmp('c',crop) == 1
        crop_logical = 1;
    else
        error('no valid input')
    end
    if nargin ~= ExpectedArgs
        resolution = input('Every how many data points should a fit be performed?\nWARNING: A too small value may make the calculation take forever.\nFor a 1000 data point force curves 7 may be reasonable.\nBecause of certain parts of the algorithm the number should be below 20.\nTo do only one fit over the whole data set, choose 0.\n>>>');
    end
    log_userinput{1,5} = num2str(resolution);
    forceInput = 0;
    indentationInput = 0.01*beadradius; %Changed original 0.03 to 0.01
    assumedCP = 0;
    detailedRun = 0;
elseif specialSelect == 4
    [analyzed_file_name, analyzed_path_name, analyzed_filter_index] = ...
        uigetfile({'*.mat','analyzed curves'},...
        'Select curve','C:\ac563\work\measurementdata\test\',...
        'MultiSelect','on');
    q = iscell(analyzed_file_name);
    if (q == 0)
        analyzed_file_name = {analyzed_file_name};
    end
    indentationInput = 0;
    forceInput = 0;
    assumedCP = 0;
    detailedRun = 0;
    intervals = input('For which indentations do you want to see fits?\nType ''[indentation1 indentation2 ...]'' in microns\n>>>');
    log_userinput{1,4} = num2str(intervals);
    intervals = intervals * 1E-6;
    maxDist = input('What is the maximum error in indentations (in microns)\n>>>');
    log_userinput{1,5} = num2str(maxDist);
    maxDist = maxDist * 1E-6;
elseif specialSelect == 5
    [analyzed_file_name, analyzed_path_name, analyzed_filter_index] = ...
        uigetfile({'*.mat','analyzed curves'},...
        'Select curve','C:\ac563\work\measurementdata\test\',...
        'MultiSelect','on');
    q = iscell(analyzed_file_name);
    if (q == 0)
        analyzed_file_name = {analyzed_file_name};
    end
    indentationInput = 0;
    forceInput = 0;
    assumedCP = 0;
    detailedRun = 0;
    intervals = input('For which indentations do you want to see residuals?\nType ''[indentation1 indentation2 ...]'' in microns\n>>>');
    log_userinput{1,4} = num2str(intervals);
    intervals = intervals * 1E-6;
    maxDist = input('What is the maximum error in indentations (in microns)\n>>>');
    log_userinput{1,5} = num2str(maxDist);
    maxDist = maxDist * 1E-6;
else
    fprintf('invalid input')
end
deletePoints = 0;

space = ' ';
userInput{1} = {['beadradius' space num2str(beadradius)];...
    ['specialSelect' space num2str(specialSelect)];...
    ['forceInput' space num2str(forceInput)];...
    ['indentationInput' space num2str(indentationInput)];...
    ['assumedCP' space num2str(assumedCP)];...
    ['detailedRun' space num2str(detailedRun)];...
    ['weight_user_index' space num2str(weight_user_index)]};

%% iteration over all files
[w,e] =  size(FileName);
filnum = 1;
for i = 1:e
    
    %% AMENDMENTS JULIA 13/01/20 START
    %% Read the force curve data and cut of 'bad' start and end
    fprintf('\n %s (%d of %d)', FileName{1,i},filnum, e);
    filnum = filnum +1;
    [rawdata,headerinfo] = Readfile(PathName,FileName(i));
    rawdata;
    [vDefl, mHeight, number_rawdata_columns] = FindColumnsNeeded(headerinfo, 'vDeflection', 'measuredHeight'); % variables 'vDefl' and 'mHeight' used only in this cell, please change names according to rawdata columns you're looking for
    [time, ~, ~] = FindColumnsNeeded(headerinfo, 'seriesTime', 'measuredHeight'); % JB 13/01/20 line added to include time
    rawdata{vDefl} = smooth(rawdata{vDefl},10); % inserted by David 14/03/13, altered by Julia 23/10/18 to accommodate new variable
    rawdata = CleanData(rawdata, vDefl, mHeight, time); % JB 13/01/20 line amended to include time
    
    % log value of variables vDefl and mHeight
    name = fullfile(PathName,'Log_vDefl_mHeight_values.txt');
    variables = strjoin({'vDefl', num2str(vDefl), 'mHeight', num2str(mHeight), 'seriesTime', num2str(time)},'\t'); % JB 13/01/20 line amended to include time
    %% AMENDMENTS JULIA 13/01/20 END
    
    fid = fopen(name, 'at');
    fprintf(fid, '%38s\t%s\n', FileName{1,i}, variables);
    fclose(fid);
    clear vDefl mHeight name variables fid
    
    
    %% this loop following finds the index of the point with minCP_value
    minCP_value = min([(max(rawdata{1,3}) - 2E-6) (min(rawdata{1,3}) + 2*beadradius)]); % the multiplication of bead radius by factor 2 changed David 14/03/13 
    minCP_index = 1;
    length(rawdata{1,3});
    rawdata{1,3}(minCP_index);
    minCP_value;
    if rawdata{1,3}(minCP_index) > minCP_value
        while (rawdata{1,3}(minCP_index) > minCP_value) && (minCP_index+1<length(rawdata{1,3})) % Included "&& (minCP_index+1>length(rawdata{1,3})" as ran into error if minCP_value was outside lookup range, Max and Julia 25/01/18 % corrected this to <, Julia 03/12/18
            minCP_index = minCP_index+1;
        end
    end
    
    %% actual calculation of force curve fit for one particular curve
    local_indentation = 15000E-9;
    local_CP_index = minCP_index + 1;
    if specialSelect == 1
        steps = round(length(rawdata{1,3})/resolution,0);
        progress = 0;
        fprintf(' - ');
     %   fprintf(num2str(progress,'%05.2f'));
     %   fprintf('%%');
        w=1;
        mod = 2;
        try
            while (minCP_index < local_CP_index) && w > 0 && mod > 1
                results = forcecurveanalysis(rawdata,headerinfo,userInput,minCP_index,w,local_CP_index);
                local_indentation = GetHeaderValue(results,'indentation');
                mod = GetHeaderValue(results,'modulus');
                if (local_indentation < indentationInput)
                    fprintf('local indentation is less than indentation input');
                    break
                end
                % next bit inserted by akw48 to try to crop the data
                % if the indentation was more than 1/3 bead radius. In 
                % order to prevent the fit looping until no data is left, 
                % the CP is maintained at the value established for the
                % full data set. Although when resolution is nonzero, CP
                % will be re-analysed after each removal of 'resolution' data points 
                RESULTS(w,6) = GetHeaderValue(results,'bestcontactpointrms');
                if local_indentation > beadradius/3 && crop_logical == 0 && w == 1
                    fprintf('\nWarning: The indentation was more than is permitted by the Hertz model.\nApprox Progress:       ');
                end
                if local_indentation > beadradius/3 && crop_logical == 1
                    fprintf('\nThe indentation was more than is permitted: data cropped.\nApprox Progress:       ');
                    local_CP_index = GetHeaderValue(results,'contactpointindex');
                    contactpoint_now = rawdata{1,3}(local_CP_index);
                    [new_end,~]= find(rawdata{1,3} < (contactpoint_now-beadradius/3),1) ; 
                    rawdata = {rawdata{1,1}(1:end) rawdata{1,2}(1:new_end) rawdata{1,3}(1:new_end)};
                    results = forcecurveanalysis(rawdata,headerinfo,userInput,minCP_index,0,local_CP_index);
                    local_indentation = GetHeaderValue(results,'indentation');
                    local_CP_index = GetHeaderValue(results,'contactpointindex');
                    crop_logical = 0;
                end
                
                local_force = GetHeaderValue(results,'force');
                local_CP_index = GetHeaderValue(results,'contactpointindex');
                RESULTS(w,1) = GetHeaderValue(results,'indentation');
                RESULTS(w,2) = GetHeaderValue(results,'force');
                RESULTS(w,3) = GetHeaderValue(results,'modulus');
                RESULTS(w,4) = GetHeaderValue(results,'hertzfactor');
                RESULTS(w,5) = GetHeaderValue(results,'contactpointindex');
                
                %RESULTS(w,6) is taken above in case the fit is re-run after R/3
                RESULTS(w,7) = rawdata{1,3}(local_CP_index); %AKW: record CP in meters
                            %% INSERT JULIA 13/01/20 START
                % Find time interval for indentation part
                time2 = rawdata{1,1}(end,1);
                time1 = rawdata{1,1}(RESULTS(w,5)-1,1);
                time_interval = time2 - time1;

                % Include indentation time in column 8
                RESULTS(w,8) = time_interval;

                % Include x position in column 9, y position in column 10
                [pos_x, pos_y] = FindCoordinates(headerinfo);
                RESULTS(w,9) = pos_x;
                RESULTS(w,10) = pos_y;

                rawdata = {rawdata{1,1}(1:end-resolution) rawdata{1,2}(1:end-resolution) rawdata{1,3}(1:end-resolution)};
                if w == 1
                    local_CP_index;
                    steps = round((length(rawdata{1,3})-local_CP_index)/resolution,0);
                    local_CP_index;
                end
                progress= round(100*w/steps,2);
                if resolution > 0
                    w=w+1;
                else
                    w = 0;
                end
                if w > 2
                    fprintf('\b\b\b\b\b\b\b');
                end
                fprintf(num2str(progress,'%06.2f'));
                fprintf('%%');
            end
            fprintf('\b\b\b\b\b\b\b');
            fprintf('Done');
            filename = fullfile(PathName,[FileName{i}(1:end-4) '.mat']);

         if 1 == exist('RESULTS', 'var')
                save(filename, 'RESULTS', '-mat')
            end
            clear('RESULTS', 'rawdata');
            if strcmp('w',crop) == 1
                crop_logical = 0;
            elseif strcmp('c',crop) == 1
                crop_logical = 1;
            end

        catch err %err is an MException struct
            fprintf('FAILED - SKIPPED!');
            fprintf(1,'\n%s\n',err.message);
        end
    elseif specialSelect == 4 || 5
            %% find the corresponding .mat file from the analysis
        analyzed_file_index = strmatch(FileName{i}(1:end-4), analyzed_file_name);
        if isempty(analyzed_file_index)
            print(FileName{i})
        end
        %% get the cp from .mat file
        analyzed_file = [analyzed_path_name analyzed_file_name{analyzed_file_index}];
        load(analyzed_file);
        %% select the values for the fitting
        result_size = size(RESULTS);
        binned_data = [];
        for interval_number = 1:length(intervals)
            dataPointIndex = find(RESULTS(:,1) <= intervals(interval_number) + maxDist,1);
            if ~isempty(dataPointIndex)
                %NEXT 4 LINES UPDATED BY MAX ON 19/1/2015
                tmp=abs(RESULTS(:,1)-intervals(interval_number));
                [dist,dataPointIndex]=min(tmp);
                if (dist < maxDist)
                    binned_data = [binned_data; RESULTS(dataPointIndex,:) intervals(interval_number)];
                end
                %UPDATE OVER
            end
        end
        %% fit approach data to the contactpoint of furthest indentation
        contactpointindex = RESULTS(1,5);
        numberofdatapoints = length(rawdata{:,2});
        approachdata = [rawdata{1,3}(1:contactpointindex) rawdata{1,2}(1:contactpointindex)];
        [approachfit] = fitapproach (approachdata);
        approachfitcoefficients = coeffvalues(approachfit);
        newapproachdata = [approachdata(:,1)-rawdata{1,3}(contactpointindex),approachdata(:,2)-approachfitcoefficients(1,1)*approachdata(:,1)-approachfitcoefficients(1,2)];
        %% recalculate indentationdata
        springConstant = GetHeaderValue(headerinfo,'springConstant');
        forcecurvedata = [rawdata{1,3}(contactpointindex:numberofdatapoints,1) rawdata{1,2}(contactpointindex:numberofdatapoints,1)];
        forcecurvedata = [(forcecurvedata(:,1)-rawdata{1,3}(contactpointindex)),forcecurvedata(:,2)-approachfitcoefficients(1,1)*forcecurvedata(:,1)-approachfitcoefficients(1,2)];
        indentationdata = [forcecurvedata(:,1) + forcecurvedata(:,2)/springConstant, forcecurvedata(:,2)];
        indentationdata(:,1) = (-1)*indentationdata(:,1);
        
        %% make additional indentationdata from fit data
        if not(isempty(binned_data))
            for q = 1:length(binned_data(:,1))
                distance_to_cp = rawdata{1,3}(contactpointindex)-rawdata{1,3}(binned_data(q,5));
                first_positive = find(indentationdata(:,1)-distance_to_cp>0 , 1);
                indentationdata(first_positive:end,2*q+2) = binned_data(q,4)*((indentationdata(first_positive:end,1)-distance_to_cp).^(3/2));
                indentationdata(1:first_positive,2*q+2) = indentationdata(1:first_positive,2*q+2)*0;
                indentationdata(:,2*q+3) = indentationdata(:,1);
                indentationdata(1:first_positive,2*q+3) = ones(first_positive,1)* distance_to_cp;
            end
            if specialSelect == 5
                newapproachdata = [0 0]
                for q = 1:length(binned_data(:,1))
                    indentationdata(:,2*q+2) = indentationdata(:,2)-indentationdata(:,2*q+2)
                end
                indentationdata(:,2) = 0
            end
        end
        %% draw the graph
        if specialSelect == 4
            datax = [(-1)*newapproachdata(:,1); indentationdata(:,1)];
            datay = [newapproachdata(:,2); indentationdata(:,2)];
            figure1 = plot(datax,datay,'.k');
            hold all
            legend_string = [num2str(0) '  ' num2str(0)];
            if not(isempty(binned_data))
                for q = 1:length(binned_data(:,1))
                    plot(indentationdata(:,2*q+3), indentationdata(:,2*q+2));
                    legend_string_try = [num2str(binned_data(q,7)) '  ' num2str(binned_data(q,3))];
                    legend_string = strvcat(legend_string, legend_string_try);
                end
            end
            legend(legend_string);
            legend('Location', 'NorthWest');
            legend('show');
            axis auto
            hold off
        elseif specialSelect == 5
            datax = [(-1)*newapproachdata(:,1); indentationdata(:,1)];
            datay = [newapproachdata(:,2); indentationdata(:,2)];
            figure1 = plot(datax,datay,'-k');
            hold all
            legend_string = [num2str(0) '  ' num2str(0)];
            if not(isempty(binned_data))
                for q = 1:length(binned_data(:,1))
                    plot(indentationdata(:,2*q+3), indentationdata(:,2*q+2), '.');
                    legend_string_try = [num2str(binned_data(q,7)) '  ' num2str(binned_data(q,3))];
                    legend_string = strvcat(legend_string, legend_string_try);
                end
            end
            legend(legend_string);
            legend('Location', 'NorthWest');
            legend('show');
            axis([0 7E-6 -0.2E-8 0.2E-8])
            hold off
        end

        %% save the plot
        filename = [PathName FileName{i}];
        r = length(filename);
        timestampstart = r-11;
        timestampend = r-4;
        timestamp = filename(timestampstart:timestampend);
        newtimestamp = [timestamp(1:2) ':' timestamp(4:5) ':' timestamp(7:8)];
        imagename = filename(1:end-4);
        if specialSelect == 4
            imagename = [imagename '.png'];
        elseif specialSelect == 5
            imagename = [imagename 'residual.png'];
        end
        print('-dpng ','-r300',imagename);
    end
    fclose all;
    
    %% Write information about current run of batchforce to central log file
    % Retrieve system time and reformat to 'YYYY.MM.DD - hh.mm.ss'
    timestamp = clock;
    formatSpec = '%4d.%02d.%02d - %02d.%02d.%02d';
    timestamp = sprintf(formatSpec,timestamp(1,1),timestamp(1,2),timestamp(1,3),timestamp(1,4),timestamp(1,5),round(timestamp(1,6)));
    
    % Determining which batchforce script is currently used and when it was last modified
    log_batchforceversion = dir([mfilename('fullpath'),'.m']);
    log_batchforceversion1 = [log_batchforceversion.folder,' ',log_batchforceversion.name,' ',log_batchforceversion.date];

    % User name will be included - specified at very start of script for practicality
    
    % Combine path and name of file which has just been analysed
    fileforlog = fullfile(PathName, FileName(1,i)); 
    
    % Write new line in log file:
    % Time file was analysed - batchforce: path, name, last modified - user name - curve which was analysed - user inputs in order and format given by user
    if existsd == 7
       fileID = fopen('D:\batchforce_log - DO NOT MOVE.csv','a');   % DO NOT CHANGE THIS UNLESS LOG FILE IS MOVED TO A DIFFERENT LOCATION!
       formatSpec = '%s\t%s\t%s\t%s';
       fprintf(fileID,formatSpec,timestamp,log_batchforceversion1, log_user,fileforlog{1,1});
       for log_counter = 1:size(log_userinput,2)-1
          formatSpec = '\t%s';
          fprintf(fileID,formatSpec,log_userinput{1,log_counter});
       end
       log_counter = size(log_userinput,2);
       formatSpec = '\t%s\n';
       fprintf(fileID,formatSpec,log_userinput{1,log_counter});
       fclose(fileID);
    end
    %% fit curve with the contact point from analysis
    
        %% draw the graph
end
    
    
    %% create graphs
    
    %% IF LOOP: IF RESULTS ONLY ONE LINE, DO GRAPH FOR THOSE VALUES AND
    %% PRINT OUT ONLY THAT LINE. IF MORE THAN ONE LINE, GRAPH FOR FIRST
    %% LINE, FOR LAST LINE AND TEXTFILE OUTPUT OF TABLE
    
    % [figure1] = creategraph (rawdata,headerinfo,userInput,Results);
    %% save the data
    %{
    if specialSelect == 1
        filename = [PathName FileName{i}(1:end-4) '.mat'];
        save(filename, 'RESULTS', '-mat')
        clear('RESULTS', 'rawdata');
    end
    %}
    %Timestampvector(i) = timestamp;
    %Resultsmatrix(i,:) = Results;
    %Forcestring = num2str(MaxForceVector(counter))
    %Analysisfilename = [PathName 'Analysis-' Forcestring 'nN.txt'];
    %fid = fopen(Analysisfilename,'at');
    %s = fprintf(fid,'%8s\t',newtimestamp);
    %s = fprintf(fid,'%10e\t %10e\t %10e\t %10e\t %10e\t %10e\t %10e\t %10e\t %10e\n',Results);
    %status = fclose(fid);
    %imagename = filename(1:end-4);
    %imagename = [imagename '-' Forcestring 'nN.png'];
    %print('-dpng ','-r300',imagename);
    %disp(i)
    %disp(MaxForceVector(counter))
    %disp(timestamp)
fprintf('\nFinished.\n')
end
%path = input(path)
%beadsize = input(beadsize)

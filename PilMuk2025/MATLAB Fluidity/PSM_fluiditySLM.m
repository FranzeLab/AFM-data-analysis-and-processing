function PSM_fluiditySLM(varargin)
%% PSM_fluiditySLM.m
%% Written to accomodate files with multiple creep sections
%% 
%% Syntax: PSM_fluiditySLM [chosen_creep] [bead_radius_um]
%% steps:
%% open files
%% transfer segments into tables/matrices
%% ask user which segments should be analyised (if more than one pause segment)
%% 


[FileName,PathName,~] = uigetfile({'*.txt','JPK TXT export file'},'Select file(s)','D:\Users\alex_\OneDrive - University of Cambridge\AFM data\sudi\2024_09_20\matlab fluidity\SLM\all simple_1\curves','MultiSelect','on');

% this iscell check is required, because if only one file is chosen it is not
% put into a field, but FileName is required to be in a field later on.
q = iscell(FileName);
if (q == 0)
    FileName = {FileName};
end
%% iteration over all files
[~,e] =  size(FileName); %Filename is a field of 1 x <number of files>, so here w = 1 and e = number of files
if nargin > 0
     chosen_creep = str2num(varargin{1});
else
     chosen_creep = input('Which pause segment would like to analyse?\n e.g. 1 for the first\n>   ');
end
if nargin > 1
     r_um = str2num(varargin{2});
else
     r_um = input('What is the radius of the bead in μm\n>   ');
end
fprintf('Chosen pause segment = %i\n', chosen_creep);
if r_um < 1e-3
    fprintf('Error the chosen bead radius (%.3E μm) seems unbelievably small. Please check and try again.\n',r_um);
    return
end
fprintf('bead radius is %.3f μm\n', r_um);
for p = 1:e 
% organise and read file
    filename = strcat(FileName(p));
    pathfilei = strcat(PathName,filename);    
    outpath = strcat(PathName,"matlab fluidity");
    if ~exist(outpath,"dir") %~= 7
        mkdir(outpath);
    end
    outfile = fullfile(outpath,'fluidity.csv');
    FileData = fileread(pathfilei{1});

%determine where segments start     
    k = strfind(FileData,'# index: ');
%read segments into cell called segment    
    segment = cell(length(k),1);
    for j = 1:length(k)-1
        segment{j} = FileData(k(j):k(j+1)-1);
    end
    segment{length(k)} = FileData(k(end):end);
 %split segments up into lines for pattern matching and remove text lines relating ot removed segments 
        searchterm = 'segment: pause';
        l = strfind(segment,searchterm);
        q = find(~cellfun(@isempty,l));
        
        fprintf('\n%s: script has found %i pause segment(s)\n', filename{1},length(q));
        if chosen_creep > length(q)
            disp('Error: chosen pause segment does not exist')
            return
        end
        %% Convert chosen creep data (and preceeding segment) into table of values
        creep = textscan(segment{q(chosen_creep)},'%f %f %f %f %f %f %f','Delimiter',' ','CommentStyle','#');
        creep = cell2mat(creep);
        creep = array2table(creep);
        % remove columns that are mostly NaNs
        for i = 1:width(creep)
            if sum(isnan(creep.(i)))>height(creep.(i))/2
                creep.(i) = []
            end
        end
  %% Find data types and set as column headings
        colsc = extractBetween(segment(q(chosen_creep)),'# fancyNames: ', '# heightMultiplier:');
        colsc = colsc{1}(1:end-2);
        colsc = strsplit(colsc,'" "');
        colsc = erase(colsc,'"');
        creep.Properties.VariableNames = colsc;

        %% crop creep down to 3 seconds
        if max(creep.("Segment Time")) > 3
            creep = creep((creep.("Segment Time")<=3),:);
            fprintf("Pause/creep segment was longer than 3 seconds: removed data after 3 seconds.\n");
        end
%% start to compile the data for fitting, start with the four relevant colums from creep
        creeptemp = creep;
        creeptemp.Height=[];
        creeptemp.("Height (measured)")=[];
        creeptemp.("Segment Time")=[];

        %% make a table of the associated approach data
        approach = textscan(segment{q(chosen_creep)-1},'%f %f %f %f %f %f %f %f %f %f','Delimiter',' ','CommentStyle','#');
        approach = cell2mat(approach);
        approach = array2table(approach);
        colsa = extractBetween(segment(q(chosen_creep)-1),'# fancyNames: ', '# heightMultiplier:');
        colsa = colsa{1}(1:end-2);
        colsa = strsplit(colsa,'" "');
        colsa = erase(colsa,'"');
        % remove columns that are mostly NaNs
        for i = 1:width(approach)
            if sum(isnan(approach.(i)))>height(approach.(i))/2
                approach.(i) = []
            end
        end

        approach.Properties.VariableNames = colsa;
 %% Continue assembling data for analysis (4 the same four columns as from creep  
        approachtemp = approach;
        approachtemp.Height=[];
        approachtemp.("CellHesion Height")=[];
        approachtemp.("Head Height (measured)")=[];
        approachtemp.("Head Height (measured & smoothed)")=[];
        approachtemp.("Height (measured)")=[];
        approachtemp.("Segment Time")=[];
        %% combine approach and creep data
        data2fit = [approachtemp ; creeptemp];
        %% REMINDER need vertical tip position, which JPKDP can easily export (hence the code now looks 
        %% for 7 creep cols and 10 approach)
        %% should probably also baseline correct (twice separately for the complex curves)
        %% also used hertz fit and "shift curves" so that contact point is at 0
        %% next we need to invert Vertical Tip Position (new col in table) and set to um
        data2fit.("Inverted VTP") = data2fit.("Vertical Tip Position")*(-1e6); 
        creep.("Inverted VTP") = creep.("Vertical Tip Position")*(-1e6);
%% create variables to send to send to polynomial_step_model.m 
        data_obj.extend_idx = height(data2fit) - height(creep);
        data_obj.fdt(2, :) = data2fit.("Inverted VTP"); % in m
%% reset deflection data so that it starts at 0nN 
        data2fit.("Vertical Deflection") = data2fit.("Vertical Deflection")*1e9-data2fit.("Vertical Deflection")(1)*1e9; %convert F to nN to help fitting
        data_obj.fdt(1, :) = data2fit.("Vertical Deflection"); % in nN
        data_obj.fdt(3, :) = data2fit.("Series Time") ;
        PSF = polynomial_step_model(data_obj);
        f = figure;
        f.WindowState = 'maximized';
        ax1 = subplot(1,2,1);
        plot(data_obj.fdt(3,1:end), data_obj.fdt(1,1:end), 'b.-'); hold on
        plot(data_obj.fdt(3,1:end), PSF.best_fit, 'r-', 'LineWidth', 2);
        xlabel('Time [s]');
        ylabel('Force [nN]');
        legend('Data','Polynomial Step Fit');
        title('Polynomial Step Model Fit');
%% 09/04/2025 the above gives good PSM fits for simple creep curves (key was to put force in nN)
        %% next remove lines in table where VTP is negative (similar to Ryan's step model)
        data2fit = data2fit((data2fit.("Series Time")>=(PSF.params(2)+PSF.params(3))),:);
        X = data2fit.("Series Time");
        Y = data2fit.("Inverted VTP");
        clear data2fit
        tbl = table(X(:), Y(:));
        fc = PSF.params(1);
        tc = PSF.params(2);
        dta = PSF.params(3);
        a = PSF.params(3);
        SLMfit = SLM_model(data_obj, tc, a, dta, r_um, fc);
        C0 =  SLMfit.params(1);
        C1 = SLMfit.params(2);
        C2 = SLMfit.params(3);
        kl_kPa = 1/C1;
        ka_kPa = 1/C0 - 1/C1;
        eta_kPa_s = kl_kPa*ka_kPa/(C2*(kl_kPa+ka_kPa));
        kl = kl_kPa*1000;
        ka = ka_kPa*1000;
        eta = eta_kPa_s*1000;
        disp('Viscosity [Pa.s]:');
        disp(eta);
% much of the below is repeated from SLM_model.m for ease of plotting
        f = data_obj.fdt(1, :);  % force or signal
        d = data_obj.fdt(2, :);  % displacement or other
        t = data_obj.fdt(3, :);  % time        
        clear data_obj
                % Get values above the contact time
        idx = t > tc;
        f = f(idx);
        d = d(idx);
        tr = t(idx) - tc; %used later in plot
        t = t(idx) - tc;

        % Reset the indentation
        dr = d - min(d);  %used later in plot
        d = d - min(d);

        % Remove values where time exceeds dta
        idx = t > dta;
        d = d(idx);
        t = t(idx);

        ax2 = subplot(1,2,2);
        plot(tr, dr, 'b.-'); hold on
        plot(t, SLMfit.best_fit, 'r-', 'LineWidth', 2);
        xlabel('Time [s]');
        ylabel('Indentation [μm]');
        legend('Data','SLM Fit');
        title('Standard Linear Model Fit');
        savefig(fullfile(outpath,strcat(filename{1}(1:end-4),'_pause',string(chosen_creep),'.fig')));
        saveas(gcf, fullfile(outpath, strcat(filename{1}(1:end-4),'_pause',string(chosen_creep), '.png')), 'png') ;
        %add entry to eta table
        eta_tab{p,1} = filename{1};
        eta_tab{p,2} = kl;
        eta_tab{p,3} = ka;
        eta_tab{p,4} = eta;
        close gcf

    

end
T = cell2table(eta_tab,"VariableNames",["Filename" "kl [Pa]" "ka [Pa]" "eta [Pa.s]"]);
writetable(T,fullfile(outpath,strcat('eta_pause',string(chosen_creep),'.csv')))
fprintf('\nResults written to folder:\n%s\n', outpath);
clear FileData


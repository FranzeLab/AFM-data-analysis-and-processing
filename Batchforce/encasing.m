%% encasing.m
% Written by Julia Becker January 2020. Minor edits Alex Winkel
% Instructions: copy this file from the GIT folder to somewhere else (e.g.
% a folder in the Matlab path), then edit the varibles ui2 to ui7. Run the 
% script and choose an over-arching folder - it will search for subfolders 
% called 'files and labfiles' and open a matlab instance for each running 
% batchforce in each instance. Consider the speed of your computer before 
% running.

clear variables
close all

%% Let user choose which folder to read
uiwait(msgbox(sprintf("Select the overarching folder you want to analyse.\n\n All 'files and labfile' folders inside this folder will be searched for force-save-***.txt files for analysis.")))
PathName_big = uigetdir('/Users/julia/OneDrive - University Of Cambridge/Julia/Dokumente/Studium/Cambridge/PhD/PhD/PhD Franze lab/Data and results/AFM/WT measurements/', 'Select the overarching section folder (#XX_XX)');
bli = dir(fullfile(PathName_big, '**', 'files and labfile/'));
bla = {bli.folder};
PathName = unique(bla);
PathName = PathName(:);

clear bli bla
%%
setenv('PATH', [getenv('PATH') ':/Applications/MATLAB_R2018b.app/bin/']);

ui2 = input('Please enter username for logfile > ','s');
ui3 = input('Beadradius in nm > ','s');
ui4 = 'n';
ui5 = 'w';
ui6 = '1';
ui7 = '0';
% ui1 = PathName, ui2 = log_user, ui3 = beadradius, ui4 = weight_user_index, ui5 = crop or warn if indentation exceeds 1/3 bead radius, ui6 = specialSelect, ui7 = resolution 

inst_aim = input('How many batchforce instances do you want to run in parallel? Consider the capabilities of your machine! > ');
OS = computer;

%%
format shortg

for i = 1:size(PathName,1)
    ui1 = PathName{i,1};
        
    while 1
        clear result mlb inst_curr
        
        if strcmp(OS, 'PCWIN64') == 1       % Windows
            [~, result] = dos('tasklist');
        elseif strcmp(OS, 'GLNXA64') == 1   % Linux
            [~, result] = system('ps -A');
        elseif strcmp(OS, 'MACI64') == 1    % Mac
            [~, result] = system('ps axc');
        else 'Why on earth you running neither Windows nor Mac nor Linux?!'
        end
        
        mlb = strfind(result, 'MATLAB');
        inst_curr = length(mlb);
        if inst_curr < inst_aim + 1         % '+ 1' to include the instance which runs this script itself
            time = clock;
            time = strcat(num2str(time(4)),':',num2str(time(5)));
            disp(strcat("Starting instance number ", num2str(i), " at ", time, " for ", ui1))
                break
        end
        pause(5)
    end
    
    save('instance_variables.mat','ui1','ui2','ui3','ui4','ui5','ui6', 'ui7')
    !matlab -nosplash -desktop -r "load instance_variables.mat;batchforce(ui1, ui2, ui3, ui4, ui5, ui6, ui7);exit" &
    pause(30)
end

pause(30)
format short
delete instance_variables.mat
disp('Finished & instance_variables.mat deleted')
function [data, annotations, layer_numbers, layer_names, colours, colour_scheme] = RegionAnalysis_Unbiased(data, I, source, layer_numbers, layer_names)    % by Julia Becker, 01/04/2020
%REGIONANALYSIS_UNBIASED User assigns ROIs without seeing the measurement
%points
%   - annotations add up on top of each other (you can overwrite an already
%   annotated area with an annotation of a higher layer)

% If not predefined, select numbers and names of layers to be analysed
if (or(isempty(layer_numbers), isempty(layer_names)) == 1)    
    layer_numbers = inputdlg('How many different layers do you want to analyse? (max 6)');          % if >6 layers needed, will need to implement more colours - just change variable 'colours'!
    layer_numbers = str2num(layer_numbers{1,1});
    
    if layer_numbers >= 6
        warndlg('Too many layers. Amend script to include more colours.')
    end
    
    for i = 1:layer_numbers
        layer_names(i,1) = "Empty";                                                                 % Seems pointless but makes it a string which is needed for later parts of code
    end
    
    for i = 1:layer_numbers
        layer_names(i,1) = inputdlg(['What is the name of your Matter ', num2str(i), '?']);
    end
    clear i inputname;
end

colours = {'red','r';'cyan','c';'green','g';'yellow','y';'magenta','m'; 'black', 'k'};

% Annotate the layers
annotations = {};

for i = 1:layer_numbers
    k = 1;
    userselect4b = 'Yes';
    uiwait(msgbox(strcat("Please define your layer '",layer_names(i,1),"'!")))
    
    
    while strcmp(userselect4b, 'Yes') == 1
        annotations{i,k} = drawassisted('Closed', true, 'Color', colours{i,2});
        userselect4a = questdlg('Keep this annotation?','Annotation drawing','Yes','No','Yes');
        if strcmp(userselect4a, 'No') == 1
            delete(annotations{i,k});
            annotations{i,k} = {};
            k = k-1;
        end
        userselect4b = questdlg(strcat("Do you want to make another annotation for '",layer_names(i,1),"'?"),'Another annotation?','Yes','No','Yes');
        if strcmp(userselect4b, 'Yes') == 1
            k = k+1;
        end
    end
end

% SAVE FIGURE WITH LABELLED LAYERS
figurewithlayers_name = fullfile(source(1:end-9),'annotated layers_areas.tif');
saveas(gcf,figurewithlayers_name);
% Saving annotation for second layer (usually grey matter) as outline so it
% can be used for illustrating purposes if needed - JB 25/03/2021
outline = annotations{2,1};
save(source, 'outline', '-append')

% Go through layers and change activation values based on annotations
for i = 1:layer_numbers
    for j = 1:size(annotations,2)
        if isempty(annotations{i,j})
            break
        end
        mask{i,j} = createMask(annotations{i,j},I);
        clear k
        for k = 1:size(data,1)
            if mask{i,j}(round(data.y_image(k)),round(data.x_image(k))) == 1
                % Assign new roi values according to mask
                data.roi(k) = i;
            end
        end
    end
end

% MAKE NEW FIGURE WITH POINTS ONLY
close all
ShowImage(I)
for i = 1:layer_numbers
    plot(data.x_image(find(data.roi == i)), data.y_image(find(data.roi == i)), '.', 'MarkerSize', 8, 'LineWidth', 2, 'Color', colours{i,2});
end

% Save figure with points only
figurewithlayers_name = fullfile(source(1:end-9), 'annotated layers_points.tif');
saveas(gcf,figurewithlayers_name);

% SAVE COLOUR SCHEME FOR FIGURE
colour_scheme = cell(1,1);
for i = 1:length(layer_names)
    colour_scheme{i,1} = layer_names(i,1);
    colour_scheme{i,2} = colours{i,1};
end

fileID = fopen(fullfile(source(1:end-9),'annotated layers_colour scheme.txt'),'w');
formatSpec = '%s\t%s\n';
[nrows,ncols] = size(colour_scheme);
for row = 1:nrows
    fprintf(fileID,formatSpec,colour_scheme{row,:});
end
fclose(fileID);

clear fileID formatSpec nrows ncols row
end


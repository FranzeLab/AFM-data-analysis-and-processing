function [data, layer_numbers, layer_names, colours, colour_scheme] = RegionAnalysis_Standard(data, I, source, layer_numbers, layer_names)    % by Julia Becker, 01/04/2020
%REGIONANALYSIS_STANDARD Displays points while user assigns layers
%   - Select area by clicking left and circling, finish with right click
%   - Removed option to select individual points by clicking as will be
%     difficult for overlaying points - only one point will be selected.

% If not predefined, select numbers and names of layers to be analysed
if (or(isempty(layer_numbers), isempty(layer_names)) == 1)
    layer_numbers = inputdlg('How many different layers do you want to analyse? (max 6)');          % if >6 layers needed, will need to implement more colours - just change variable 'colours'!
    layer_numbers = str2num(layer_numbers{1,1});
    
    if layer_numbers >= 7
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

% Display image with inactivated points and instruct user
hold on
plot(data.x_image(find(data.roi == 0)), data.y_image(find(data.roi == 0)), '.', 'MarkerSize', 8, 'LineWidth', 2, 'Color', 'b');
for i = 1:layer_numbers
    plot(data.x_image(find(data.roi == i)), data.y_image(find(data.roi == i)), '.', 'MarkerSize', 8, 'LineWidth', 2, 'Color', colours{i,2});
end

message = sprintf('Inactivated points are displayed in blue.\n\nLayers are displayed in red, cyan, green, yellow and blue.\n\nYou will now specify which points belong to a certain layer, one layer at a time. You can always amend the layer one point belongs to later if needed.\n\nEach point can only belong to one layer.');
uiwait(msgbox(message));
clear message

% Go through layers and let user select points
for i = 1:layer_numbers
    message = sprintf('Please draw circles around the points beloning to layer\n\n        '+layer_names(i,1)+'\n\nThese points will turn '+colours{i,1}+'.\n\nIf you have selected points by accident, circle them repeatedly until their colour is correct.\nRight click when you are done with this layer.');
    message = char(message);
    uiwait(msgbox(message));
    clear message
    
    [bli,bla] =  ginput(1); % to remove 'alt' as the last key that was pressed on the figure from memory otherwise while loop won't run
    order = fliplr([0:i,0:i]);
    clear bli bla
    
    while 1
        hold on
        key = get(gcf, 'SelectionType');
        if strcmpi(key, 'alt')
            break
        end
        
        annotations_more{i,1} = drawassisted('Closed', true);
        mask{i,1} = createMask(annotations_more{i,1},I);
        annotations_more{i,1}.Visible = 'off';
        
        clear k
        for k = 1:size(data,1)
            if mask{i,1}(round(data.y_image(k)),round(data.x_image(k))) == 1             
                % Assign new roi values according to mask  - move this point one layer down
                current_value = data.roi(k);
                new_value = order((find(order == current_value,1))+1);
                data.roi(k) = new_value;
            end
        end
        
        % Replot all points according to their roi value
        plot(data.x_image(find(data.roi == 0)), data.y_image(find(data.roi == 0)), '.', 'MarkerSize', 8, 'LineWidth', 2, 'Color', 'b');
        for i = 1:layer_numbers
            plot(data.x_image(find(data.roi == i)), data.y_image(find(data.roi == i)), '.', 'MarkerSize', 8, 'LineWidth', 2, 'Color', colours{i,2});
        end
    end
end
clear k i XY_new1

% SAVE FIGURE WITH LABELLED LAYERS
figurewithlayers_name = fullfile(source(1:end-9),'annotated layers.tif');
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


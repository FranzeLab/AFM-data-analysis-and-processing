function PlotMap(data, I, ui0, PathName, layer_names, markertype, markersize, bar_intervals, colourmap, x_lim, y_lim, varargin)    % by Julia Becker, 14/10/2021
%PLOTMAP Plots heatmaps based on modulus values from data and specified
%        scale on cropped image with optional scalebar

% OPTIONAL INPUTS
% - Answers to questions creating us1-4 in the format: [us1 us2 us3 us4]
% - Additionally after the above in curly brackets the answer to the questions about scaling:
%     - Scale to maximum value of data (1) or to values specified by user (2)
%     - If 2 at the above
%         - Which values to scale to as a matrix: [value1 value2 value3 ...]
%     so either {1} or {2, [400 500 600]}
% - Additionally after the above in curly brackets the answer to the questions about the scale bar:
%     - Include scalebar: yes (1) or no (1)
%     - If 1 at the above
%         - Answers to length of bar in µm, bar thickness, font size as a matrix: [barlength barthickness fontsize]
%     so either {0} or {1, [500 10 28]}
% For example: PlotMap( ..., [1 0 1 1], {2, [400 500 600]}, {1, [500 10 28]})

% Compared to previous versions, this one is quicker as it does not plot
% each measurement individually but uses indexing to prepare data1. It
% allows to include a scalebar.

% The function can't currently loop over subfolders from complex
% experiments and plot heatmaps separately for each subfolder. This would
% need to be implemented. Consider how to treat scaling to maximum
% elasticity in this case (This would presumably need to be max elasticity
% for each subfolder. This might require rearrangement of heatmap_scale
% definition within the function.)

%% Learn what to plot
if nargin > 11
    us1 = varargin{1,1}(1);
    us2 = varargin{1,1}(2);
    us3 = varargin{1,1}(3);
    us4 = varargin{1,1}(4);
    
else
    if strcmp(ui0, 'Complex') == 1
        reply = questdlg('Do you want to plot all measurements together or each subfolder individually?', 'What to plot?', 'All together', 'Each subfolder', 'Both', 'All together');
        if strcmp(reply, 'All together') == 1
            us1 = 2;
            us2 = 0;
        elseif strcmp(reply, 'Each subfolder') == 1
            us1 = 0;
            us2 = 1;
        elseif strcmp(reply, 'Both') == 1
            us1 = 2;
            us2 = 1;
        end
        clear reply
    elseif strcmp(ui0, 'Simple') == 1
        us1 = 1;
        us2 = 0;
    else warndlg("Not sure if this is a simple or complex experiment. Please specify 'ui0' accordingly.");
    end
    
    if us2 == 1
        warndlg('This option is not currently implemented. Have fun modifying the code! :)')
    end
    
    reply = questdlg('Do you want to also see plots for individual layers?', 'Layers', 'No', 'Yes', 'No');
    if strcmp(reply, 'Yes') == 1
        us3 = 1;
    else
        us3 = 0;
    end
    clear reply
    
    if us3 == 1
        reply = questdlg('Do you want to also save the plots for each layer? (Many plots need lots of space!)', 'Save layer plots?', 'No', 'Yes', 'No');
        if strcmp(reply, 'Yes') == 1
            us4 = 1;
        else
            us4 = 0;
        end
        clear reply
    else
        us4 = 0;
    end
end

% Create paths for figure saving
if us1 == 1
    us1_path = fullfile(PathName, 'elasticity maps');
elseif us1 == 2
    us1_path = fullfile(PathName, 'combined', 'elasticity maps');
end

%% The following would be relevant if implementing looping over subfolders
% of complex experiments
%
% if us2 == 1
%     subfolder = unique(data.folder);
% end
% us2_path = fullfile(PathName, subfolder{i,1}(1:end-18), 'elasticity
% maps');       % Does not go here but in a subfolder loop if needed

%% Scaling of the heatmap
if nargin > 11
    ui4 = varargin{2}{1};
else
    ui4 = questdlg(sprintf('The heatmap can be scaled in two ways:\n\n(1) to the maximum elasticity within this map\n(2) to a maximum value set by the user\n    (values above the threshold will look identical)\n'), 'Scaling of heatmap','1', '2', '1');
    ui4 = str2num(ui4);
end

% Define maximum value in heatmap colour scale ('threshold')
if ui4 == 1
    threshold = ceil(max(data.modulus));
elseif ui4 == 2
    if nargin > 11
        threshold = varargin{2}{2}
    else
        threshold = inputdlg(sprintf('Please give the maximum elasticity you want to scale to (in Pa).\nYou can enter more than one value.\n'));
        threshold = str2num(threshold{1,1});
    end
end

% Ask whether to plot scalebar
if nargin > 11
    us5 = varargin{3}{1};
    if us5 == 1
        us5 = 'Yes';
        us6 = varargin{3}{2};
        us6 = us6';
    end
else
    us5 = questdlg('Should a scalebar be plotted?','Scalebar','Yes','No','Yes');
    if strcmp(us5,'Yes') == 1
        us6 = inputdlg({'Bar length (µm):','Bar thickness:','Font size:  (0 = no label)'},'Scalebar parameters',[1 35],{'500','10','28'});
        us6 = str2double(us6);
    end
end
%% Iterate over threshold values
for j = 1:length(threshold)
    
    %% Set up colour scale
    if strcmp(colourmap, 'hot') == 1
        heatmap_scale = hot(threshold(j));     % using Matlab colormap array 'hot' - this can be changed
    elseif strcmp(colourmap, 'gray') == 1
        heatmap_scale = gray(threshold(j));
    elseif strcmp(colourmap, 'parula') == 1
        heatmap_scale = parula(threshold(j));
    elseif strcmp(colourmap, 'jet') == 1
        heatmap_scale = jet(threshold(j));
    else warndlg('The chosen colourmap is not configured yet. Please amend the function.')
    end
    
    %% Make heatmap including all measurement points from the experiment
    if us1 > 0
        data1 = data;
        data1.modulus = round(data1.modulus);
        data1(isnan(data1.modulus),:) = [];
        data1(find(data1.modulus == 0),:) = [];
        data1.modulus(find(data1.modulus > threshold(j))) = threshold(j);
        
        colour_spec = heatmap_scale(data1.modulus(:),:);
        
        close all
        figure
        ShowImage(I)
        set(gca,'XLim',x_lim)
        set(gca,'Ylim',y_lim)
        scatter(data1.x_image(:), data1.y_image(:), markersize, colour_spec(:,:), 'filled', markertype);
               
        % Include colour scale bar
        colormap(heatmap_scale)
        colorbar
        colorbar_ticklabels = [0:bar_intervals:threshold(j)];
        colorbar_ticks = colorbar_ticklabels/threshold(j);
        colorbar('Ticks',colorbar_ticks,'TickLabels',colorbar_ticklabels, 'FontSize', 18)
        clear cb
        
        % Include optional scalebar
        if strcmp(us5,'Yes') == 1
            Scalebar(us6(1), us6(2), us6(3), PathName)
        end
        set(gcf,'Color','w')            % The background color has to be reset to make the white items be saved correctly. Default color is [0.94 0.94 0.94] which can also be used.
        
        % NEW - trying to prevent figure distortion
        set(gcf, 'WindowState','maximized');
        pause(2)
        
        % Save the figure
        heatmap_name = fullfile(us1_path, strcat('all points_maxindent_scaledto', num2str(threshold(j)),'.png'));
        saveas(gcf,heatmap_name);       
        heatmap_name = fullfile(us1_path, strcat('all points_maxindent_scaledto', num2str(threshold(j)),'.fig'));
        saveas(gcf,heatmap_name);
        
        clear data1 heatmap_name 
    end
    
    %% Make separate heatmaps for measurement points from each layer
    if us3 == 1
        layers_used = unique(data.roi);
        layers_used(find(layers_used == 0)) = [];
        
        for k = 1:length(layers_used)
            data1 = data(find(data.roi(:) == layers_used(k)),:);
            data1.modulus = round(data1.modulus);
            data1(isnan(data1.modulus),:) = [];
            data1(find(data1.modulus == 0),:) = [];
            data1.modulus(find(data1.modulus > threshold(j))) = threshold(j);
            
            colour_spec = heatmap_scale(data1.modulus(:),:);
            
            close all
            ShowImage(I)
            set(gca,'XLim',x_lim)
            set(gca,'Ylim',y_lim)
            scatter(data1.x_image(:), data1.y_image(:), markersize, colour_spec(:,:), 'filled', markertype);
            
            % Include colour scale bar
            colormap(heatmap_scale)
            colorbar
            colorbar_ticklabels = [0:bar_intervals:threshold(j)];
            colorbar_ticks = colorbar_ticklabels/threshold(j);
            colorbar('Ticks',colorbar_ticks,'TickLabels',colorbar_ticklabels, 'FontSize', 18)
            clear cb
            
            % Include optional scalebar
            if strcmp(us5,'Yes') == 1
                Scalebar(us6(1), us6(2), us6(3), PathName)
            end
            set(gcf,'Color','w')            % The background color has to be reset to make the white items be saved correctly. Default color is [0.94 0.94 0.94] which can also be used.
  
            % Save the figure
            if us4 == 1
                heatmap_name = fullfile(us1_path, strcat(layer_names(k), '_maxindent_scaledto', num2str(threshold(j)),'.png'));
                saveas(gcf,heatmap_name{1,1});
                
%                 heatmap_name = fullfile(us1_path, strcat(layer_names(k), '_maxindent_scaledto', num2str(threshold(j)),'.fig'));
%                 saveas(gcf,heatmap_name{1,1});
                clear heatmap_name
            else
                uiwait(msgbox("Click 'okay' for next layer."))
            end
            clear data1
        end
    end
end
uiwait(msgbox('Finished plotting heatmaps.'))

end


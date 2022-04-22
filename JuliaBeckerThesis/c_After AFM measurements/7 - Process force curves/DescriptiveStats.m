function [stats, stats_overview] = DescriptiveStats(data, PathName, layer_numbers)    % by Julia Becker, 10/04/2020
%DESCRIPTIVESTATS
% For each condition and ROI, calculate
%   - median
%   - lower quartile (25th percentile)
%   - upper quartile (75th percentile)
%	- minimum value
%   - maximum value
%   - mean
% 
% The standard columns are those were these data are calculated from the
% modulus column. For experiments, where there are data for
% modulus.*indent_time and/or modulus./(indent_depth./indent_time), the
% above parameters are also calculated for those columns.
% 
% If you want to have these parameters, insert "RelativeToTimeAndSpeed.m" before this
% function in the script.

% Prepare table of correct dimensions
subfolder = unique(data.folder);
sz = [(size(subfolder,1).*(layer_numbers+1)),16];
vartypes = {'cell','cell','double','double','double','cell','double','double','double','double','double','double','double','double','double','double'};
varnames = {'PathName','folder','beadradius','springconstant','animal','orient','setpoint','speed','roi','N','median','low','up','bottom','top','mean'};
stats = table('Size',sz,'VariableTypes',vartypes,'VariableNames',varnames);

if ismember('mod_time', data.Properties.VariableNames) == 1
    sz = [(size(subfolder,1).*(layer_numbers+1)),6];
    vartypes = {'double','double','double','double','double','double'};
    varnames = {'median_time','low_time','up_time','bottom_time','top_time','mean_time'};
    stats1 = table('Size',sz,'VariableTypes',vartypes,'VariableNames',varnames);
    stats = [stats stats1];
    clear stats1
end

if ismember('mod_speed', data.Properties.VariableNames) == 1
    sz = [(size(subfolder,1).*(layer_numbers+1)),6];
    vartypes = {'double','double','double','double','double','double'};
    varnames = {'median_speed','low_speed','up_speed','bottom_speed','top_speed','mean_speed'};
    stats1 = table('Size',sz,'VariableTypes',vartypes,'VariableNames',varnames);
    stats = [stats stats1];
    clear stats1
end

% Calculate statistical parameters from dataset for each condition and ROI
k = 1;
for j = 1:size(subfolder,1)
    data1 = data(find(contains(data.folder,subfolder{j,1})),:);
    stats.beadradius(k:k+layer_numbers) = unique(data1.beadradius);
    stats.springconstant(k:k+layer_numbers) = unique(data1.springconstant);
    
    if sum(isnan(data.animal)) ~= size(data.animal,1)
        stats.animal(k:k+layer_numbers) = unique(data1.animal);
    end
    if sum(cellfun(@isempty,data.orient)) ~= size(data.orient,1)
        stats.orient(k:k+layer_numbers) = unique(data1.orient);
    end
    if sum(isnan(data.setpoint)) ~= size(data.setpoint,1)
        stats.setpoint(k:k+layer_numbers) = unique(data1.setpoint);
    end
    if sum(isnan(data.speed)) ~= size(data.speed,1)
        stats.speed(k:k+layer_numbers) = unique(data1.speed);
    end
    
    % For entire experiment (all measurements)
    stats.folder{k} = subfolder{j,1};
    stats.PathName{k} = PathName;
    stats.roi(k)    = 1000;
    
    stats.N(k) = length(data1.modulus);
    stats.median(k) = median(data1.modulus,'omitnan');
    stats.low(k) = quantile(data1.modulus, 0.25);
    stats.up(k) = quantile(data1.modulus, 0.75);
    stats.bottom(k) = min(data1.modulus);
    stats.top(k) = max(data1.modulus);
    stats.mean(k) = mean(data1.modulus,'omitnan');
    
    if ismember('mod_time', data1.Properties.VariableNames) == 1
        stats.median_time(k) = median(data1.mod_time,'omitnan');
        stats.low_time(k) = quantile(data1.mod_time, 0.25);
        stats.up_time(k) = quantile(data1.mod_time, 0.75);
        stats.bottom_time(k) = min(data1.mod_time);
        stats.top_time(k) = max(data1.mod_time);
        stats.mean_time(k) = mean(data1.mod_time,'omitnan');
    end
    
    if ismember('mod_speed', data1.Properties.VariableNames) == 1
        stats.median_speed(k) = median(data1.mod_speed,'omitnan');
        stats.low_speed(k) = quantile(data1.mod_speed, 0.25);
        stats.up_speed(k) = quantile(data1.mod_speed, 0.75);
        stats.bottom_speed(k) = min(data1.mod_speed);
        stats.top_speed(k) = max(data1.mod_speed);
        stats.mean_speed(k) = mean(data1.mod_speed,'omitnan');
    end
    
    k = k + 1;
    
    % Per ROI
    if sum(data1.roi) > 0           % No individual analysis necessary if only 0 in data1.roi
        for i = 1:layer_numbers
            stats.folder{k} = subfolder{j,1};
            stats.PathName{k} = PathName;
            stats.roi(k)    = i;
            
            stats.N(k) = length(data1.modulus(find(data1.roi == i)));
            stats.median(k) = median(data1.modulus(find(data1.roi == i)),'omitnan');
            stats.low(k) = quantile(data1.modulus(find(data1.roi == i)), 0.25);
            stats.up(k) = quantile(data1.modulus(find(data1.roi == i)), 0.75);
            stats.bottom(k) = min(data1.modulus(find(data1.roi == i)));
            stats.top(k) = max(data1.modulus(find(data1.roi == i)));
            stats.mean(k) = mean(data1.modulus(find(data1.roi == i)),'omitnan');
            
            if ismember('mod_time', data1.Properties.VariableNames) == 1
                stats.median_time(k) = median(data1.mod_time(find(data1.roi == i)),'omitnan');
                stats.low_time(k) = quantile(data1.mod_time(find(data1.roi == i)), 0.25);
                stats.up_time(k) = quantile(data1.mod_time(find(data1.roi == i)), 0.75);
                stats.bottom_time(k) = min(data1.mod_time(find(data1.roi == i)));
                stats.top_time(k) = max(data1.mod_time(find(data1.roi == i)));
                stats.mean_time(k) = mean(data1.mod_time(find(data1.roi == i)),'omitnan');
            end
            
            if ismember('mod_speed', data1.Properties.VariableNames) == 1
                stats.median_speed(k) = median(data1.mod_speed(find(data1.roi == i)),'omitnan');
                stats.low_speed(k) = quantile(data1.mod_speed(find(data1.roi == i)), 0.25);
                stats.up_speed(k) = quantile(data1.mod_speed(find(data1.roi == i)), 0.75);
                stats.bottom_speed(k) = min(data1.mod_speed(find(data1.roi == i)));
                stats.top_speed(k) = max(data1.mod_speed(find(data1.roi == i)));
                stats.mean_speed(k) = mean(data1.mod_speed(find(data1.roi == i)),'omitnan');
            end
            
            k = k + 1;
        end
        clear data1
    end
end
clear i j k

% Stats_overview for display to user
stats2 = stats(find(stats.roi == 1000),:);
stats_overview = table(stats2.setpoint, stats2.speed, round(stats2.bottom), round(stats2.low), round(stats2.median), round(stats2.up), round(stats2.top));
stats_overview.Properties.VariableNames = {'setpoint','speed','bottom','low','median','up','top'};
stats_overview = sortrows(stats_overview,[2 1]);

end


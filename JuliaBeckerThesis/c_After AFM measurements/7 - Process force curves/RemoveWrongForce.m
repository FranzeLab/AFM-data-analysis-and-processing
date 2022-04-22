function [data, deviate] = RemoveWrongForce(data, cutoff)    % by Julia Becker, 01/04/2020, changed 05/01/2021 to accommodate the case that curves with deviating forces exist
%REMOVEWRONGFORCE Delete curves where the actual force applied was too far from force setpoint

% Find all curves which deviate more than cutoff
j = 1;
for i = 1:size(data,1)
    if abs(1-(data.force(i)./data.setpoint_N(i))) > cutoff
        deviate(j,1) = i;
        j = j+1;
    end
end

if exist('deviate') == 1
    % Remove deviating measurements from "data"
    data(deviate(:),:) = [];
else
    % Make deviate empty if there are no wrong forces   % JB 22/04/2021
    deviate = [];
end

clear i j

end


function [contactpointquality] = contactpointfit(rawdata,numberofdatapoints,contactpointquality,springConstant,loop,contactpointindex,userInput)
% determines the rms of weighed fits of the force curve and the
% approachdata

% akw48: Julia and Ryan found an issue, that I think is to do with the
% length of the data sets. I have adjusted the code below to allow for a
% scaling factor. It seems like the most important one is the minimum
% points in the two "if (length(indentationdata)" conditions below. This
% was set to 10, but I have changed it to scale with the data, so that it
% is rounded to the nearest integer to 1% of the data points (as 10 is 1%
% of the example given by andreas of a 1000 data point curve). So Minpoints
% will have a new default, while the others can be adjusted by commenting
% out the lines that set them to 1. 
% Tweaked Minpoints to 4%
loop1res = round(numberofdatapoints()/1000,0);
loop2res = round(numberofdatapoints()/1000,0);
Minpoints = round(0.04*numberofdatapoints(),0);
%Minpoints = 10;
loop1res = 1;
loopres2 = 1;

if (loop==1)
    checkindices = contactpointindex:15*loop1res:numberofdatapoints-20*loop1res; 
    counter = length(checkindices);
elseif (loop==2)
    if (contactpointindex<=numberofdatapoints-40*loop2res)
        checkindices = contactpointindex-35*loop2res:loop2res:contactpointindex+35*loop2res;
    elseif (contactpointindex <= numberofdatapoints-20*loop2res)
        checkindices = contactpointindex-35*loop2res:loop2res:contactpointindex+15*loop2res;
    else 
        checkindices = contactpointindex-35*loop2res:loop2res:contactpointindex;
    end   
    counter = length(checkindices);
else
    error('contactpointquality-loop out of control');
end
for i = 1:counter
    contactpointindex = checkindices(i);
    %% Cut approachdata at contactpoint    
    approachdata = [rawdata{1,3}(1:contactpointindex) rawdata{1,2}(1:contactpointindex)];
    %% approachlinefit
    [approachfit,approachfitquality] = fitapproach (approachdata);
    approachfitcoefficients = coeffvalues(approachfit);
    approachfitqualitycell = struct2cell(approachfitquality);
    %% set theoretical contactpoint at origin and recalculate force curve
    forcecurvedata = [rawdata{1,3}(contactpointindex:numberofdatapoints,1) rawdata{1,2}(contactpointindex:numberofdatapoints,1)];
    forcecurvedata = [(forcecurvedata(:,1)-rawdata{1,3}(contactpointindex)),forcecurvedata(:,2)-approachfitcoefficients(1,1)*forcecurvedata(:,1)-approachfitcoefficients(1,2)];
    indentationdata = [forcecurvedata(:,1) + forcecurvedata(:,2)/springConstant, forcecurvedata(:,2)]; %akw48: Corrected indentation calculation
    indentationdata(:,1) = (-1)*indentationdata(:,1);
    %% force curve fit
    weight_user_index = GetHeaderValue(userInput,'weight_user_index');
    if (length(indentationdata)>Minpoints)
        if weight_user_index == 1
            [Hertzfitt,Hertzfitquality] = weighedhertzfit(indentationdata);
        elseif weight_user_index == 0
            [Hertzfitt,Hertzfitquality] = hertzfit(indentationdata);
        end
        Hertzfitcoefficient = coeffvalues(Hertzfitt);
        Hertzfitqualitycell = struct2cell(Hertzfitquality);
        if (Hertzfitcoefficient < 0)
            Hertzfitqualitycell{5,1} = NaN;
        end
    elseif (length(indentationdata)<=Minpoints)
        Hertzfitqualitycell{5,1} = NaN;
 %       fprintf('*');
    end
    %% fill quality matrix
    contactpointquality(contactpointindex,1) = contactpointindex;
 %   contactpointquality(contactpointindex,2) = approachfitqualitycell{5,1};
 %   contactpointquality(contactpointindex,3) = Hertzfitqualitycell{5,1};
    %AKW: batchfoce struggles with the lines above for steep curves which
    %use rmse errors for both herts and contact point fit (later summed and
    %minimised). The below looks at the total sum of the squared error
    %(sse) which is a better thing to minimise
    contactpointquality(contactpointindex,2) = approachfitqualitycell{1,1};
    contactpointquality(contactpointindex,3) = Hertzfitqualitycell{1,1};
end
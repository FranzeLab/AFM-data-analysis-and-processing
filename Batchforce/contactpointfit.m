function [contactpointquality] = contactpointfit(rawdata,numberofdatapoints,contactpointquality,springConstant,loop,contactpointindex,userInput)
% determines the rms of weighed fits of the force curve and the
% approachdata
if (loop==1)
    checkindices = contactpointindex:15:numberofdatapoints-20;
    counter = length(checkindices);
elseif (loop==2)
    if (contactpointindex<=numberofdatapoints-40)
        checkindices = contactpointindex-35:contactpointindex+35;
    elseif (contactpointindex <= numberofdatapoints-20)
        checkindices = contactpointindex-35:contactpointindex+15;
    else 
        checkindices = contactpointindex-35:contactpointindex;
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
    if (length(indentationdata)>10)
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
    elseif (length(indentationdata)<=10)
        Hertzfitqualitycell{5,1} = NaN;
    end
    %% fill quality matrix
    contactpointquality(contactpointindex,1) = contactpointindex;
    contactpointquality(contactpointindex,2) = approachfitqualitycell{5,1};
    contactpointquality(contactpointindex,3) = Hertzfitqualitycell{5,1};
end
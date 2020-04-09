function [Results] = forcecurveanalysis (rawdata,headerinfo,userInput,minCP_index,w,local_CP_index)

local_beadradius = GetHeaderValue(userInput,'beadradius');
%% determine the number of data points
numberofdatapoints = length(rawdata{1,3});
%% evaluate weighed force fits by rms of fit for contact points
contactpointquality = zeros(numberofdatapoints,5);

springConstant = GetHeaderValue(headerinfo,'springConstant');

if minCP_index < 100
    contactpointindex =100;
else
    contactpointindex=minCP_index;
end
% this for loop serves the sole purpose of reducing runtime by having a
% first go with only each 20th data point considered and than doing a
% fine tune around the contactpoint.
if w == 1
    for loop = 1:2
        contactpointquality = contactpointfit(rawdata,numberofdatapoints,contactpointquality,springConstant,loop,contactpointindex,userInput);
        %% only consider nonzero entries of the contactpointquality matrix
        clear usedcontactpointquality
        usedcontactpointquality(:,1) = nonzeros(contactpointquality(:,1));
        usedcontactpointquality(:,2) = nonzeros(contactpointquality(:,2));
        usedcontactpointquality(:,3) = nonzeros(contactpointquality(:,3));
        usedcontactpointquality(:,4) = usedcontactpointquality(:,2)+usedcontactpointquality(:,3);
        %% look for minimum rms of the force curve in the contactpointmatrix
        [bestcontactpointrms,bestcontactpointindex] = min(usedcontactpointquality(:,4));
        contactpointindex = usedcontactpointquality(bestcontactpointindex,1);
    end
elseif w==0   %new for cropping overindents
    contactpointindex = local_CP_index;
    bestcontactpointrms = 0;   % the value from the w=1 run will be used
    
else
    loop = 2;
    contactpointindex = local_CP_index;
    contactpointquality = contactpointfit(rawdata,numberofdatapoints,contactpointquality,springConstant,loop,contactpointindex,userInput);
    %% only consider nonzero entries of the contactpointquality matrix
    clear usedcontactpointquality
    usedcontactpointquality(:,1) = nonzeros(contactpointquality(:,1));
    usedcontactpointquality(:,2) = nonzeros(contactpointquality(:,2));
    usedcontactpointquality(:,3) = nonzeros(contactpointquality(:,3));
    usedcontactpointquality(:,4) = usedcontactpointquality(:,2)+usedcontactpointquality(:,3);
    %% look for minimum rms of the force curve in the contactpointmatrix
    [bestcontactpointrms,bestcontactpointindex] = min(usedcontactpointquality(:,4));
    contactpointindex = usedcontactpointquality(bestcontactpointindex,1);
    
end
%% fit approach data to the best contactpoint
approachdata = [rawdata{1,3}(1:contactpointindex) rawdata{1,2}(1:contactpointindex)];
[approachfit] = fitapproach (approachdata);
approachfitcoefficients = coeffvalues(approachfit);
%newapproachdata = [approachdata(:,1)-rawdata{1,3}(contactpointindex),approachdata(:,2)-approachfitcoefficients(1,1)*approachdata(:,1)-approachfitcoefficients(1,2)];
%[approachfit] = fitapproach (newapproachdata); AKW: These lines of I guess
%Andreas' seem not to do anything. Hence commented out
%% fit forcecurve data to the best contactpoint
forcecurvedata = [rawdata{1,3}(contactpointindex:numberofdatapoints,1) rawdata{1,2}(contactpointindex:numberofdatapoints,1)];
forcecurvedata = [(forcecurvedata(:,1)-rawdata{1,3}(contactpointindex)),forcecurvedata(:,2)-approachfitcoefficients(1,1)*forcecurvedata(:,1)-approachfitcoefficients(1,2)];
indentationdata = [forcecurvedata(:,1) + forcecurvedata(:,2)/springConstant, forcecurvedata(:,2)]; %akw48: Corrected indentation calculation
indentationdata(:,1) = (-1)*indentationdata(:,1);
indentation = max(indentationdata(:,1));
force = max(indentationdata(:,2));

weight_user_index = GetHeaderValue(userInput,'weight_user_index');
if weight_user_index == 1
    [Hertzfit,~] = weighedhertzfit(indentationdata);
elseif weight_user_index == 0
    [Hertzfit,~] = hertzfit(indentationdata);
end

%% Calculate results
Hertzfitcoefficients = coeffvalues(Hertzfit);
Hertzfitcoefficients = real(Hertzfitcoefficients);
modulus = Hertzfitcoefficients*(3/4)/sqrt(local_beadradius);
space = ' ';
Results{1} = {['indentation' space num2str(indentation)];...
    ['force' space num2str(force)];...
    ['modulus' space num2str(modulus)];...
    ['hertzfactor', space num2str(Hertzfitcoefficients(1))];...
    ['contactpointindex' space num2str(contactpointindex)];...
    ['bestcontactpointrms' space num2str(bestcontactpointrms)]};
end
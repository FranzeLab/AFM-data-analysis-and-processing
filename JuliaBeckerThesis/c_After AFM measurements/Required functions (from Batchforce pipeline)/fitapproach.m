function [approachfit, approachfitquality] = fitapproach (approachdata)
% fits the approachline currently linear
q=1;
while (q==1);
approachfit = fittype({'x','1'},'coefficients',{'a1','a2'});
    options = fitoptions('Method','LinearLeastSquares');
    [approachfit, approachfitquality] = fit(approachdata(:,1),approachdata(:,2),approachfit,options);
    y = feval(approachfit,approachdata(:,1));
    difference = (y-approachdata(:,2)).^2;
    meandiff = mean (difference);
    if ((difference(end)>2*meandiff) && (length(approachdata)>100))
        while ((difference(end)>2*meandiff)  && (length(approachdata)>100))
            difference = difference (1:end-1);
            approachdata = approachdata(1:end-1,:);
        end
    elseif ((difference(end) < 2*meandiff) || (length(approachdata)<=100))
        q=0;
    else
        disp('error at fitapproach')
    end
end
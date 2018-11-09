function [weighedHertzfit,weighedHertzfitquality] = weighedhertzfit(indentationdata)
% makes a weighed fit to the indentationdata (further indentation weights
% more)
fitdata = indentationdata;
indentationdatapoints = length (indentationdata);
Weights = 1:indentationdatapoints;
Weights = (Weights'/indentationdatapoints).^2;
q = 1;
while (q==1)
    weighedHertzmodel = fittype({'x^(3/2)'},'coefficients','Hertzfactor');
    weighedoptions = fitoptions('Method', 'LinearLeastSquares','Weights',Weights);
    [weighedHertzfit,weighedHertzfitquality,weighedHertzfitoutput] = fit(fitdata(:,1),fitdata(:,2),weighedHertzmodel,weighedoptions);
    w = feval(weighedHertzfit,fitdata(:,1));
    difference = (w-fitdata(:,2)).^2;
    meandiff = mean(difference);
    if (difference(1)>2*meandiff && length(fitdata) > 0.5*indentationdatapoints)
        while(difference(1)>2*meandiff && length(fitdata) > 0.5*indentationdatapoints)
            difference = difference(2:end);
            fitdata = fitdata(2:end,:);
            Weights = Weights(2:end);
        end
    elseif (difference(1)<2*meandiff || length(fitdata) <= 0.5*indentationdatapoints)
        q=0;
    else
        error('error at weighedhertzfit badcp elimination')
    end
end
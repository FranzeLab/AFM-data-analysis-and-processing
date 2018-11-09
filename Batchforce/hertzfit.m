function [Hertzfit,Hertzfitquality] = hertzfit(indentationdata)
% makes a fit to the indentationdata
fitdata = indentationdata;
indentationdatapoints = length(indentationdata);
Weights = ones(indentationdatapoints,1);
q = 1;
while q==1
    Hertzmodel = fittype({'real(x.^(3/2))'},'coefficients','Hertzfactor');
    hertzoptions = fitoptions('Method', 'LinearLeastSquares','Weights',Weights);

    [Hertzfit,Hertzfitquality,Hertzfitoutput] = fit(fitdata(:,1),fitdata(:,2),Hertzmodel,hertzoptions);
    
    w = feval(Hertzfit,fitdata(:,1));
    difference = (w-fitdata(:,2)).^2;
    meandiff = mean(difference);
    if ( (difference(1) > 2*meandiff) && (length(fitdata) > 0.5*indentationdatapoints))
        
        while ( (difference(1) > 2*meandiff) && (length(fitdata) > 0.5*indentationdatapoints))
            difference = difference(2:end);
            fitdata = fitdata(2:end,:);
            Weights = Weights(2:end);
        end
        
    elseif ( (difference(1) < 2*meandiff) || (length(fitdata) <= 0.5*indentationdatapoints)) 
        q=0;
    else
          error('error at hertzfit badcp elimination')
    end
   
end
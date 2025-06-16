function y = polynomial_step_function(x, fc, tc, dta, a)
%% this script is a ChatGPT translation of Ryan Greenhalgh's pyforce's equivalent polynomial_step_function within functions.py 
%POLYNOMIAL_STEP_FUNCTION  Piecewise function:
%
%  if x < tc:
%      y = 0
%  elseif tc <= x < tc + dta:
%      y = fc * ((x - tc)/dta)^a
%  else
%      y = fc

    % Make sure x is a column or row vector:
    x = x(:);
    y = zeros(size(x));

    idx1 = x < tc;
    idx2 = (x >= tc) & (x < (tc + dta));
    idx3 = x >= (tc + dta);

    y(idx1) = 0;
    y(idx2) = fc .* ((x(idx2) - tc) ./ dta) .^ a;
    y(idx3) = fc;
end

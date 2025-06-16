function result = SLM(x, c0, c1, c2, alpha, dta, r, f0)
%% this is ChatGPT's translation of Ryan Greenhalgh's slm_hyp1f1 from functions.py in pyforce 
%% created 7/4/2025
    % Function to calculate the given expression in MATLAB
    
    % Initialize the function value
    func = c0;
    
    % Add the exponential and hypergeometric part
    func = func + (c0 - c1) * exp(-x * c2) * hypergeom([alpha], [alpha + 1], dta * c2);
    
    % Calculate prefactor
    prefactor = (3 / 4) * f0 / sqrt(r);
    
    % Calculate constant term
    const = alpha^(1 - alpha) * dta^(alpha - 1);
    
    % Return the final result
    result = (func * const * prefactor).^(2 / 3);
end


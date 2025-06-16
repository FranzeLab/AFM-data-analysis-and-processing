function model_object = polynomial_step_model(data_obj, opt_kwargs)
%% this script is a based on a ChatGPT translation of Ryan Greenhalgh's pyforce's equivalent polynomial_step_model within models.py 
%POLYNOMIAL_STEP_MODEL  Fit polynomial_step_function to data in data_obj.
% feed this function with data that already only consists of extend and pause
%   model_object = polynomial_step_model(data_obj, opt_kwargs)
%
%   data_obj is assumed to have fields:
%       - fdt: a 3 x N or Nx3 array [f; d; t], or separate fields f, d, t
%       - extend_idx: an index
%       - pause_idx: an index
%       - results: a struct that may have a sub-field hertz_model.cp
%   opt_kwargs can be a placeholder for additional options.

    % ---------------------------------------------------
    % 1) Extract data (f, d, t) from data_obj
    % ---------------------------------------------------
    % If data_obj.fdt is something like a 3xN matrix:
    f = data_obj.fdt(1, :);  % force or signal
    d = data_obj.fdt(2, :);  % displacement or other
    t = data_obj.fdt(3, :);  % time
    
    % ---------------------------------------------------
    % 2) Guess at contact time     
    % ---------------------------------------------------
    cp_index = data_obj.extend_idx;  
    tc_guess = t(cp_index);

    % ---------------------------------------------------
    % 3) Build initial parameter guesses
    % ---------------------------------------------------
    fc0  = max(f);  % guess for fc
    tc0  = tc_guess;
    dta0 = 1;
    a0   = 1.5;

    % Lower and upper bounds for [fc, tc, dta, a]
    lb = [0,  0,    0,  1];
    ub = [Inf, Inf, Inf, 2];

    % ---------------------------------------------------
    % 4) Define a fitting function handle for lsqcurvefit
    % ---------------------------------------------------
    % p = [fc, tc, dta, a]
    fit_fun = @(p, x) polynomial_step_function(x, p(1), p(2), p(3), p(4));

    % ---------------------------------------------------
    % 5) Perform the fit using lsqcurvefit
    % ---------------------------------------------------
    p0 = [fc0, tc0, dta0, a0];
    options = optimoptions('lsqcurvefit', 'Display', 'off');
    p_fit = lsqcurvefit(fit_fun, p0, t', f', lb, ub, options);

    % Evaluate the best-fit model
    f_fit = fit_fun(p_fit, t');

    % ---------------------------------------------------
    % 6) Compute RMSE
    % ---------------------------------------------------
    residuals = f - f_fit;
    custom_rmse = sqrt(mean(residuals.^2)); 

    % ---------------------------------------------------
    % 7) Package results into model_object (similar to lmfit ModelResult)
    % ---------------------------------------------------
    model_object.params      = p_fit;       % [fc, tc, dta, a]
    model_object.best_fit    = f_fit;       % fitted y-values
    model_object.custom_rmse = custom_rmse; % store the RMSE
    model_object.residuals   = residuals;   % optional: store residuals
    
    % If you want to store param names or other details, you can extend:
    % model_object.paramNames = {'fc','tc','dta','a'};
disp('PSM Fitted parameters [fc, tc, dta, a]:');
disp(model_object.params);
if model_object.params(1) < 1e-6
    disp('WARNING: it looks like the Force is in N. The fit works much better in nN')
end
end

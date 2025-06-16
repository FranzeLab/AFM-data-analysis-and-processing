function model_object = SLM_model(data_obj, tc, alpha, dta, r, f0)
%% the below is based on ChatGPT's translation of Ryan Greenhalgh's slm_hyp1f1_model in models.py from pyforce
%% created 7/4/2025
        
        % Extract the necessary data
    f = data_obj.fdt(1, :);  % force or signal
    d = data_obj.fdt(2, :);  % displacement or other
    t = data_obj.fdt(3, :);  % time
        

        % Get values above the contact time
        idx = t > tc;
        f = f(idx);
        d = d(idx);
        t = t(idx) - tc;

        % Reset the indentation
        dr = data_obj.fdt(2, :) - min(d);  %used later in plot
        d = d - min(d);

        % Remove values where time exceeds dta
        idx = t > dta;
        d = d(idx);
        t = t(idx);

        % Initialize the model (assuming you have a function SLM for fitting)
        slmmodel = @(c, x) SLM(x,c(1), c(2), c(3), alpha,dta,r,f0);
        c0_0 = 1;
        c1_0 = 1;
        c2_0 = 1;
        c_0 = [c0_0, c1_0, c2_0];
        lb = [0,  0,  0];
        ub = [Inf, Inf, Inf];

        % Fit the model
        options = optimoptions('lsqcurvefit', 'Display', 'off');
        c_fit = lsqcurvefit(slmmodel, c_0, t', d', lb, ub, options);
        f_fit = slmmodel(c_fit, t');
        residuals = f - f_fit;
        custom_rmse = sqrt(mean(residuals.^2));
        model_object.params      = c_fit;       % fit output parms
        model_object.best_fit    = f_fit;       % fitted y-values
        model_object.custom_rmse = custom_rmse; % store the RMSE
        model_object.residuals   = residuals;   % optional: store residuals

        disp('SLM Fitted parameters [C0, C1, C2]:');
        disp(model_object.params);
               
        % Return the fitted model object
        return
    end

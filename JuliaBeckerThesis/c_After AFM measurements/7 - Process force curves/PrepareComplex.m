function PrepareComplex(PathName, ui0)    % by Julia Becker, 01/04/2020
%PREPARECOMPLEX Create necessary folders and files for complex experiments

if strcmp(ui0, 'Complex')
  if ~exist(fullfile(PathName, 'region analysis_all'))
      mkdir(fullfile(PathName, 'region analysis_all'));
  end
  
  if ~exist(fullfile(PathName, 'calibration_all'))
      mkdir(fullfile(PathName, 'calibration_all'));
  end
  
  if ~exist(fullfile(PathName, 'combined', 'elasticity maps'))
      mkdir(fullfile(PathName, 'combined', 'elasticity maps'));
  end
  
  if ~exist(fullfile(PathName, 'combined', 'region analysis'))
      mkdir(fullfile(PathName, 'combined', 'region analysis'));
  end

  if ~exist(fullfile(PathName, 'calibration_all', 'conversion_variables.mat'))
      invent = dir(fullfile(PathName, '**', 'conversion_variables.mat'));
      from = fullfile(invent(1).folder, invent(1).name);
      copyfile(from, fullfile(PathName, 'calibration_all', 'conversion_variables.mat'));
  end
  
  if ~exist(fullfile(PathName, 'calibration_all', 'overview.tif'))
      invent = dir(fullfile(PathName, '**', 'overview.tif'));
      from = fullfile(invent(1).folder, invent(1).name);
      copyfile(from, fullfile(PathName, 'calibration_all', 'overview.tif'));
  end
end


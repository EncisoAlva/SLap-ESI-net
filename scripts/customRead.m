function [J, SL, SY ] = customRead( caseFile )
%CUSTOMREAD Read function for Neural Network formatting
%   In order to use neural networks optimally, the synthetic data must be
%   organized on a format that the Deep Learning Toolbox would recognize.

load(caseFile,'result');

J  = result.data.Jsparse;
SL = result.data.SL;
SY = result.data.SY;

end


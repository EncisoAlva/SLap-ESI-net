function SLW = customRead_SLwmne( caseFile )
%CUSTOMREAD Read function for Neural Network formatting
%   In order to use neural networks optimally, the synthetic data must be
%   organized on a format that the Deep Learning Toolbox would recognize.

load(caseFile,'result');

%outS = [];
%J  = sparse(result.data.Jsparse);
%SL = result.data.SL;
%SY = result.data.SY;

SLW = [ result.data.SL; full(result.data.J_WMNE)];

end


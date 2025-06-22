function SLSYW = customRead_SLSYwmne( caseFile )
%CUSTOMREAD Read function for Neural Network formatting
%   In order to use neural networks optimally, the synthetic data must be
%   organized on a format that the Deep Learning Toolbox would recognize.

load(caseFile,'result');

%outS = [];
%W  = full(result.data.J_WMNE);
%SL = result.data.SL;
%SY = result.data.SY;

SLSYW = [ result.data.SL; result.data.SY; full(result.data.J_WMNE)];

end


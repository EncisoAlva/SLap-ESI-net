function SLSY = customRead_SLSY( caseFile )
%CUSTOMREAD Read function for Neural Network formatting
%   In order to use neural networks optimally, the synthetic data must be
%   organized on a format that the Deep Learning Toolbox would recognize.

load(caseFile,'result');

%outS = [];
%J  = sparse(result.data.Jsparse);
%SL = result.data.SL;
%SY = result.data.SY;
SLSY = [result.data.SL; result.data.SY];

end


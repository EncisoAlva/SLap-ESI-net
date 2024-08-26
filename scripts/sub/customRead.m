function outS = customRead( caseFile )
%CUSTOMREAD Read function for Neural Network formatting
%   In order to use neural networks optimally, the synthetic data must be
%   organized on a format that the Deep Learning Toolbox would recognize.

load(caseFile,'result');

outS = [];

outS.J  = sparse(result.data.Jsparse);
outS.SL = result.data.SL;
outS.SY = result.data.SY;

end


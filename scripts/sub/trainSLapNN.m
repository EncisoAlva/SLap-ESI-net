function trainSLapNN(info)
% Create neural nwtwrok for the Electrical Source Imaging problem, trained
% from synthetic data

% format as database
switch info.TrainProfiles
  case "all"
    profiles = {'square', 'gauss', 'exp', 'circ'};
  otherwise
    profiles = {info.TrainProfiles};
end

for idxProfile = 1:length(profiles)
  curr_profile = profiles{idxProfile};
  %
  dataStoreTMP = datastore( ...
    strcat( info.basePath,'\data\', info.tagName, '_', curr_profile),...
    "IncludeSubfolders",true, ...
    "Type","file", "ReadFcn", @customRead );
  %
  Q = cell(0);
  counter = 1;
  for ff = 1:length(dataStoreTMP.Files)
    currFile = dataStoreTMP.Files{ff};
    % skip metadata files
    if ( ~contains(currFile,'metadata') ) && ...
        ( ~contains(currFile,'metadata2') ) && ...
        ( ~contains(currFile,'checklist') ) && ...
        ( ~contains(currFile,'evaluation') ) && ...
        ( ~contains(currFile,'params') )
      Q{counter,1} = currFile;
      counter = counter+1;
    end
  end
  dataStoreTMP.Files = Q;
  %
  if idxProfile == 1
    dataStore = dataStoreTMP;
  else
    %dataStore = combine(dataStore, dataStoreTMP, "ReadOrder","sequential");
    dataStore.Files = [dataStore.Files; Q];
  end
end

% split into train and test data
propTrain = info.propTrain;
propTest  = info.propTest;
propValid = 1 -propTrain -propTest;
%
rng(0);
nTrials = numel(dataStore.Files);
shuffleIdx = randperm(nTrials);
%
idxTrain  = sort(shuffleIdx(1:ceil(propTrain*nTrials)));
idxTest   = sort(shuffleIdx(ceil((1-propTest)*nTrials):nTrials));
idxValid  = setdiff((1:nTrials), union(idxTest,idxTrain));
if isempty(idxValid)
  idx = randi(length(idxTrain));
  idxValid = idxTrain(idx);
  idxTrain(idx) = [];
end
%
switch info.NetInput
  case "EEG"
    inFun = @customRead_SY;
  case "SLap"
    inFun = @customRead_SL;
  case "WMNE"
    inFun = @customRead_wmne;
  case "EEG_SLap"
    inFun = @customRead_SLSY;
  case "EEG_WMNE"
    inFun = @customRead_SYwmne;
  case "SLap_WMNE"
    inFun = @customRead_SLwmne;
  case "EEG_SLap_WMNE"
    inFun = @customRead_SLSYwmne;
end
%
dTrain_in  = datastore( dataStore.Files(idxTrain),...
    "Type","file", "ReadFcn", inFun );
dTrain_out = datastore( dataStore.Files(idxTrain),...
    "Type","file", "ReadFcn", @customRead_J );
dTest_in  = datastore( dataStore.Files(idxTest),...
    "Type","file", "ReadFcn", inFun );
dTest_out = datastore( dataStore.Files(idxTest),...
    "Type","file", "ReadFcn", @customRead_J );
%
trainData  = combine(dTrain_in,dTrain_out);
testData   = combine( dTest_in, dTest_out);

% read one file to get the appropriate dimensions
tmpIN  = preview(dTrain_in);
tmpOUT = preview(dTrain_out);

% layers
layers = [...
  inputLayer([size(tmpIN) 1], "CTB") ...
  convolution2dLayer(3,8) ...
  fullyConnectedLayer(512) ...
  fullyConnectedLayer(size(tmpOUT,1)) ...
  ];

%%%% old architecture I used
%layers = [...
%  inputLayer([size(tmpIN) 1], "CTB") ...
%  fullyConnectedLayer(300) ...
%  fullyConnectedLayer(300) ...
%  fullyConnectedLayer(size(tmpOUT,1)) ...
%  ];

% options
opts = trainingOptions( ...
  "sgdm",... % Stoch Grad Descent w/ Momentum
  Plots = "training-progress", ...
  GradientThreshold = 5e2, ...
  MaxEpochs = 2000, ...
  Shuffle = "every-epoch", ...
  OutputNetwork = "best-validation", ...
  InitialLearnRate = 0.01, ...
  LearnRateSchedule = "piecewise", ...
  LearnRateDropPeriod = 25, ...
  LearnRateDropFactor = 0.7, ...
  ValidationData = testData ...
  );
% "sgdm",... % Stoch Grad Descent w/ Momentum
% "adam",... % Adaptive Moment Estimation
%
% ExecutionEnviroment = "parallel-auto" ...

% network training
fprintf("Network inut : %s \n\n",info.NetInput)
%SLnetTrained = trainnet(trainData,layers,"l1loss",opts);
netTrained = trainnet(trainData,layers,"l2loss",opts);
summary(netTrained)

% save network
switch info.TrainProfiles
  case "all"
    trainName = "all";
  otherwise
    trainName = info.TrainProfiles;
end
saveFile = strcat( info.basePath, '\networks\', ...
  "net_", info.tagName, "_", trainName, "_", ...
  info.NetInput,".mat");

save(saveFile,"netTrained");

end

%%

function SY = customRead_SY( caseFile )
%CUSTOMREAD Read function for Neural Network formatting
%   In order to use neural networks optimally, the synthetic data must be
%   organized on a format that the Deep Learning Toolbox would recognize.

load(caseFile,'result');

%outS = [];
%J  = sparse(result.data.Jsparse);
%SL = result.data.SL;
SY = result.data.SY;

end

function SL = customRead_SL( caseFile )
%CUSTOMREAD Read function for Neural Network formatting
%   In order to use neural networks optimally, the synthetic data must be
%   organized on a format that the Deep Learning Toolbox would recognize.

load(caseFile,'result');

%outS = [];
%J  = sparse(result.data.Jsparse);
SL = result.data.SL;
%SY = result.data.SY;

end

function W = customRead_wmne( caseFile )
%CUSTOMREAD Read function for Neural Network formatting
%   In order to use neural networks optimally, the synthetic data must be
%   organized on a format that the Deep Learning Toolbox would recognize.

load(caseFile,'result');

%outS = [];
W  = full(result.data.J_WMNE);
%SL = result.data.SL;
%SY = result.data.SY;

%W = [ result.data.SL; full(result.data.J_WMNE)];

end

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

function SYW = customRead_SYwmne( caseFile )
%CUSTOMREAD Read function for Neural Network formatting
%   In order to use neural networks optimally, the synthetic data must be
%   organized on a format that the Deep Learning Toolbox would recognize.

load(caseFile,'result');

%outS = [];
%W  = full(result.data.J_WMNE);
%SL = result.data.SL;
%SY = result.data.SY;

SYW = [ result.data.SY; full(result.data.J_WMNE)];

end

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

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
  fullyConnectedLayer(300) ...
  fullyConnectedLayer(300) ...
  fullyConnectedLayer(size(tmpOUT,1)) ...
  ];
%layers = [...
%  inputLayer([size(tmpSL) 1], "CTB") ...
%  fullyConnectedLayer(300, WeightsInitializer="ones") ...
%  fullyConnectedLayer(300, WeightsInitializer="ones") ...
%  fullyConnectedLayer(size(tmpJ,1), WeightsInitializer="ones") ...
%  ];

% options
opts = trainingOptions(...
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
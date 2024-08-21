% Round of simulations started on August/13/2024
%
% Source patch has an effective are of 5 cm^2, never p
% laced on the sulci.
%
%

%% GENERAL PARAMETERS
info = [];

% forward model
info.OGforward  = 'asa_10_10_vol_BEM_5k';
info.OGanatomy  = 'icbm152anatomy';
info.OGelec     = 'icbm152_10_10_elec';

info.SourceType = 'volume';

info.nTrials    = 2000;
info.SNRvals    = [Inf, 30, 20];

info.ProtocolFun   = 'Protocol04';
info.tagName       = 'testing';

info.maxDepth  = Inf; % unit: mm
info.maxKappa  = 10*sqrt(10/pi); % unit: mm
info.minKappa  = 10*sqrt(10/pi); % unit: mm

% for vol:  kap = 30.9 mm  ->  A = 30 cm^2
% for srf:  kap = 30.9 mm  ->  A = 30 cm^2

info.debugFigs  = false;

info.debugCent  = false;
info.debugCoord = [47.353, 18.555, 113.019];

info.print_all = false;

info.nLapGrid = 9;

%% 
% Preprocessing for Spline Laplacian
pre_laplace(info);

%% CLOSE BROKEN WAITBARS
F = findall(0,'type','figure','tag','TMWWaitbar');
delete(F)

%%
% variables (may be moved to a function in the future)

% database format
originalPath = pwd;
cd('..')
basePath = pwd;
cd(originalPath)

%%
% Source patch has different profiles:
%     square  Unit source over a circle of radius k
%        exp  ||J_n|| = exp( - dist(n, n*) / 2*k )
%      gauss  ||J_n|| = exp( - dist(n, n*)^2 / 2*k^2 )
%       circ  ||J_n|| = sqrt( 1 - [ dist(n, n*) / k ]^2 )

profiles = {'square', 'gauss', 'exp', 'circ'};

for idxProfile = 1:length(profiles)
  curr_profile = profiles{idxProfile};
  info.BaseName      = [info.tagName, '_', curr_profile];
  info.SourceProfile = curr_profile;
  %
  generator(info);
end

%% training of model

% format as database
for idxProfile = 1:length(profiles)
  curr_profile = profiles{idxProfile};
  %
  dataStoreTMP = datastore( ...
    [ basePath,'\data\', [info.tagName, '_', curr_profile]],...
    "IncludeSubfolders",true, ...
    "Type","file", "ReadFcn", @customRead );
  %
  Q = cell(0);
  counter = 1;
  for ff = 1:length(dataStoreTMP.Files)
    currFile = dataStoreTMP.Files{ff};
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
propTrain = 0.75;
propTest  = 0.15;
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
fileTrain = dataStore.Files(idxTrain);
fileTest  = dataStore.Files(idxTest);
fileValid = dataStore.Files(idxValid);
%
dTrain_J  = datastore( dataStore.Files(idxTrain),...
    "Type","file", "ReadFcn", @customRead_J );
dTrain_SL = datastore( dataStore.Files(idxTrain),...
    "Type","file", "ReadFcn", @customRead_SL );
dTest_J  = datastore( dataStore.Files(idxTest),...
    "Type","file", "ReadFcn", @customRead_J );
dTest_SL = datastore( dataStore.Files(idxTest),...
    "Type","file", "ReadFcn", @customRead_SL );
%
trainData  = combine(dTrain_SL,dTrain_J);
testData   = combine(dTest_SL, dTest_J );

% read one file to get the appropriate dimensions
tmpJ  = preview(dTrain_J);
tmpSL = preview(dTrain_SL);

% layers
layers = [...
  inputLayer([size(tmpSL) 1], "CTB") ...
  fullyConnectedLayer(500) ...
  fullyConnectedLayer(500) ...
  fullyConnectedLayer(size(tmpJ,1)) ...
  ];

% options
opts = trainingOptions(...
  "sgdm",... % Stoch Grad Descent w/ Momentum
  Plots = "training-progress", ...
  MaxEpochs = 100, ...
  Shuffle = "every-epoch", ...
  OutputNetwork = "best-validation", ...
  ValidationData = testData ...
  );

% network training
SLnetTrained = trainnet(trainData,layers,"l1loss",opts);
%netTrained = trainnet(trainData,layers,"l2loss",opts);
summary(SLnetTrained)

%% evaluation
%for idxProfile = 1:length(profiles)
%  curr_profile = profiles{idxProfile};
%  info.BaseName      = [info.tagName, '_', curr_profile];
%  info.SourceProfile = curr_profile;
%  %
%  %generator(info);
%  evaluator(info);
%  collector(info);
%end
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

info.nTrials    = 200;
info.SNRvals    = [Inf, 30, 20, 10];

info.ProtocolFun   = 'Protocol04';
info.tagName       = 'evaluation2408';

info.maxDepth  = Inf; % unit: mm
info.maxKappa  = 10*sqrt( 5/pi); % unit: mm
info.minKappa  = 10*sqrt(15/pi); % unit: mm

% for vol:  kap = 30.9 mm  ->  A = 30 cm^2
% for srf:  kap = 30.9 mm  ->  A = 30 cm^2

info.debugFigs  = false;

info.debugCent  = false;
info.debugCoord = [47.353, 18.555, 113.019];

info.print_all = false;

info.nLapGrid = 10;

%% 
% Preprocessing for Spline Laplacian
% only run one time
pre_laplace(info);

%% CLOSE BROKEN WAITBARS
F = findall(0,'type','figure','tag','TMWWaitbar');
delete(F)

%%
% variables (may be moved to a function in the future)

% database format
originalPath = pwd;
cd('..')
info.basePath = pwd;
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
  % only run one time
  generator(info);
end

for idxProfile = 1:length(profiles)
  curr_profile = profiles{idxProfile};
  info.BaseName      = [info.tagName, '_', curr_profile];
  info.SourceProfile = curr_profile;
  %
  evaluator(info);
  collector(info);
end
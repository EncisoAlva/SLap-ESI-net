function pars = SLapESInet_gral_tune( ~, info, ~, opts )
% TODO add description (optional)
%

% start timer
parTic = tic;
pars   = [];

% load surface laplacian data
load(strcat(info.basePath,'\anat_ref\', ...
  'SLap_',info.OGanatomy,'_',info.OGelec,".mat"), "lap");
pars.lap = lap;

load(strcat(info.basePath,'\networks\', ...
  'net_testing_','all_', opts.NetInput,".mat"), "netTrained");
pars.network = netTrained;

% stop timer
pars.parTime = toc(parTic);

% print the results nicely
fprintf("Network loaded: %s", strcat('net_testing_','all_', opts.NetInput,".mat"))
fprintf("\n")

end
function pars = SLapESInet_gral_tune( meta, info, result, opts )
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

% find regularization for WMNE using U-curve
best_alpha = median(meta.S(:));
alphas = best_alpha*( 2.^(-50:50) );
Us     = zeros( size(alphas) );
for q = 1:length(alphas)
  alpha = alphas(q);
  %
  K = meta.LeadfieldColNorm' * pinv( eye(meta.nChans) * alpha + meta.LeadfieldColNorm * meta.LeadfieldColNorm' );
  % solution
  J = K * (result.data.Y) ./(meta.ColumnNorm');
  % residual
  R = vecnorm( meta.Leadfield*J - result.data.Y, 2 )^2;
  % norm
  N = vecnorm( J, 2 )^2;
  % U-curve
  Us(q) = 1/R + 1/N;
end
[~, idx]   = min(Us);
best_alpha = max(alphas(idx), .001);
pars.alpha = best_alpha;
%
pars.kernel = meta.LeadfieldColNorm' * ...
  pinv( eye(meta.nChans) * best_alpha + meta.LeadfieldColNorm * meta.LeadfieldColNorm' );
%J = K * (result.data.Y) ./(meta.ColumnNorm');
%maxJ = max(abs(J(:)));
%J(abs(J)<0.1*maxJ) = 0;

% stop timer
pars.parTime = toc(parTic);

% print the results nicely
fprintf("Network loaded: %s", strcat('net_testing_','all_', opts.NetInput,".mat"))
fprintf("\n")

end
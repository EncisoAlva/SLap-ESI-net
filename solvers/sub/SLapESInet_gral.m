function solution = SLapESInet_gral( meta, ~, result, pars, opts )
% TODO add description (optional)
%
solution = [];

% solution per se
parTic = tic;

% for later
switch opts.NetInput
  case {"WMNE", "EEG_WMNE", "SLap_WMNE", "EEG_SLap_WMNE"}
    % compute WMNE solution
    J_WMNE = pars.kernel * (result.data.Y) ./(meta.ColumnNorm');
    maxJ = max(abs(JJ_WMNE(:)));
    J_WMNE(abs(J)<0.1*maxJ) = 0;
    %J_WMNE = sparse(J);
  otherwise
    % do nothing
end

switch opts.NetInput
  case "EEG"
    input = pars.lap.S * result.data.Y;
  case "SLap"
    input = pars.lap.L * result.data.Y;
  case "WMNE"
    input = J_WMNE;
  case "EEG_SLap"
    input = [...
      pars.lap.L * result.data.Y; ...
      pars.lap.S * result.data.Y ];
  case "EEG_WMNE"
    input = [...
      pars.lap.S * result.data.Y; ...
      J_WMNE];
  case "SLap_WMNE"
    input = [...
      pars.lap.L * result.data.Y; ...
      J_WMNE];
  case "EEG_SLap_WMNE"
    input = [...
      pars.lap.L * result.data.Y; ...
      pars.lap.S * result.data.Y; ...
      J_WMNE];
end

% solution per se
solution.J = predict(pars.network, input);
if size(solution.J, 2)~=1
  % if incrrect orientation
  solution.J = solution.J';
end
solution.algTime = toc(parTic);

% norm of J
switch meta.Type
  case 'surface'
    solution.normJ = abs( solution.J );
  case 'volume'
    solution.normJ = dip_norm( solution.J );
end

% stop timer
solution.algTime = toc(parTic);

end


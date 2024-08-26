function solution = SLapESInet_EEG( meta, ~, result, pars )
% TODO add description (optional)
%
opts = [];
opts.NetInput = "EEG";

solution = SLapESInet_gral( meta, [], result, pars, opts );

end


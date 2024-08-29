function solution = SLapESInet_EEG_SLap( meta, ~, result, pars )
% TODO add description (optional)
%
opts = [];
opts.NetInput = "EEG_SLap";

solution = SLapESInet_gral( meta, [], result, pars, opts );

end


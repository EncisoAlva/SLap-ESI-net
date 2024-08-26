function solution = SLapESInet_EEG_SLap_WMNE( meta, ~, result, pars )
% TODO add description (optional)
%
opts = [];
opts.NetInput = "EEG_SLap_WMNE";

solution = SLapESInet_gral( meta, [], result, pars, opts );

end


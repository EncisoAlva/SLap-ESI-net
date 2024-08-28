function pars = SLapESInet_EEG_SLap_tune( meta, info, result )
% TODO add description (optional)
%

opts = [];

opts.NetInput = "EEG_SLap";

pars = SLapESInet_gral_tune( meta, info, result, opts );

end
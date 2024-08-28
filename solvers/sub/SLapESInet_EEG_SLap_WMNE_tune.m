function pars = SLapESInet_EEG_SLap_WMNE_tune( meta, info, result )
% TODO add description (optional)
%

opts = [];

opts.NetInput = "EEG_SLap_WMNE";

pars = SLapESInet_gral_tune( meta, info, result, opts );

end
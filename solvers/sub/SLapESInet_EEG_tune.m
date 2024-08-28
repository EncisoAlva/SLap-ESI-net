function pars = SLapESInet_EEG_tune( meta, info, result )
% TODO add description (optional)
%

opts = [];

opts.NetInput = "EEG";

pars = SLapESInet_gral_tune( meta, info, result, opts );

end
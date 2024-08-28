function pars = SLapESInet_SLap_tune( meta, info, result )
% TODO add description (optional)
%

opts = [];

opts.NetInput = "SLap";

pars = SLapESInet_gral_tune( meta, info, result, opts );

end
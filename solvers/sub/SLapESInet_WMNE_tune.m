function pars = SLapESInet_WMNE_tune( meta, info, result )
% TODO add description (optional)
%

opts = [];

opts.NetInput = "WMNE";

pars = SLapESInet_gral_tune( meta, info, result, opts );

end
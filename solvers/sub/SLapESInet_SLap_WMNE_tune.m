function pars = SLapESInet_SLap_WMNE_tune( ~, info, ~ )
% TODO add description (optional)
%

opts = [];

opts.NetInput = "SLap_WMNE";

pars = SLapESInet_gral_tune( [], info, [], opts );

end
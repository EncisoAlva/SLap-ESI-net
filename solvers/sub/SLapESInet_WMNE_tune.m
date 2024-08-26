function pars = SLapESInet_WMNE_tune( ~, info, ~ )
% TODO add description (optional)
%

opts = [];

opts.NetInput = "WMNE";

pars = SLapESInet_gral_tune( [], info, [], opts );

end
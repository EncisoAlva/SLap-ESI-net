function pars = SLapESInet_EEG_WMNE_tune( ~, info, ~ )
% TODO add description (optional)
%

opts = [];

opts.NetInput = "EEG_WMNE";

pars = SLapESInet_gral_tune( [], info, [], opts );

end
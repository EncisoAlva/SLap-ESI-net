function pars = SLapESInet_EEG_SLap_WMNE_tune( ~, info, ~ )
% TODO add description (optional)
%

opts = [];

opts.NetInput = "EEG_SLap_WMNE";

pars = SLapESInet_gral_tune( [], info, [], opts );

end
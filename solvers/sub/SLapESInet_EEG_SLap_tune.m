function pars = SLapESInet_EEG_SLap_tune( ~, info, ~ )
% TODO add description (optional)
%

opts = [];

opts.NetInput = "EEG_SLap";

pars = SLapESInet_gral_tune( [], info, [], opts );

end
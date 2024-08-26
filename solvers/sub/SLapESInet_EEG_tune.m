function pars = SLapESInet_EEG_tune( ~, info, ~ )
% TODO add description (optional)
%

opts = [];

opts.NetInput = "EEG";

pars = SLapESInet_gral_tune( [], info, [], opts );

end
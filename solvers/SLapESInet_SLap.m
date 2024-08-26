function solution = SLapESInet_SLap( meta, ~, result, pars )
% TODO add description (optional)
%
opts = [];
opts.NetInput = "SLap";

solution = SLapESInet_gral( meta, [], result, pars, opts );

end


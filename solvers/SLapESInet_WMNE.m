function solution = SLapESInet_WMNE( meta, ~, result, pars )
% TODO add description (optional)
%
opts = [];
opts.NetInput = "WMNE";

solution = SLapESInet_gral( meta, [], result, pars, opts );

end


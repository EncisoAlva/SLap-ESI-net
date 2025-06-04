%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% sphlap_interp.m - Auxiliar function to compute spherical splines on some
%     points in a mesh (not the electrode locations)
%
% Usage: [K, LapK ] = sphlap0_interp(x0, y0, z0, x, y, z, m, max_n, tol);
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Required Inputs
%   x0, y0, z0   electrode coordinates (must be on a sphere)
%      x, y, z   mesh coordinates (must be on a sphere)
%            m   interpolation order (2<=m<=6)
% Optional Input
%         tol   error tolerance in the estimate of the Legendre 
%              polynomials. Default is 1e-10.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Output
% K, LapK, T, Q1, Q2, R   matrices required to implement spherical splines
%

%% CHANGES
% This new function is used to compute the interpolation and laplacian over
% a mesh whose points may be different from electrode locations.
%
% Modified by Enciso-Alva, JC (2024)

%% CREDIT ( ORIGINAL ALGORITHM )
% Claudio Carvalhaes, J. Acacio de Barros,
% The surface Laplacian technique in EEG: Theory and methods,
% International Journal of Psychophysiology,
% Volume 97, Issue 3,
% 2015,
% Pages 174-188,
% ISSN 0167-8760,
% https://doi.org/10.1016/j.ijpsycho.2015.04.023.

function [K, LapK ] = sphlap0_interp(xyz0_, xyz_, m, max_n)

% Handle arguments
if m < 2 || m > 6
  error('sphlap0:intorder',...
    'The parameter "m" should be in the range of %s.',...
    '2 and 6');
end

% transpose if needed
if size(xyz_,2) ~= 3
  xyz = xyz_';
else
  xyz = xyz_;
end
if size(xyz0_,2) ~= 3
  xyz0 = xyz0_';
else
  xyz0 = xyz0_;
end

r  = hypot(xyz(:,3), hypot(xyz(:,1), xyz(:,2))); % head radius
N  = size(xyz, 1);  % number of electrodes
N0 = size(xyz0, 1); % number of mesh points

sqdist = pdist2(xyz, xyz0, 'euclidean').^2;
r2  = r(1)^2; % squared head radius
cos_gamma = 1 - sqdist/(2*r2); % angle between electrodes

if any ((cos_gamma(:) > 1) | (cos_gamma (:) < -1)) 
  error('sphlap0:locs', ...
    'Something is wrong with the electrode coordinates. %s', ...
    'Are they on located on a sphere?');
end

G    = []; 
LapG = [];
G0   = 0;

for n = 1:max_n
  Pn = legendre(n, cos_gamma(:));
  a  = (2*n+1) / (n*(n+1))^m;
  gm = a * Pn(end,:)';
  G  = horzcat(G, gm);
  LapG = horzcat(LapG, -n* (n+1)* gm);
  %epsilon = max(abs( G(:,end)-G0 ));
  %G0 = G(:,end);
end

%tol = epsilon; % final error tolerance

K = reshape( sum(G,2), N, N0)/(4*pi);
LapK = reshape( sum(LapG,2), N, N0) / (4*pi*r2); 

end
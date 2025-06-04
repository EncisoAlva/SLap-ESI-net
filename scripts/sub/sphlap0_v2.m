%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% sphlap0.m - Auxiliar function to compute spherical splines
%
% Usage: [K, LapK, T, Q1, Q2, R] = sphlap0(xyz, m, tol);
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Required Inputs
%        xyz   electrode coordinates (must be on a sphere)
%          m   interpolation order (2<=m<=6)
% Optional Input
%        tol   error tolerance in the estimate of the Legendre 
%              polynomials. Default is 1e-10.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Output
% K, LapK, T, Q1, Q2, R   matrices required to implement spherical splines
%

%% CREDIT
% Claudio Carvalhaes, J. Acacio de Barros,
% The surface Laplacian technique in EEG: Theory and methods,
% International Journal of Psychophysiology,
% Volume 97, Issue 3,
% 2015,
% Pages 174-188,
% ISSN 0167-8760,
% https://doi.org/10.1016/j.ijpsycho.2015.04.023.

%% CHANGES
% 2024-Aug  The max order of Legendre polynomial is part of the output.
% 2024-Aug  The input is a Nx3 matrix, instead of 3 Nx1 matrices.
%           Modification by Enciso-Alva.

function [mat_g, mat_gLap, T, Q1, Q2, R, max_n, tol] = sphlap0_v2(xyz_, m, tol)

% Handle arguments
if nargin < 2
  help sphlap0.m;
  return;
end
if nargin == 2
  tol = 1e-10;
end
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

r = hypot(xyz(:,3), hypot(xyz(:,1), xyz(:,2))); % head radius
N = size(xyz, 1); % number of electrodes

sqdist = pdist(xyz, 'euclidean').^2; % square distances between electrodes
dr2 =  squareform(sqdist); % convert distances to matrix form
r2  = r(1)^2; % squared head radius
cos_gamma = 1 - dr2/(2*r2); % angle between electrodes

if any ((cos_gamma(:) > 1) | (cos_gamma (:) < -1)) 
  error('sphlap0:locs', ...
    'Something is wrong with the electrode coordinates. %s', ...
    'Are they on located on a sphere?');
end

G    = []; 
LapG = [];
G0   = 0;
epsilon = tol + 1;

n = 1;
while (tol < epsilon)&&(n<8)
  Pn = legendre(n, cos_gamma(:));
  a  = (2*n+1) / (n*(n+1))^m;
  gm = a * Pn(end,:)';
  G  = horzcat(G, gm);
  LapG = horzcat(LapG, -n* (n+1)* gm);
  %epsilon = max(abs( G(:,end)-G0 ))
  epsilon = max(abs( G(:,end) ));
  G0 = G(:,end);
  n = n + 1;
end
max_n = n-1;

tol = epsilon; % final error tolerance

mat_g    = reshape( sum(G,2), N, [])/(4*pi);
mat_gLap = reshape( sum(LapG,2), N, []) / (4*pi*r2); 
T = ones(N,1);

% QR decomposition of T
[Q, R] = qr(T);
R  = R(1);
Q1 = Q(:,1);
Q2 = Q(:,2:N);

% Alternative
% R  = -sqrt(N);
% Q1 = T / R;
% [U,~,~] = svd(T);
% Q2 = U(:,2:end);

end
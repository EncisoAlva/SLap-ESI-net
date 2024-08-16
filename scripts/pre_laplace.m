function pre_laplace(info)
% This function takes the subject's anatomy and do the followng:
%  1. Fit a sphere on the subject's head, projecting the electrodes on it.
%  2. Construct matrices S, L so that
%       EEG_fitted = S * EEG
%        SL_fitted = L * EEG
%
% S, L are constructed using the algorithm by Carvalhae and Barros (2015).
% The surface Laplacian technique in EEG: Theory and methods. 
% https://doi.org/10.1016/j.ijpsycho.2015.04.023.
%
%-------------------------------------------------------------------------
% Author: Julio Cesar Enciso-Alva (2024)
%         juliocesar.encisoalva@mavs.uta.edu
%

counter = 0;
f = waitbar(counter,'Computing general parameters, including SVD of leadfield matrix',...
  'Name','Computing synthetic data',...
  'CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
setappdata(f,'canceling',0);

%% SETUP + LOAD DATA

scriptsPath = pwd;
addpath( scriptsPath, [scriptsPath,'\sub'] )
cd('..')
basePath  = pwd;
cd('.\anat_ref')

% forward model
load([ basePath,'\anat_ref\', info.OGelec, '.mat'],'electrodes');

% metadata
lap = [];

lap.Elec  = electrodes.Channel;
lap.nElec = size( lap.Elec, 2 );

%% 1. SPHERICAL PROJECTION

lap.OGpos = zeros( lap.nElec, 3 );
for i = 1:lap.nElec
  lap.OGpos(i,:) = lap.Elec(i).Loc'*1000;
end

% initialization
ctr_old = mean(lap.OGpos,1);
rad_old = median( vecnorm(lap.OGpos-ctr_old, 2, 2) );
err_old = mean(abs( vecnorm(lap.OGpos-ctr_old, 2, 2)-rad_old ));

% loop for getting a better center
for scale = -10:10
  fprintf('Step %i / 10\n \n', scale)
  for idx = 1:10000
    ctr_new = ctr_old + normrnd(0,rad_old*2^(-scale), 1,3);
    rad_new = median( vecnorm(lap.OGpos-ctr_new, 2, 2) );
    err_new = mean(abs( vecnorm(lap.OGpos-ctr_new, 2, 2)-rad_new ));
    if err_new < err_old
      ctr_old = ctr_new;
      rad_old = rad_new;
      err_old = err_new;
      fprintf('Avg. error: %2.7f ;  Id : %i \n', err_old, idx)
    end
  end
end
lap.SPHcenter = ctr_old;
lap.SPHradius = rad_old;

% projecting electrodes into the sphere
lap.SPHpos  = zeros( lap.nElec, 3 );
lap.SPHpos0 = zeros( lap.nElec, 3 );
for i = 1:lap.nElec
  vec_tmp = lap.OGpos(i,:) - lap.SPHcenter;
  lap.SPHpos0(i,:) = vec_tmp * lap.SPHradius/norm(vec_tmp);
  lap.SPHpos(i,:)  = lap.SPHpos0(i,:) + lap.SPHcenter;
end

% new points on a 'good' mesh
% TEMPORARY: using an icosahedron instead of a 9x9 grid
icos = [ 
 1.000000,  0.000000, -0.618034 ; 
 1.000000, -0.000000,  0.618034 ; 
-1.000000, -0.000000,  0.618034 ; 
-1.000000,  0.000000, -0.618034 ; 
 0.000000, -0.618034,  1.000000 ; 
 0.000000,  0.618034,  1.000000 ; 
 0.000000,  0.618034, -1.000000 ; 
 0.000000, -0.618034, -1.000000 ; 
-0.618034, -1.000000, -0.000000 ; 
 0.618034, -1.000000, -0.000000 ; 
 0.618034,  1.000000,  0.000000 ; 
-0.618034,  1.000000,  0.000000 ; 
];
tmp = vecnorm(icos,2,2);
lap.MESHpos0 = lap.SPHradius*icos / tmp(1);
lap.MESHpos  = lap.SPHcenter + lap.MESHpos0;

if info.debugFigs
  figure()
  scatter3(lap.OGpos(:,1), lap.OGpos(:,2), lap.OGpos(:,3), "filled")
  hold on
  scatter3(lap.SPHpos(:,1), lap.SPHpos(:,2), lap.SPHpos(:,3), "filled")
  scatter3(lap.MESHpos(:,1), lap.MESHpos(:,2), lap.MESHpos(:,3), "filled")
  xlabel('1: Anterior->Posterior [mm]')
  ylabel('2: Right->Left [mm]')
  zlabel('3: Inferior->Superior [mm]')
  legend({'Electrode Positions (original)', ...
          'Electrode Positions (projected)', 'Spherical Grid'}, ...
          "Location","south")
end

%% 2. SPLINE LAPLACIAN

% interpolation of splines from electrode positions
[K_0, LapK_0, T, Q1, Q2, R, max_n, ~] = sphlap0( lap.SPHpos0, 4, 1e-10);

[K_F, LapK_f ] = sphlap_interp( lap.SPHpos0, lap.MESHpos0, 4, max_n);

[S, L] = sphlap (K, LapK, T, Q1, Q2, R, 1);

lap.S = S;
lap.L = L;

save(['SLap_',info.OGanatomy,'_',info.OGelec],"lap", "-v7.3");

end
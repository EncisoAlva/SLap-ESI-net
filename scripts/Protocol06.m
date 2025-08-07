% This script creates a single trials of synthetic data according to 
% protocol in the ConvDip Paper:
%  > Constrained dipoles at brain cortex
%  > One single active dipole (given)
%  > Sample freq = 15 Hz [actually irrelevant, only 1 point is used]
%  > Sample window = 1/15 sec, ie one single timepoint
%  > Total points: 1
%  > Signal: [Deprecated for the moment]
%  > Added noise on sensors with prescribed SNR (given)
%
% Author: Julio C Enciso-Alva (2025)
%         juliocesar.encisoalva@mavs.uta.edu
%
function RES = Protocol06( meta, result, info )

RES = [];

% shared container
%normJ_shared = zeros(meta.nGridDips,1);
switch info.SourceType
  case 'volume'
    J_shared = zeros(meta.nGridDips*3,1);
  case 'surface'
    J_shared = zeros(meta.nGridDips  ,1);
end

% same process for all patches, whatever number of them there are
for idxPatch = 1:result.nPatches

% optional: only consider sources with magnitude > 5%
% the maximal draw distance depend on the profile
kappa = result.kappa(idxPatch);
switch info.SourceProfile
  case 'square'
    maxDist = kappa;
  case 'exp'
    maxDist = 3.00*kappa;
  case 'gauss'
    maxDist = 2.45*kappa;
  case 'circ'
    maxDist = kappa;
end
% prepare a short list of dipoles within the draw distance
idx = 1:meta.nGridDips;
idxShort = idx( vecnorm( meta.Gridloc - result.IntendedCent(idxPatch,:), 2, 2 ) < maxDist );
nShort   = length( idxShort );
switch info.SourceType
  case 'volume'
    Distance = vecnorm( meta.Gridloc(idxShort,:) - result.IntendedCent(idxPatch,:), 2, 2 );
  case 'surface'
    [~,GraphDist] = shortestpathtree(meta.asGraph, result.idxCent(idxPatch), idxShort );
    Distance = GraphDist;
end

%fprintf('Distance is ok')

% J, shortened to non-zero dipoles
RES.time   = linspace(0,0,1);
normJshort = zeros(nShort,1);
switch info.SourceProfile
  case 'square'
    normJshort( Distance < kappa ) = 1;
  case 'exp'
    normJshort = exp(- Distance /kappa);
  case 'gauss'
    normJshort = exp(-( Distance ).^2/(2*(kappa^2)));
  case 'circ'
    normJshort = ( 1 - min( Distance /kappa,1 ).^2 ).^(1/2);
end
normJshort( normJshort < max(abs( normJshort ))*0.05 ) = 0; % sparse enforce
normJshort = normJshort / sqrt(sum( normJshort.^2 ));

% inflate and make sparse (for storage)
normJ = zeros(meta.nGridDips,1);
normJ(idxShort) = normJshort;
%RES.normJsparse = sparse(normJ);

switch info.SourceType
  case 'volume'
    J = kron(normJ, result.Orient(idxPatch,:)');
  case 'surface'
    J = normJshort*result.Orient(idxPatch);
end
%RES.Jsparse = sparse(J);

J_shared = J_shared + J;

end

% order output in desired format
switch info.SourceType
  case 'volume'
    J_shared_vec = reshape( J_shared, [3, meta.nGridDips] );
    normJ_shared = vecnorm( J_shared_vec, 3, 1);
  case 'surface'
    normJ_shared = abs( J_shared );
end

RES.normJsparse = sparse(normJ_shared);
RES.Jsparse     = sparse(    J_shared);

% Y, noiseless
RES.Yclean = meta.Leadfield * J;
RES.varY   = RES.Yclean.^2;

% adding noise to a prescribed SNR
if isinf(result.SNR)
  noise = zeros( size(RES.Yclean) );
else
  noise = normrnd(0, 1, size(RES.Yclean) );
end

% Y
RES.YOG = RES.Yclean + 10^(-result.SNR/10) * diag( RES.varY ) * noise;
RES.Y   = RES.YOG - mean(RES.YOG,1); % average re-referencing

% true center of mass
RES.TrueCent = normJ' * meta.Gridloc / sum(normJ);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function DebugPlotIndendedCenter(meta, info, RES)
% only the source patch 'center'
figure()

 % cortex surface
trisurf(meta.Cortex.Faces, ...
  meta.Cortex.Vertices(:,1), meta.Cortex.Vertices(:,2), meta.Cortex.Vertices(:,3), ...
  'FaceColor', [1,1,1]*153/255, ...
  'EdgeColor', ...
  'none', 'FaceAlpha', 0.75 )
hold on

% true center in red
scatter3(result.IntendedCent(1), result.IntendedCent(2), result.IntendedCent(3), ...
  30, 'red','filled')
legend({'','Seed dipole, $n^*$'}, 'Interpreter', 'latex')
legend boxoff
  
% change view BEFORE adding light
view([ 90  90]) % top
camlight('headlight','infinite')
material dull
grid off
set(gca,'DataAspectRatio',[1 1 1])
  
% remove grids and box
set(gca,'XColor', 'none','YColor','none','ZColor','none')
set(gca, 'color', 'none');
set(gcf,'color','w');
set(gca,'LooseInset',get(gca,'TightInset'))
%fig = gcf;
%fig.Units = 'inches';
%fig.OuterPosition = [0 0 3 3];
%exportgraphics(gcf,[info.SourceProfile, '_center.pdf'],'Resolution',600)

end

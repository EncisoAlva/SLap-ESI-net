% This script creates a single trials of synthetic data according to 
% protocol in the Multiple Source Preallocation Paper:
%  > Constrained dipoles at brain cortex
%  > One single active dipole (given)
%  > Sample freq = 15 Hz [actually irrelevant]
%  > Sample window = 1/15 sec, ie one single timepoint
%  > Total points: 1
%  > Signal: [Deprecated for the moment]
%  > Added noise on sensors with prescribed SNR (given)
%
% Author: Julio C Enciso-Alva (2025)
%         juliocesar.encisoalva@mavs.uta.edu
%
function RES = Protocol05( meta, result, info )

RES = [];

% optional: only consider sources with magnitude > 5%
% the maximal draw distance depend on the profile
switch info.SourceProfile
  case 'square'
    maxDist = result.kappa;
  case 'exp'
    maxDist = 4.61*result.kappa;
  case 'gauss'
    maxDist = 2.15*result.kappa;
  case 'circ'
    maxDist = result.kappa;
end
% prepare a short list of dipoles within the draw distance
idx = 1:meta.nGridDips;
idxShort = idx( vecnorm( meta.Gridloc - result.IntendedCent, 2, 2 ) < maxDist );
nShort   = length( idxShort );
%idxCentShort = find(result.idxCent == idxShort,1);
%if isempty(idxCentShort)
%  [~,idxCentShort] = min(vecnorm( meta.Gridloc(idxShort,:) - result.IntendedCent, 2, 2));
%end
switch info.SourceType
  case 'volume'
    Distance = vecnorm( meta.Gridloc(idxShort,:) - result.IntendedCent, 2, 2 );
  case 'surface'
    [~,GraphDist] = shortestpathtree(meta.asGraph, result.idxCent, idxShort );
    Distance = GraphDist;
end

%fprintf('Distance is ok')

% J, shortened to non-zero dipoles
RES.time       = linspace(0,0,1);
normJshort = zeros(nShort,1);
switch info.SourceProfile
  case 'square'
    normJshort( Distance < result.kappa ) = 1;
  case 'exp'
    normJshort = exp(- Distance /result.kappa);
  case 'gauss'
    normJshort = exp(-( Distance ).^2/(2*(result.kappa^2)));
  case 'circ'
    normJshort = ( 1 - min( Distance /result.kappa,1 ).^2 ).^(1/2);
end
normJshort( normJshort < max(abs( normJshort ))*0.05 ) = 0; % sparse enforce
normJshort = normJshort / sqrt(sum( normJshort.^2 ));

% inflate and make sparse (for storage)
normJ = zeros(meta.nGridDips,1);
normJ(idxShort) = normJshort;
RES.normJsparse = sparse(normJ);

%fprintf('normJsparse is ok')

% add chosen orientation if it is a volume source
switch info.SourceType
  case 'volume'
    J = zeros(meta.nGridDips*3,1);
    tmp = (idxShort-1)*3 + [1,2,3]';
    J(sort(tmp(:))) = kron(normJshort, result.Orient');
  case 'surface'
    J = zeros(meta.nGridDips  ,1);
    J(idxShort) = normJshort;
end
RES.Jsparse = sparse(J);

%fprintf('Jsparse is ok')

% Y, noiseless
RES.Yclean = meta.Leadfield * J;
RES.varY   = RES.Yclean.^2;

%fprintf('Yclean is ok')

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

function DebugPlotTrueSourceDistribution(meta, info, RES)
% source patch distribution
figure()

J = full(RES.Jsparse);
trisurf(meta.Cortex.Faces, ...
  meta.Cortex.Vertices(:,1), meta.Cortex.Vertices(:,2), meta.Cortex.Vertices(:,3), ...
  'FaceColor', [1,1,1]*153/255, ...
  'EdgeColor', ...
  'none', 'FaceAlpha', 1 )
view([ 90  90]) % top
camlight('headlight', 'infinite')
material dull
  
% plot source distribution
hold on
trisurf(meta.Cortex.Faces, ...
  meta.Cortex.Vertices(:,1), meta.Cortex.Vertices(:,2), meta.Cortex.Vertices(:,3), ...
  'FaceColor', 'interp', ...
  'FaceVertexCData', abs(J), ...
  'EdgeColor', 'none', ...
  'FaceAlpha', 'interp', ...
  'FaceVertexAlphaData', 1*(abs(J)>0.05*max(abs(J(:)))) )
material dull
%colormap("turbo")
colormap("parula")
clim([0,1])
  
% remove grids and stuff
grid off
set(gca,'DataAspectRatio',[1 1 1])
set(gca,'XColor', 'none','YColor','none','ZColor','none')
set(gca, 'color', 'none');
set(gcf,'color','w');
set(gca,'LooseInset',get(gca,'TightInset'))
  
% labels
switch info.SourceProfile
  case 'square'
    title('Square profile')
  case 'exp'
    title('Exponential profile')
  case 'gauss'
    title('Gaussian profile')
  case 'circ'
    title('Polynomial profile')
end
  
% configure for export
%fig = gcf;
%fig.Units = 'inches';
%fig.OuterPosition = [0 0 3 3];
%exportgraphics(gcf,[info.SourceProfile, '_GroundTruth.pdf'],'Resolution',600)
end

function DebugPlotTrueProfile(meta, info, RES)
% PROFILE GRAPH
figure()
fig = tiledlayout(1,1,'Padding','tight');
nexttile

% optional: only consider sources with magnitude > 5%
% the maximal draw distance depend on the profile
switch info.SourceProfile
  case 'square'
    maxDist = result.kappa;
  case 'exp'
    maxDist = 4.61*result.kappa;
  case 'gauss'
    maxDist = 2.15*result.kappa;
  case 'circ'
    maxDist = result.kappa;
end

% prepare a short list of dipoles within the draw distance
idx = 1:meta.nGridDips;
idxShort = idx( vecnorm( meta.Gridloc - result.IntendedCent, 2, 2 ) < maxDist );
switch info.SourceType
  case 'volume'
    Distance = vecnorm( meta.Gridloc(idxShort,:) - result.IntendedCent, 2, 2 );
  case 'surface'
    [~,GraphDist] = shortestpathtree(meta.asGraph, result.idxCent, idxShort );
    Distance = GraphDist;
end

% load source patch information
J = full(RES.Jsparse);
normJ2 = abs( J(idxShort) ).^2;

% geodesic distance in cortex
scatter( Distance, normJ2, "filled" )
  
% labels
switch info.SourceProfile
  case 'square'
    title('Square profile')
  case 'exp'
    title('Exponential profile')
  case 'gauss'
    title('Gaussian profile')
  case 'circ'
    title('Polynomial profile')
end
xlabel('dist$(\mathbf{r}_n, \mathbf{r}_{n^*})$ [mm]','Interpreter','latex')
ylabel('$\Vert \mathbf{J} \Vert^2_2$', 'Interpreter','latex')
xlim([0, 30])
ylim([0,1])
  
% add grid
grid on
set(gcf,'color','w');

% configure for export
%fig.Units = 'inches';
%fig.OuterPosition = [0 0 3 3];
%exportgraphics(gcf,[info.SourceProfile, '_Profile.pdf'],'Resolution',600)
end
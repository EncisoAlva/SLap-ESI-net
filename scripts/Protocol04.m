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
function RES = Protocol04( meta, result, info )

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
idx = 1:size(meta.Leadfield, 2);
RES.idxShort0  = idx( vecnorm( meta.Gridloc - result.IntendedCent, 2, 2 ) < maxDist );
RES.nShort    = length( RES.idxShort0 );
RES.idxCentShort = find(result.idxCent == RES.idxShort0,1);
if isempty(RES.idxCentShort)
  [~,RES.idxCentShort] = min(vecnorm( meta.Gridloc(RES.idxShort0,:) - result.IntendedCent, 2, 2));
end

% surface distance
switch info.SourceType
  case 'volume'
    RES.idxShort   = RES.idxShort0;
  case 'surface'
    [~,GraphDist0] = shortestpathtree(meta.asGraph, result.idxCent, RES.idxShort0 );
    RES.idxShort   = RES.idxShort0( GraphDist0 < maxDist );
    RES.idxShort0  = [];
    RES.nShort     = length( RES.idxShort );
    RES.idxCentShort = find(result.idxCent == RES.idxShort,1);
    if isempty(RES.idxCentShort)
      [~,RES.idxCentShort] = min(vecnorm( meta.Gridloc(RES.idxShort,:) - result.IntendedCent, 2, 2));
    end
    [~,GraphDist] = shortestpathtree(meta.asGraph, result.idxCent, RES.idxShort );
end

% miscellanea
switch info.SourceType
  case 'volume'
    tmp = (RES.idxShort-1)*3 + [1,2,3]';
    RES.idxShortG = sort(tmp(:));
  case 'surface'
    RES.idxShortG = RES.idxShort;
end

% J, shortened to non-zero dipoles
RES.time       = linspace(0,0,1);
RES.normJshort = zeros(RES.nShort,1);
switch info.SourceType
  case 'volume'
    RES.Jshort = zeros(RES.nShort*3,1);
  case 'surface'
    RES.Jshort = zeros(RES.nShort,  1);
end
switch info.SourceProfile
  case 'square'
    switch info.SourceType
      case 'surface'
        % geodesic distance in cortex
        for ii = 1:RES.nShort
          if GraphDist(ii) < result.kappa
            RES.normJshort(ii) = 1;
          end
        end
        RES.Jshort = RES.normJshort;
      case 'volume'
        % euclidian distance in 3D space
        for ii = 1:RES.nShort
          idx = RES.idxShort(ii); 
          if vecnorm( meta.Gridloc(idx,:) - result.IntendedCent, 2, 2 ) < result.kappa
            RES.normJshort(ii) = 1;
          end
        end
        RES.Jshort = kron(RES.normJshort, [1,1,1]');
    end
  case 'exp'
    switch info.SourceType
      case 'surface'
        RES.normJshort = exp(- GraphDist /result.kappa);
        RES.Jshort = RES.normJshort;
      case 'volume'
        RES.normJshort = exp(-vecnorm( meta.Gridloc(RES.idxShort,:) - result.IntendedCent, 2, 2 )/result.kappa);
        RES.Jshort = kron(RES.normJshort, [1,1,1]');
    end
  case 'gauss'
    switch info.SourceType
      case 'surface'
        RES.normJshort = exp(-( GraphDist ).^2/(2*(result.kappa^2)));
        RES.Jshort = RES.normJshort;
      case 'volume'
        RES.normJshort = exp(-vecnorm( meta.Gridloc(RES.idxShort,:) - result.IntendedCent, 2, 2 ).^2/(2*(result.kappa^2)));
        RES.Jshort = kron(RES.normJshort, [1,1,1]');
    end
  case 'circ'
    switch info.SourceType
      case 'surface'
        RES.normJshort = ( 1 - min( GraphDist /result.kappa,1 ).^2 ).^(1/2);
        RES.Jshort = RES.normJshort;
      case 'volume'
        RES.normJshort = ( 1 - ...
          min( vecnorm( meta.Gridloc(RES.idxShort,:) - result.IntendedCent, 2, 2 ) /result.kappa,1 ).^2 ).^(1/2);
        RES.Jshort = kron(RES.normJshort, [1,1,1]');
    end
end

% debug figures
if info.debugFigs
  % TRUE CENTER
  figure()
  trisurf(meta.Cortex.Faces, ...
    meta.Cortex.Vertices(:,1), meta.Cortex.Vertices(:,2), meta.Cortex.Vertices(:,3), ...
     'FaceColor', [1,1,1]*153/255, ...
    'EdgeColor', ...
    'none', 'FaceAlpha', 0.75 )
  hold on
  scatter3(result.IntendedCent(1), result.IntendedCent(2), result.IntendedCent(3), ...
    30, 'red','filled')
  legend({'','Seed dipole, $n^*$'}, 'Interpreter', 'latex')
  legend boxoff
  %
  view([ 90  90]) % top
  camlight('headlight','infinite')
  material dull
  grid off
  set(gca,'DataAspectRatio',[1 1 1])
  %
  set(gca,'XColor', 'none','YColor','none','ZColor','none')
  set(gca, 'color', 'none');
  set(gcf,'color','w');
  set(gca,'LooseInset',get(gca,'TightInset'))
  fig = gcf;
  fig.Units = 'inches';
  fig.OuterPosition = [0 0 3 3];
  exportgraphics(gcf,[info.SourceProfile, '_center.pdf'],'Resolution',600)
  %
  % TRUE SOURCES
  J = zeros(meta.nGridDips,1);
  J(RES.idxShort) = RES.Jshort;
  figure()
  trisurf(meta.Cortex.Faces, ...
    meta.Cortex.Vertices(:,1), meta.Cortex.Vertices(:,2), meta.Cortex.Vertices(:,3), ...
    'FaceColor', [1,1,1]*153/255, ...
    'EdgeColor', ...
    'none', 'FaceAlpha', 1 )
  view([ 90  90]) % top
  camlight('headlight', 'infinite')
  material dull
  %
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
  %
  grid off
  set(gca,'DataAspectRatio',[1 1 1])
  set(gca,'XColor', 'none','YColor','none','ZColor','none')
  set(gca, 'color', 'none');
  set(gcf,'color','w');
  set(gca,'LooseInset',get(gca,'TightInset'))
  %
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
  %
  fig = gcf;
  fig.Units = 'inches';
  fig.OuterPosition = [0 0 3 3];
  exportgraphics(gcf,[info.SourceProfile, '_GroundTruth.pdf'],'Resolution',600)
  %
  % PROFILE GRAPH
  figure()
  fig = tiledlayout(1,1,'Padding','tight');
  nexttile
  %GraphDist = distances(meta.asGraph, RES.idxShort, RES.idxShort) ...
  %  * max(meta.minDist(RES.idxShort));
  switch info.SourceType
    case 'surface'
      % geodesic distance in cortex
      scatter( GraphDist, RES.normJshort.^2, "filled" ) 
    case 'volume'
      % euclidian distance in 3D space
      scatter( vecnorm( meta.Gridloc(RES.idxShort,:) - ...
        (result.IntendedCent'*ones(size(RES.idxShort)))', 2, 2 ), ...
        RES.normJshort.^2, "filled" ) 
  end
  %
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
  %
  grid on
  set(gcf,'color','w');
  fig.Units = 'inches';
  fig.OuterPosition = [0 0 3 3];
  exportgraphics(gcf,[info.SourceProfile, '_Profile.pdf'],'Resolution',600)
end

% for the figre of AUROC
if info.debugFigs
  % TRUE SOURCES
  J = zeros(meta.nGridDips,1);
  J(RES.idxShort) = RES.Jshort;
  figure()
  trisurf(meta.Cortex.Faces, ...
    meta.Cortex.Vertices(:,1), meta.Cortex.Vertices(:,2), meta.Cortex.Vertices(:,3), ...
    'FaceColor', [1,1,1]*153/255, ...
    'EdgeColor', ...
    'none', 'FaceAlpha', 1 )
  view([ 90  90]) % top
  camlight('headlight', 'infinite')
  material dull
  hold on
  %
  trisurf(meta.Cortex.Faces, ...
    meta.Cortex.Vertices(:,1), meta.Cortex.Vertices(:,2), meta.Cortex.Vertices(:,3), ...
    'FaceColor', 'interp', ...
    'FaceVertexCData', min(floor(abs(J)*6)/6, 1/6), ...
    'EdgeColor', 'none', ...
    'FaceAlpha', 'interp', ...
    'FaceVertexAlphaData', 1*(abs(J)>(1/6-.1)*max(abs(J(:)))) )
  material dull
  %colormap("jet")
  colormap('parula')
  clim([0,1])
  %
  trisurf(meta.Cortex.Faces, ...
    meta.Cortex.Vertices(:,1), meta.Cortex.Vertices(:,2), meta.Cortex.Vertices(:,3), ...
    'FaceColor', 'interp', ...
    'FaceVertexCData', min(floor(abs(J)*6)/6, 3/6), ...
    'EdgeColor', 'none', ...
    'FaceAlpha', 'flat', ...
    'FaceVertexAlphaData', 1*(abs(J)>(3/6-.1)*max(abs(J(:)))) )
  material dull
  %colormap("jet")
  colormap('parula')
  clim([0,1])
  %
  trisurf(meta.Cortex.Faces, ...
    meta.Cortex.Vertices(:,1), meta.Cortex.Vertices(:,2), meta.Cortex.Vertices(:,3), ...
    'FaceColor', 'interp', ...
    'FaceVertexCData', min(floor(abs(J)*6)/6, 5/6), ...
    'EdgeColor', 'none', ...
    'FaceAlpha', 'flat', ...
    'FaceVertexAlphaData', 1*(abs(J)>(5/6-.1)*max(abs(J(:)))) )
  material dull
  %colormap("jet")
  colormap('parula')
  clim([0,1])
  %
  %trisurf(meta.Cortex.Faces, ...
  %  meta.Cortex.Vertices(:,1), meta.Cortex.Vertices(:,2), meta.Cortex.Vertices(:,3), ...
  %  'FaceColor', 'interp', ...
  %  'FaceVertexCData', abs(J), ...
  %  'EdgeColor', 'none', ...
  %  'FaceAlpha', 'interp', ...
  %  'FaceVertexAlphaData', 1*(abs(J)>0.05*max(abs(J(:)))) )
  %material dull
  %%colormap("turbo")
  %colormap("parula")
  %clim([0,1])
  %
  grid off
  set(gca,'DataAspectRatio',[1 1 1])
  set(gca,'XColor', 'none','YColor','none','ZColor','none')
  set(gca, 'color', 'none');
  set(gcf,'color','w');
  set(gca,'LooseInset',get(gca,'TightInset'))
  %
  fig = gcf;
  fig.Units = 'inches';
  fig.OuterPosition = [0 0 2 3];
  exportgraphics(gcf,[info.SourceProfile, '_AUROC_GroundTruth.pdf'],'Resolution',600)
end

% patch
if size(RES.Jshort, 2) ~= 1
  RES.Jshort = RES.Jshort';
end

% Y, noiseless
RES.Yclean = meta.Leadfield(:,RES.idxShortG) * RES.Jshort;
%RES.varY  = vecnorm( meta.LeadfieldOG, 2, 2 );
RES.varY   = RES.Yclean.^2;

% adding noise to a prescribed SNR
if isinf(result.SNR)
  noise = zeros( size(RES.Yclean) );
else
  noise = normrnd(0, 1, size(RES.Yclean) );
end

% Y
RES.YOG = RES.Yclean + 10^(-result.SNR/10) * diag( RES.varY ) * noise;
RES.Y   = RES.YOG - mean(RES.YOG,1);

% true center of mass
RES.TrueCent = RES.normJshort' * meta.Gridloc(RES.idxShort,:) / sum(RES.normJshort);

% for compression purposes, the source as a sparse matrix
switch info.SourceType
  case 'volume'
    tmp = zeros(meta.nGridDips*3, size(RES.Y,2));
  case 'surface'
    tmp = zeros(meta.nGridDips,   size(RES.Y,2));
    tmp(RES.idxShort) = sparse(RES.Jshort);
end
tmp(RES.idxShortG) = sparse(RES.Jshort);
RES.Jsparse = tmp;

end
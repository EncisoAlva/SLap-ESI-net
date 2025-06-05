function PlotOnSphere(lap, CurrVar)

figure()
trisurf(lap.Triangulation, ...
  lap.MESHpos(:,1), lap.MESHpos(:,2), lap.MESHpos(:,3), ...
  'FaceColor', [1,1,1]*153/255, ...
  'EdgeColor', ...
  'none', 'FaceAlpha', 0.75 )

% change view BEFORE adding light
view([ 90  90]) % top
camlight('headlight','infinite')
material dull
grid off
set(gca,'DataAspectRatio',[1 1 1])
set(gca,'XColor', 'none','YColor','none','ZColor','none')
set(gca, 'color', 'none');
set(gcf,'color','w');
set(gca,'LooseInset',get(gca,'TightInset'))

hold on
MM = max(abs(CurrVar(:)));
trisurf(lap.Triangulation, ...
  lap.MESHpos(:,1), lap.MESHpos(:,2), lap.MESHpos(:,3), ...
  'FaceColor', 'interp', ...
  'FaceVertexCData', CurrVar, ...
  'EdgeColor', 'none', ...
  'FaceAlpha', 'interp', ...
  'FaceVertexAlphaData', ones(size(CurrVar)) )
  %'FaceVertexAlphaData', 1*(abs(CurrVar)>0.05*max(abs(CurrVar(:)))) )
material dull
%colormap("turbo")
colormap("parula")
%clim([min(CurrVar(:)),max(CurrVar(:))])
clim([-MM,MM])

colorbar

end
function PlotNaiveWMNE(meta, RES, TitleText)
% source patch distribution
figure()

J = full(RES.J_WMNE);
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
clim([0,max(abs(J(:)))])
  
% remove grids and stuff
grid off
set(gca,'DataAspectRatio',[1 1 1])
set(gca,'XColor', 'none','YColor','none','ZColor','none')
set(gca, 'color', 'none');
set(gcf,'color','w');
set(gca,'LooseInset',get(gca,'TightInset'))
  
% labels
title(TitleText)
  
% configure for export
%fig = gcf;
%fig.Units = 'inches';
%fig.OuterPosition = [0 0 3 3];
%exportgraphics(gcf,[info.SourceProfile, '_GroundTruth.pdf'],'Resolution',600)
end
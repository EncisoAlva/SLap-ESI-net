ElecPos = normrnd(0,1,90,3);

% parameters
nElec = size(ElecPos,2);

% initialization
ctr_old = mean(ElecPos,1);
rad_old = median( vecnorm(ElecPos-ctr_old, 2, 2) );
err_old = mean(abs( vecnorm(ElecPos-ctr_old, 2, 2)-rad_old ));

if false
  scatter3(ElecPos(:,1), ElecPos(:,2), ElecPos(:,3), "filled")
  hold on
  scatter3(ctr_old(:,1), ctr_old(:,2), ctr_old(:,3), "filled")
end

% loop for getting a better center
for scale = 0:10
  fprintf('Step %i / 10\n \n', scale)
  for idx = 1:1000
    ctr_new = ctr_old + normrnd(0,rad_old*2^(-scale), 1,1);
    rad_new = median( vecnorm(ElecPos-ctr_new, 2, 2) );
    err_new = mean(abs( vecnorm(ElecPos-ctr_new, 2, 2)-rad_new ));
    if err_new < err_old
      ctr_old = ctr_new;
      rad_old = rad_new;
      err_old = err_new;
      fprintf('Avg. error: %2.5f ;  Id : %i \n', err_old, idx)
    end
  end
end
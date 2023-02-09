


figure(7)
clf
val = ceil(sqrt(n_unique_actions));
for ii = 1:n_unique_actions
    subplot(val,val,ii)
    imagesc(mdp.T(:,:,ii))
    title(num2str(ii))
end
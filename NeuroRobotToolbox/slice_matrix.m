


figure(7)
clf
for ii = 1:10
    subplot(2,5,ii)
    imagesc(mdp.T(:,:,ii))
    title(num2str(ii))
end
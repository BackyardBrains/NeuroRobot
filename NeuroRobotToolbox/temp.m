

a1 = mdp.T(:,:,1);
a2 = mdp.T(:,:,2);

figure(1)
clf
set(gcf, 'position', [300 300 1200 400])

subplot(1,2,1)
imagesc(a1, [0 1])
title('a1')
colorbar

subplot(1,2,2)
imagesc(a2, [0 1])
title('a2')
colorbar
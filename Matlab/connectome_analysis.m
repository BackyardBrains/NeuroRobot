clf
subplot(2,2,1)
imagesc(connectome)
colorbar
title('Current')
subplot(2,2,2)
imagesc(da_connectome(:,:,2))
colorbar
title('Original')
subplot(2,2,3)
reinforcement_matrix = connectome - da_connectome(:,:,2);
imagesc(reinforcement_matrix)
colorbar
title('Reinforcement')
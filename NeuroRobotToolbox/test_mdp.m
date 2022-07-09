
% going_east = [mdp.T(1,5,:); mdp.T(5,9,:); mdp.T(13,17,:); mdp.T(17,21,:)];
% squeeze(going_east)
% 
% turning_left = [mdp.T(1,2,:); mdp.T(5,6,:); mdp.T(9,10,:); ...
%     mdp.T(13,14,:); mdp.T(17,18,:); mdp.T(21,22,:)];
% squeeze(turning_left)
% 
% turning_right = [mdp.T(2,1,:); mdp.T(6,5,:); mdp.T(10,9,:); ...
%     mdp.T(14,13,:); mdp.T(18,17,:); mdp.T(22,21,:)];
% squeeze(turning_right)

origin = [2 1 3 4 2] - 1;
turning_left = [];
for ii = 1:4:24
    this_array = squeeze(mdp.T(ii + origin(jj + 1), origin(jj), :))
        turning_left = [turning_left; this_array];    
    for jj = 1:4
        this_array = squeeze(mdp.T(origin(jj + 1), origin(jj), :))
        turning_left = [turning_left; this_array];
    end
end

figure(1)
clf
plot(mean(turning_left, 2))
% 
% turning_left = [...
%     squeeze(mdp.T(5, 1, :)), ...
%     squeeze(mdp.T(14, 2, :)), ...
%     squeeze(mdp.T(18, 6, :)), ...
%     squeeze(mdp.T(22, 10, :)), ...
%     squeeze(mdp.T(17, 21, :)), ...
%     squeeze(mdp.T(13, 17, :)), ...
%     squeeze(mdp.T(20, 16, :)), ...
%     squeeze(mdp.T(11, 23, :)), ...
%     squeeze(mdp.T(20, 16, :)), ...
%     ];
% 
% mean(turning_left, 2)'
% 
% figure(1)
% clf
% plot(mean(turning_left, 2))

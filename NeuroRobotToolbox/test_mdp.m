
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
    for jj = 1:4
        this_array = squeeze(mdp.T(origin(ii + jj), origin(ii + jj + 1), :))
        turning_left = [turning_left; this_array];
    end
end


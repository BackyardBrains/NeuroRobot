

nsteps = 3000;
intended_activity_1 = zeros(nsteps, 1);
x = exp(0.02:0.02:10);
for ii = 1:nsteps
    if ii <= 500
        intended_activity_1(ii) = intended_activity_1(ii) + x(ii);
    elseif ii <= 1000
        intended_activity_1(ii) = intended_activity_1(ii) + x(ii-500);
    elseif ii <= 1500
        intended_activity_1(ii) = intended_activity_1(ii) + x(ii-1000);
    elseif ii <= 2000
        intended_activity_1(ii) = intended_activity_1(ii) + x(ii-1500);
    elseif ii <= 2500
        intended_activity_1(ii) = intended_activity_1(ii) + x(ii-2000);
    elseif ii <= 3000
        intended_activity_1(ii) = intended_activity_1(ii) + x(ii-2500);
    end
end
intended_activity_1 = intended_activity_1 - min(intended_activity_1);
intended_activity_1 = intended_activity_1 / max(intended_activity_1);

intended_activity_2 = sigmoid(0.02:0.003327:10, 5);
intended_activity_2 = intended_activity_2 - min(intended_activity_2);
intended_activity_2 = intended_activity_2 / max(intended_activity_2);

intended_activity_3 = intended_activity_1 + intended_activity_2';
intended_activity_3 = intended_activity_3 - min(intended_activity_3);
intended_activity_3 = intended_activity_3 / max(intended_activity_3);

intended_activity = intended_activity_3;

% clf
% plot(intended_activity_1)
% hold on
% plot(intended_activity_2)
% plot(intended_activity_3)
% plot(intended_activity, 'linewidth', 3, 'color', 'k')
% title('Intended activity')
% 
% save('intended_activity', 'intended_activity')


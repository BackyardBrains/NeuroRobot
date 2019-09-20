
% This script generates a time series representing regular bursting

nsteps = 3000;

intended_activity = zeros(nsteps, 1);
x = exp(0.02:0.02:10);

for ii = 1:nsteps
    if ii <= 500
        intended_activity(ii) = x(ii);
    elseif ii <= 1000
        intended_activity(ii) = x(ii-500);
    elseif ii <= 1500
        intended_activity(ii) = x(ii-1000);
    elseif ii <= 2000
        intended_activity(ii) = x(ii-1500);
    elseif ii <= 2500
        intended_activity(ii) = x(ii-2000);
    elseif ii <= 3000
        intended_activity(ii) = x(ii-2500);
    end
end

intended_activity = intended_activity - min(intended_activity);
intended_activity = intended_activity / max(intended_activity);

plot(intended_activity)
title('Intended activity')

% save('intended_activity', 'intended_activity')

axes(ml_load_status)
cla
txx = text(0.03, 0.5, 'Loading...');
drawnow

net_name = 'patternrecognizer';

try
    openfig(strcat(nets_dir_name, net_name, '-examples.fig'))
    load(strcat(nets_dir_name, net_name, '-mdp'))
catch
    button_load_ml.BackgroundColor = [1 0 0];
    pause(0.5)
    button_load_ml.BackgroundColor = [0.94 0.94 0.94];
    error('Cannot find prepared training data')
end

txx.String = 'Ready to train decision network';


% figure(1)
% clf
% ax1 = axes('Position', [0.02 0.02 0.47 0.96]);
% draw1 = image(zeros(227, 227, 3));
% set(gca, 'xtick', [], 'ytick', [])
% ax2 = axes('Position', [0.51 0.02 0.47 0.96]);
% draw2 = image(zeros(227, 227, 3));
% set(gca, 'xtick', [], 'ytick', [])

for ntuple = tlog(1) - 2 : tlog(end)
    disp(horzcat('ntuple: ', num2str(ntuple), ', torques: ', ...
        num2str(torque_data(ntuple, 1)), ' ', num2str(torque_data(ntuple, 2))))

    ind = ntuple*2 - 1;
    fname = horzcat(image_dir(ind).folder, '\', image_dir(ind).name);
    im = imread(fname);
    draw1.CData = im;

    ind = ntuple*2;
    fname = horzcat(image_dir(ind).folder, '\', image_dir(ind).name);
    im = imread(fname);
    draw2.CData = im;

    pause(0.5)
    drawnow
end
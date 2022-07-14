clc
for ntuple = tlog(1) - 4 : tlog(end)
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
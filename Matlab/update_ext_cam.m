if ext_cam_id
    trigger(ext_cam)
    ext_frame = getdata(ext_cam);
    ext_im.CData = ext_frame(:,281:1000,:);
    save_ext_cam(:, :, :, xstep) = ext_frame;
    if sum(firing)
        save_firing(:, xstep) = firing;
    end
    save_left_cam(:, :, :, xstep) = left_eye_frame;
    save_right_cam(:, :, :, xstep) = right_eye_frame;
    save_time(xstep) = this_time;
    if xstep == ext_cam_nsteps
        run_button = 4;
    end
end
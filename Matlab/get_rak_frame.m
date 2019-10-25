function [large_frame, rak_fail] = get_rak_frame(rak_cam, use_webcam, rak_only)

rak_fail = 0;
try
    if rak_only
        large_frame = rak_cam.readVideo();
%         large_frame = flip(permute(reshape(large_frame, 3, 1280, 720),[3,2,1]), 3);
        large_frame = flip(permute(reshape(large_frame, 3, 1920, 1080),[3,2,1]), 3);
    elseif ~use_webcam
        large_frame = getsnapshot(rak_cam);
    elseif use_webcam
        trigger(rak_cam)
        large_frame = getdata(rak_cam, 1);
    end
catch
%     large_frame = zeros(720, 1280, 3, 'uint8');
    large_frame = zeros(1080, 1920, 3, 'uint8');
    disp('RAK fail')
    rak_fail = 1;
end

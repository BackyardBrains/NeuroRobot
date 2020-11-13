

this_offset = [5 6 1 2 3 4];

just_off

for ii = 1:10
    for nled = 1:6
        rak_cam.writeSerial(sprintf('d:%d11;', nled));
        pause(0.1)
        rak_cam.writeSerial(sprintf('d:%d11;', this_offset(nled)));
    end
end

just_off
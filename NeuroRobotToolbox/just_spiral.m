

a = [4 3 1 6 5 2];
b = [5 2 4 3 1 6];

just_off

for nloop = 1:10
    for nled = 1:6
        rak_cam.writeSerial(sprintf('d:%d11;', a(nled)));
        pause(0.1)
        rak_cam.writeSerial(sprintf('d:%d10;', b(nled)));
        pause(0.1)
    end
end

just_off
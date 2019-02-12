clear mex; clear all; close all; clear functions;

mex RAK5206.cpp -I/usr/local/include -L/usr/local/lib -lboost_system -lboost_thread -lboost_chrono -lavcodec -lavformat -lavutil -lswscale
% mex RAK5206.cpp -ID:\rak\boost_1_68_0\library2\include\boost-1_68 -LD:\rak\boost_1_68_0\library2\lib  -lboost_system-vc120-mt-x64-1_68 -ID:\rak\ffmpeg-4.1-win64-dev\include -LD:\rak\ffmpeg-4.1-win64-dev\lib -lavcodec -lavformat -lavutil -lswscale -D_WIN32_WINNT=0x0601
% mex RAK5206.cpp -IC:\boost_1_68_0_build\include\boost-1_68 -IC:\ffmpeg-4.1-win64-dev\include -LC:\boost_1_68_0_build\lib -LC:\ffmpeg-4.1-win64-dev\lib -llibboost_system-mgw63-mt-x32-1_68 -llibboost_thread-mgw63-mt-x32-1_68 -llibboost_chrono-mgw63-mt-x32-1_68 -lavcodec -lavformat -lavutil -lswscale -D_WIN32_WINNT=0x0A00 
% mex RAK5206.cpp -IC:\boost_1_68_0_build2\include\boost-1_68 -IC:\ffmpeg-4.1-win64-dev\include -LC:\boost_1_68_0_build2\lib -LC:\ffmpeg-4.1-win64-dev\lib -lavcodec -lavformat -lavutil -lswscale -llibboost_system-vc141-mt-x64-1_68 -llibboost_system-vc141-mt-x64-1_68 -llibboost_chrono-vc141-mt-x64-1_68 -D_WIN32_WINNT=0x0A00

rak = RAK5206_matlab('192.168.100.1', '80');
rak.start();

p1 = imshow(uint8(255* ones(720, 1280, 3)), []);

audioMat = 0;
serialData = 0;

serialCounter = 0;
while rak.isRunning()
    
    
    imageMat = rak.readVideo();
    
    
    audioMat = [audioMat rak.readAudio()];
    
    imageMat = flip(permute(reshape(imageMat, 3, 1280, 720),[3,2,1]), 3);
    
    if mod(serialCounter, 5) == 0
        rak.writeSerial(uint8([1 2 3 4 5]') );
    end
    
    if mod(serialCounter, 20) == 0
        t=0:1/1000:6;
        y=sin(50*t);
        y = [y y y y]';
        rak.sendAudio2(y);
        
%         rak.sendAudio('test.wav');
    end
    
    serialData = [serialData rak.readSerial()];
    
    

    set(p1, 'CData', imageMat);
    drawnow
    
    serialCounter = serialCounter + 1;
end
closeAll;
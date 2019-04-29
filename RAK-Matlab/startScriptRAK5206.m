clear mex; clear all; close all; clear functions;

% mex RAK5206.cpp -I/usr/local/include -L/usr/local/lib -lboost_system -lboost_thread -lboost_chrono -lavcodec -lavformat -lavutil -lswscale
% mex RAK5206.cpp -ID:\rak\boost_1_68_0\library2\include\boost-1_68 -LD:\rak\boost_1_68_0\library2\lib  -lboost_system-vc120-mt-x64-1_68 -ID:\rak\ffmpeg-4.1-win64-dev\include -LD:\rak\ffmpeg-4.1-win64-dev\lib -lavcodec -lavformat -lavutil -lswscale -D_WIN32_WINNT=0x0601
% mex RAK5206.cpp -IC:\boost_1_68_0_build\include\boost-1_68 -IC:\ffmpeg-4.1-win64-dev\include -LC:\boost_1_68_0_build\lib -LC:\ffmpeg-4.1-win64-dev\lib -llibboost_system-mgw63-mt-x32-1_68 -llibboost_thread-mgw63-mt-x32-1_68 -llibboost_chrono-mgw63-mt-x32-1_68 -lavcodec -lavformat -lavutil -lswscale -D_WIN32_WINNT=0x0A00 
% mex RAK5206.cpp -IC:\boost_1_68_0_build2\include\boost-1_68 -IC:\ffmpeg-4.1-win64-dev\include -LC:\boost_1_68_0_build2\lib -LC:\ffmpeg-4.1-win64-dev\lib -lavcodec -lavformat -lavutil -lswscale -llibboost_system-vc141-mt-x64-1_68 -llibboost_system-vc141-mt-x64-1_68 -llibboost_chrono-vc141-mt-x64-1_68 -D_WIN32_WINNT=0x0A00
% mex RAK5206.cpp -LC:\boost_1_68_0 -LC:\boost_1_68_0\stage\lib -IC:\boost_1_68_0 -IC:\boost_1_68_0\stage\lib -LC:\ffmpeg-shared\bin -LC:\ffmpeg-dev\lib -LC:\ffmpeg-dev\include -IC:\ffmpeg-shared\bin -IC:\ffmpeg-dev\lib -IC:\ffmpeg-dev\include -llibboost_system-vc141-mt-x64-1_68 -llibboost_system-vc141-mt-x64-1_68 -llibboost_chrono-vc141-mt-x64-1_68 -lboost_thread-vc141-mt-x64-1_68 -lavcodec -lavformat -lavutil -lswscale
% mex RAK5206.cpp -IC:\boost_1_68_0 -LC:\boost_1_68_0\stage\lib -LC:\ffmpeg-4.1-win64-dev\lib -IC:\ffmpeg-4.1-win64-dev\include -lavcodec -lavformat -lavutil -lswscale -llibboost_system-vc141-mt-x64-1_68 -llibboost_chrono-vc141-mt-x64-1_68 -D_WIN32_WINNT=0x0A00
mex RAK5206.cpp -IC:\Users\Stanislav\Downloads\boost_1_69_0-1\boost_1_69_0 -LC:\Users\Stanislav\Downloads\boost_1_69_0-1\boost_1_69_0\stage\lib -LC:\Users\Stanislav\Downloads\ffmpeg-4.1.1-win64-dev\ffmpeg-4.1.1-win64-dev\lib -IC:\Users\Stanislav\Downloads\ffmpeg-4.1.1-win64-dev\ffmpeg-4.1.1-win64-dev\include -lavcodec -lavformat -lavutil -lswscale -llibboost_system-vc140-mt-x64-1_69 -llibboost_chrono-vc140-mt-x64-1_69 -llibboost_date_time-vc140-mt-x64-1_69 -D_WIN32_WINNT=0x0601

rak = RAK5206_matlab('192.168.100.1', '80');
rak.start();

p1 = imshow(uint8(255* ones(720, 1280, 3)), []);

audioMat = [];
serialData = [];

serialCounter = 0;

while rak.isRunning()
    
    % Video stream
    imageMat = rak.readVideo();
    imageMat = flip(permute(reshape(imageMat, 3, 1280, 720),[3,2,1]), 3);
    set(p1, 'CData', imageMat);
    drawnow
    
    % Audio stream
    audioMat = [audioMat rak.readAudio()];
    
    % Write serial
%     if serialCounter < 100
%         rak.writeSerial('l:100;r:100;d:50;');
%     else
%         rak.writeSerial('l:0;r:0;d:0;');
%     end
    
    
    % Send audio
%     if serialCounter == 0
%         t = 0 : 1/1000 : 5;
%         y = sin(6.28 * 8 * t);
%         y = [y y y y]';
%         rak.sendAudio2(y);
% %         rak.sendAudio('test.wav');
%     end
    
    % Receive serial
%     serialData = [serialData rak.readSerial()];

    serialCounter = serialCounter + 1;
end

closeAll;

clear mex;
clear all;
close all;
clear functions;

if ~exist('RAK5206.mexw64', 'file')
%     mex RAK5206.cpp -IC:\boost_1_68_0 -LC:\boost_1_68_0\stage\lib -LC:\ffmpeg-4.1-win64-dev\lib -IC:\ffmpeg-4.1-win64-dev\include -lavcodec -lavformat -lavutil -lswscale -llibboost_system-vc141-mt-x64-1_68 -llibboost_chrono-vc141-mt-x64-1_68 -D_WIN32_WINNT=0x0A00
    mex RAK5206.cpp -IC:\boost_1_69_0 -LC:\boost_1_69_0\stage\lib -LC:\ffmpeg-4.1.1-win64-dev\lib -IC:\ffmpeg-4.1.1-win64-dev\include -lavcodec -lavformat -lavutil -lswscale -llibboost_system-vc141-mt-x64-1_69 -llibboost_chrono-vc141-mt-x64-1_69 -D_WIN32_WINNT=0x0A00
end

if ~exist('rak', 'var')
    rak = RAK5206_matlab('192.168.100.1', '80');
end
rak.start();

fig1 = figure(1);
clf
set(fig1, 'position', [1 41 1536 800.8])
set(fig1, 'NumberTitle', 'off', 'Name', 'Neurorobot Matlab C++ WiFi RAK interface')
set(fig1, 'menubar', 'none', 'toolbar', 'none')
vid_ax = axes('position', [0.05 0.15 0.9 0.8]);
p1 = imshow(uint8(255* ones(720, 1280, 3)), []);
button_stop = uicontrol('Style', 'pushbutton', 'String', 'Stop', 'units', 'normalized', 'position', [0.4 0.05 0.2 0.05]);
set(button_stop, 'Callback', 'flag_run = 0;', 'FontSize', 18)

audioMat = [];
serialData = [];
flag_run = 1;
serialCounter = 0;

while rak.isRunning() && flag_run
    
    % Video stream
    imageMat = rak.readVideo();
    imageMat = flip(permute(reshape(imageMat, 3, 1280, 720),[3,2,1]), 3);
    set(p1, 'CData', imageMat);
    drawnow
    
    % Audio stream
    audioMat = [audioMat rak.readAudio()];
    
    % Write serial
    if serialCounter < 100
        rak.writeSerial('l:100;r:100;d:311;');
    else
        rak.writeSerial('l:0;r:0;d:0;');
    end
    
    
    % Send audio
    if serialCounter == 0
%         t = 0 : 1/1000 : 5;
%         y = sin(6.28 * 8 * t);
%         y = [y y y y]';
%         rak.sendAudio2(y);
        rak.sendAudio('EXPLOSION.mp3');
    end
    
    % Receive serial
    serialData = [serialData rak.readSerial()];

    serialCounter = serialCounter + 1;
end

rak.stop();
audiowrite('test.wav', audioMat, 8000);
close all;
serialData


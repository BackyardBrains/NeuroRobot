clear mex;
clear all;
close all;
clear functions;

if ~exist('NeuroRobot_MatlabBridge.mexw64', 'file') && ispc
    % Windows
    
    % FFMPEG - Libraries (*.dll) must be in root folder. So copy from libraries/windows/ffmpeg/lib/bin to root.
    mex NeuroRobot_framework/NeuroRobot_MatlabBridge.cpp NeuroRobot_framework/NeuroRobotManager.cpp NeuroRobot_framework/SharedMemory.cpp NeuroRobot_framework/Log.cpp NeuroRobot_framework/VideoAndAudioObtainer.cpp NeuroRobot_framework/Socket.cpp -IC:\boost_1_69_0 -LC:\boost_1_69_0\stage\lib -Llibraries\windows\ffmpeg\bin -Ilibraries\windows\ffmpeg\include -lavcodec -lavformat -lavutil -lswscale -llibboost_system-vc141-mt-x64-1_69 -llibboost_chrono-vc141-mt-x64-1_69 -llibboost_filesystem-vc141-mt-x64-1_69 -D_WIN32_WINNT=0x0A00
elseif ~isfile('NeuroRobot_MatlabBridge.mexmaci64') && ismac
    % macOS
    
    % FFMPEG - Libraries (*.dylib) must be in /usr/lib. So copy libraries from libraries/mac/ffmpeg/lib to /usr/lib.
%     mex NeuroRobot5206.cpp -I/usr/local/Cellar/boost/1.69.0_2/include -L/usr/local/Cellar/boost/1.69.0_2/lib -Ilibraries/mac/ffmpeg/include -lboost_system -lboost_chrono -lboost_thread-mt -lavcodec -lavformat -lavutil -lswscale
    mex NeuroRobot_framework/NeuroRobot_MatlabBridge.cpp NeuroRobot_framework/NeuroRobotManager.cpp NeuroRobot_framework/SharedMemory.cpp NeuroRobot_framework/Log.cpp NeuroRobot_framework/VideoAndAudioObtainer.cpp NeuroRobot_framework/Socket.cpp -Ilibraries/mac/boost/1.70.0/include -Llibraries/mac/boost/1.70.0/lib -Ilibraries/mac/ffmpeg/include -Llibraries/mac/ffmpeg/dylib -lboost_system -lboost_chrono -lboost_thread -lboost_filesystem -lavcodec -lavformat -lavutil -lswscale
end

if ~exist('rak', 'var')
    rak = NeuroRobot_matlab('192.168.100.1', '80');
end
rak.start();

% Init UI
fig1 = figure(1);
clf
set(fig1, 'position', [1 41 1536 800.8])
set(fig1, 'NumberTitle', 'off', 'Name', 'Neurorobot Matlab C++ WiFi NeuroRobot interface')
set(fig1, 'menubar', 'none', 'toolbar', 'none')
vid_ax = axes('position', [0.05 0.15 0.9 0.8]);
p1 = imshow(uint8(255* ones(1080, 1920, 3)), []);
button_stop = uicontrol('Style', 'pushbutton', 'String', 'Stop', 'units', 'normalized', 'position', [0.4 0.05 0.2 0.05]);
set(button_stop, 'Callback', 'flag_run = 0;', 'FontSize', 18)

% Init data
audioMat = [];
serialData = [];
flag_run = 1;
serialCounter = 0;
tempTimestamp = now;
frequency = 10;
deltaTime = (1/frequency)*0.0001;
ledCounter = 1;
ledOrder = [1 3 4 2 5 6];


% Recording delays
FileName = fullfile('NeuroRobot_delays.txt');
fid = fopen(FileName, 'w');
if fid == -1
  error('Cannot open file: %s', FileName);
end
startDurations = [];
videoDurations = [];
audioDurations = [];
writeSerialDurations = [];
sendAudioDurations = [];
receiveSerialDurations = [];
startTimings = [];
videoTimings = [];
audioTimings = [];
writeSerialTimings = [];
sendAudioTimings = [];
receiveSerialTimings = [];

while rak.isRunning() && flag_run
    
    startTimings = [startTimings; clock];
    
    % Video stream
    imageMat = rak.readVideo();
    imageMat = permute(reshape(imageMat, 3, 1920, 1080), [3,2,1]);
    set(p1, 'CData', imageMat);
    drawnow limitrate
    videoTimings = [videoTimings; clock];
    
    % Audio stream
    audioMat = [audioMat rak.readAudio()];
    audioTimings = [audioTimings; clock];
    
    % Write serial
    rak.writeSerial('d:0;');
    rak.writeSerial(sprintf('d:%d11;', ledOrder(ledCounter)));
    ledCounter = ledCounter + 1;
    if ledCounter > numel(ledOrder)
        ledCounter = 1;
    end
    writeSerialTimings = [writeSerialTimings; clock];
    
    % Send audio
%     if mod(serialCounter - 10, 500) == 0
    if serialCounter == 10
%         t = 0 : 1/1000 : 5;
%         y = sin(6.28 * 8 * t);
%         y = [y y y y]';
%         rak.sendAudio2(y);
%         rak.sendAudio('NeuroRobot_framework/EXPLOSION.mp3');
    end
    sendAudioTimings = [sendAudioTimings; clock];
    
    % Receive serial
    serialData = [serialData rak.readSerial()];
    receiveSerialTimings = [receiveSerialTimings; clock];
    
    serialCounter = serialCounter + 1;
end

% Printing delays
for i = 1:length(videoTimings) - 1
    videoDurations(i) = etime(videoTimings(i,:), startTimings(i,:)) * 1000;
    fprintf(fid, 'video: %f\n',  videoDurations(i));
end
fprintf(fid, '\n');
for i = 1:length(audioTimings) - 1
    audioDurations(i) = etime(audioTimings(i,:), videoTimings(i,:)) * 1000;
    fprintf(fid, 'audio: %f\n', audioDurations(i));
end
fprintf(fid, '\n');
for i = 1:length(writeSerialTimings) - 1
    writeSerialDurations(i) = etime(writeSerialTimings(i,:), audioTimings(i,:)) * 1000;
    fprintf(fid, 'write serial: %f\n', writeSerialDurations(i));
end
fprintf(fid, '\n');
for i = 1:length(sendAudioTimings) - 1
    sendAudioDurations(i) = etime(sendAudioTimings(i,:), writeSerialTimings(i,:)) * 1000;
    fprintf(fid, 'send audio: %f\n', sendAudioDurations(i));
end
fprintf(fid, '\n');
for i = 1:length(receiveSerialTimings) - 1
    receiveSerialDurations(i) = etime(receiveSerialTimings(i,:), sendAudioTimings(i,:)) * 1000;
    fprintf(fid, 'receive serial: %f\n', receiveSerialDurations(i));
end
fprintf(fid, '\n');
fprintf(fid, 'average video: %f\n', mean(videoDurations));
fprintf(fid, 'average audio: %f\n', mean(audioDurations));
fprintf(fid, 'average write serial: %f\n', mean(writeSerialDurations));
fprintf(fid, 'average send audio: %f\n', mean(sendAudioDurations));
fprintf(fid, 'average receive serial: %f\n', mean(receiveSerialDurations));
fprintf(fid, '\ntotal average: %f\n', mean(videoDurations) + mean(audioDurations) + mean(writeSerialDurations) + mean(sendAudioDurations) + mean(receiveSerialDurations));
fprintf(fid, '\n');
fclose(fid);

rak.stop();
pause(2);
audiowrite('test.wav', audioMat, rak.readAudioSampleRate());
close all;
serialData;

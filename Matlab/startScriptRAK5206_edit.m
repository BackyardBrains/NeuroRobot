
%% Close and clear
close all
clear


%% MEX build
if ~exist('RAK5206.mexw64', 'var')
    mex RAK5206.cpp -IC:\boost_1_69_0 -LC:\boost_1_69_0\stage\lib -LC:\ffmpeg-4.1.1-win64-dev\lib -IC:\ffmpeg-4.1.1-win64-dev\include -lavcodec -lavformat -lavutil -lswscale -llibboost_system-vc141-mt-x64-1_69 -llibboost_chrono-vc141-mt-x64-1_69 -D_WIN32_WINNT=0x0A00
end


%% Create RAK object
rak = RAK5206_matlab('192.168.100.1', '80');
rak.start();


%% Prepare
audioMat = [];
serialArray = [];


%% Prepare figure
fig1 = figure(1);
clf
% set(fig1, 'position', [1 41 1920 1003])
set(fig1, 'position', [1 41 1536 800.8])
set(fig1, 'NumberTitle', 'off', 'Name', 'Neurorobot Matlab C++ WiFi RAK interface')
set(fig1, 'menubar', 'none', 'toolbar', 'none')
vid_ax = axes('position', [0.05 0.15 0.9 0.8]);
p1 = imshow(uint8(255* ones(720, 1280, 3)), []);
button_stop = uicontrol('Style', 'pushbutton', 'String', 'Stop', 'units', 'normalized', 'position', [0.4 0.05 0.2 0.05]);
set(button_stop, 'Callback', 'flag_run = 0;', 'FontSize', 18, 'FontName', 'Comic Book')


%% Main loop
serialCounter = 0;
flag_run = 1;
flag_led = 0;
this_send = '';
while rak.isRunning() && flag_run

    %% Step
    tic
    serialCounter = serialCounter + 1;
    
    
    %% Vision
    imageMat = rak.readVideo();
    imageMat = flip(permute(reshape(imageMat, 3, 1280, 720),[3,2,1]), 3);
    set(p1, 'CData', imageMat);
    drawnow

%     %% Read serial
%     serial_receive = rak.readSerial();
%     if ~isempty(serial_receive)
%         serialArray = [serialArray serial_receive];
%         a = regexp(serialArray, '[\r]');
%         l = length(serialArray);
%         if ~isempty(a) && l >= 6
%             a = a(end);
%             x = serialArray(l-5:l-1);       
%             disp('Received:')
%             disp(x)
%             serialArray = [];
%         end
% %         text_serial_receive.String = horzcat('Received: ', num2str(serial_receive));
%     end

    %% Motors
    if ~rem(serialCounter, 50)
        if flag_led
            flag_led = 0;
            this_send = 'd:320;';
%             this_send = 'r:200;';
        else
            flag_led = 1;
            this_send = 'd:321;';
%             this_send = 'r:0;';
        end
        rak.writeSerial(this_send)
        disp(horzcat('Step ', num2str(serialCounter)))
    end
    
    %% Hearing
%     audioMat = [audioMat rak.readAudio()];

    %% Sound
%     if mod(serialCounter, 20) == 0
%         t=0:1/1000:6;
%         y=sin(50*t);
%         y = [y y y y]';
% %         rak.sendAudio2(y);
% %         rak.sendAudio('test.wav');
%     end

    %% Timer
    while toc < 0.1
        pause(0.01)
    end
    
end

rak.stop();

close all

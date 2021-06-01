
clear
%%must have commandNet.mat in the Neurorobot Toolbox
load('commandNet.mat')
fs=16000;
%%
% The network is trained to recognize the following speech commands:
%
% * "yes"
% * "no"
% * "up"
% * "down"
% * "left"
% * "right"
% * "on"
% * "off"
% * "stop"
% * "go"
%
%% Detect Commands Using Streaming Audio from Microphone
% Test your pre-trained command detection network on streaming audio from
% your microphone. Try saying one of the commands, for example, _yes_,
% _no_, or _stop_. Then, try saying one of the unknown words such as
% _Marvin_, _Sheila_, _bed_, _house_, _cat_, _bird_, or any number from
% zero to nine.
%
% Specify the classification rate in Hz and create an audio device reader
% that can read audio from your microphone.

classificationRate = 10; %must be even, fix this
adr = audioDeviceReader('SampleRate',fs,'SamplesPerFrame',floor(fs/classificationRate));
%% 
audioBuffer = dsp.AsyncBuffer(fs);

% labels = trainedNet.Layers(end).Classes;
labels = trainedNet.Layers(end).Classes; %%do some visualization of this
YBuffer(1:classificationRate/2) = categorical("background");

probBuffer = zeros([numel(labels),classificationRate/2]);

countThreshold = ceil(classificationRate*0.2);
probThreshold = 0.7;
%% 
VC_on=0;
if VC_on==1
h = figure('Units','normalized','Position',[0.2 0.1 0.6 0.8]);

timeLimit = Inf; % To run the loop indefinitely, set |timeLimit| to |Inf|

tic;

while ishandle(h) && toc < timeLimit
    
    % Extract audio samples from the audio device and add the samples to
    % the buffer.
    x = adr();
    write(audioBuffer,x);
    y = read(audioBuffer,fs,fs-adr.SamplesPerFrame);
    
    spec = helperExtractAuditoryFeatures(y,fs);
    
    % Classify the current spectrogram, save the label to the label buffer,
    % and save the predicted probabilities to the probability buffer.
    [YPredicted,probs] = classify(trainedNet,spec,'ExecutionEnvironment','gpu');
    YBuffer = [YBuffer(2:end),YPredicted];
    probBuffer = [probBuffer(:,2:end),probs(:)];
    
    % Plot the current waveform and spectrogram.
    subplot(2,1,1)
    plot(y)
    axis tight
    ylim([-1,1])
    
    subplot(2,1,2)
    pcolor(spec')
    caxis([-4 2.6445])
    shading flat
    
    % Now do the actual command detection by performing a very simple
    % thresholding operation. Declare a detection and display it in the
    % figure title if all of the following hold: 1) The most common label
    % is not background. 2) At least countThreshold of the latest frame
    % labels agree. 3) The maximum probability of the predicted label is at
    % least probThreshold. Otherwise, do not declare a detection.
    [YMode,count] = mode(YBuffer);
    
    maxProb = max(probBuffer(labels == YMode,:));
    subplot(2,1,1)
    if YMode == "background" || count < countThreshold || maxProb < probThreshold
        title(" ")
    else
        title(string(YMode),'FontSize',20)
    end
    
    if YMode=='on'
        close(h)
        neurorobot
        %stop(rak_pulse)
    elseif YMode == "background"
    else
        disp('You need to tell the robot to turn on!')
    end
    drawnow
end
end
%%
h = figure('Units','normalized','Position',[0.2 0.1 0.6 0.8]);

timeLimit = Inf; % To run the loop indefinitely, set |timeLimit| to |Inf|

tic;
while ishandle(h) && toc < timeLimit
    
    % Extract audio samples from the audio device and add the samples to
    % the buffer.
    x = adr();
    write(audioBuffer,x);
    y = read(audioBuffer,fs,fs-adr.SamplesPerFrame);
    
    spec = helperExtractAuditoryFeatures(y,fs);
    
    % Classify the current spectrogram, save the label to the label buffer,
    % and save the predicted probabilities to the probability buffer.
    [YPredicted,probs] = classify(trainedNet,spec,'ExecutionEnvironment','cpu');
    YBuffer = [YBuffer(2:end),YPredicted];
    probBuffer = [probBuffer(:,2:end),probs(:)];
    
    % Plot the current waveform and spectrogram.
    subplot(2,1,1)
    plot(y)
    axis tight
    ylim([-1,1])
    
    subplot(2,1,2)
    pcolor(spec')
    caxis([-4 2.6445])
    shading flat
    
    % Now do the actual command detection by performing a very simple
    % thresholding operation. Declare a detection and display it in the
    % figure title if all of the following hold: 1) The most common label
    % is not background. 2) At least countThreshold of the latest frame
    % labels agree. 3) The maximum probability of the predicted label is at
    % least probThreshold. Otherwise, do not declare a detection.
    [YMode,count] = mode(YBuffer);
    
    maxProb = max(probBuffer(labels == YMode,:));
    subplot(2,1,1)
    if YMode == "background" || count < countThreshold || maxProb < probThreshold
        title(" ")
    else
        title(string(YMode),'FontSize',20)
    end
    
%     if YMode=='off'
%         close all
%         msg = sprintf('You closed the robot!');
%         j = msgbox(msg);
%     elseif YMode=='go'
%         rak_cam.writeSerial('l:50;r:50;s:0;')
%     elseif YMode=='stop'
%         rak_cam.writeSerial('l:0;r:0;s:0;')
%     elseif YMode=='right'
%         rak_cam.writeSerial('l:50;r:0;s:0;')
%     elseif YMode=='left'
%         rak_cam.writeSerial('l:50;r:50;s:0;') 
%     elseif YMode=='yes' 
%         %make the robot wiggle and keep doing what it's doing, could maybe integrate with the dopamine stuff
%         [y, Fs] = audioread('happybeep.mp3');
%         player = audioplayer(y, Fs);play(player)
%     elseif YMode=='no'
%         rak_cam.writeSerial('l:0;r:0;s:0;') %%stop the robot
%         [y, Fs] = audioread('womp-womp.mp3');
%         player = audioplayer(y, Fs);play(player)
%     end
    drawnow
end
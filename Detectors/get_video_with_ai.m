
delete(imaqfind)
cmap = cool;
if ~exist('trainedDetector', 'var')
    load('rcnn5heads')
end
prepare_word

%% Create camera object
cam = videoinput('winvideo', cam_id);
triggerconfig(cam, 'manual');
cam.TriggerRepeat = Inf;
cam.FramesPerTrigger = 1;
cam.ReturnedColorspace = 'rgb';
start(cam)

%% Prompt
prompt_a = horzcat('You are a helpful artificial intelligence, specifically a text completion ', ...
    'engine similar to GPT-3. You are assisting at Summer Fellowship exploring how embedded ', ...
    'neural networks can be used in research and education. The following is a conversation ', ...
    'between you and ');

prompt_b = 'Dr. Harris, your AI maintenance guy. This is a short description of his Summer Project: ';
                summer_project = 'Cook meat. Summer Fellowship. Grants. Stop aging. Treat the missus.';
                
prompt_c = horzcat('(The description of the Summer Project ends here.)\n\nThe conversation 6begins here.\n', ...
    'Human: Hello, who are you?\nAI:');

prompt = horzcat(prompt_a, prompt_b, prompt_c);
dialog = [];


%% Prep
recObj = audiorecorder(16000, 16, 1);
speechObject = speechClient('Google','languageCode','en-US');

%% Create video writer object
if exist('vidWrite', 'var')
    close(vidWrite)
end
vidWrite = VideoWriter(raw_video_filename, 'MPEG-4');
vidWrite.FrameRate = fps;
open(vidWrite)

%% Get first frame
trigger(cam)
frame = getdata(cam, 1);
frame = frame(:, 281:1000, :);
frame = imresize(frame, net_input_size);

%% Create UI
fig1 = figure(1);
clf
set(gcf, 'position', [80 60 1400 700], 'color', 'w')
ax_frame = axes('position', [0.02 0.1 0.47 0.86]);
im = image(frame);
set(gca, 'xtick', [], 'ytick', [])
ti1 = title('Preparing...');
hold on
pl(1).plt = plot(-1, -1, 'linestyle', 'none', 'color', cmap(1, :), 'marker', 'o', 'markersize', 8, 'linewidth', 2);

object_strs = {'ariyana', 'head', 'nour', 'sarah', 'wenbo'};
nobjects = size(object_strs, 2);
object_scores = zeros(nobjects,1);
ax_bar = axes('position', [0.55 0.15 0.4 0.78]);
object_bars = bar(object_scores);
hold on
ylabel('Inference score (max)')
plot(xlim, [qi qi], 'color', [0.75 0 0], 'linestyle', '--')
plot(xlim, [qi qi]*2, 'color', [0 0.75 0], 'linestyle', '--')
set(gca, 'xticklabels', object_strs)
ylim([0 1])
xlim([0.2 5.8])

%% Buttons
talk_flag = 0;
button_stop = uicontrol('Style', 'pushbutton', 'String', 'Talk', 'units', 'normalized', 'position', [0.02 0.02 0.47 0.06]);
set(button_stop, 'Callback', 'talk_flag = 1;', 'FontSize', 12, 'FontName', 'Comic Book', 'FontWeight', 'bold', 'BackgroundColor', [0.8 0.8 0.8])

stop_flag = 0;
button_stop = uicontrol('Style', 'pushbutton', 'String', 'Stop', 'units', 'normalized', 'position', [0.51 0.02 0.47 0.06]);
set(button_stop, 'Callback', 'stop_flag = 1;', 'FontSize', 12, 'FontName', 'Comic Book', 'FontWeight', 'bold', 'BackgroundColor', [0.8 0.8 0.8])

%% Record video
zi = [];
clear pl
nframe = 0;
superflag = 0;
while ~stop_flag
    tic
    nframe = nframe + 1;
    trigger(cam)
    frame = getdata(cam, 1);
    frame = frame(:, 281:1000, :);
    frame = imresize(frame, net_input_size);
    im.CData = frame;
    
    [bbox, score, label] = detect(trainedDetector, frame, 'NumStrongestRegions', 500, ...
        'threshold', 0, 'ExecutionEnvironment', 'gpu', 'MiniBatchSize', 128);
    [mscore, midx] = max(score);
    mbbox = bbox(midx, :);
    
    for nobject = 1:5
        if ~isempty(max(score(label == object_strs{nobject})))
            object_scores(nobject) = max(score(label == object_strs{nobject}));
        end
    end
    
    object_bars.YData = object_scores;
    
    x = bbox(score > qi,1) + bbox(score > qi,3)/2;
    y = bbox(score > qi,2) + bbox(score > qi,4)/2;
    mx = mbbox(:,1) + mbbox(:,3)/2;
    my = mbbox(:,2) + mbbox(:,4)/2;
    
    nboxes = length(x);
    prev_length = length(zi);
    zi(1 + prev_length : prev_length + nboxes) = 10;
    for nbox = nboxes:-1:1
        if mscore > qi
            axes(ax_frame)
            pl(prev_length + nbox).plt = plot(x, y, 'linestyle', 'none', 'color', cmap(round(score(nbox)* 63) + 1, :), 'marker', 'o', 'markersize', 8, 'linewidth', 2);
        end
    end
    
    for ii = 1:length(zi)
        zi(ii) = zi(ii) - 1;
        if zi(ii) < 1
            delete(pl(ii).plt)
        end
    end
    
    ti1.String = horzcat('nframe = ', num2str(nframe), ', mscore = ', num2str(round(mscore * 100)/100), ', superflag = ', num2str(superflag));
    drawnow
    
    if talk_flag
        talk_flag = 0;
        recordblocking(recObj, 5)
        data = getaudiodata(recObj);
        tableOut = speech2text(speechObject, data, 16000);
        cellOut = table2cell(tableOut(:,1));
        disp(cellOut)
        human_says = cellOut{1};
        if ~strcmp(human_says, 'NoResult')
            prompt = append(prompt, 'AI: I am an AI created by OpenAI. How can I help you today?', ...
                '\nHuman: ', human_says);
        end
    end
    
    if ~isempty(mscore) && ~superflag
        if object_scores(1) > qi * 2
            superflag = 40;
            prompt_b = horzcat('Ariyana, a Fellow at the Summer Course. This is a short description ', ...
                'of her Summer Project: ');
            summer_project = 'Humans blink an average of 28,800 times a day. That means that a person who lives to 80 blinks around 840,960,000 times in their lifetime. The average blink lasts around 0.1 - 0.15 seconds, meaning that humans spend 126,144,000 seconds of their awake time on Earth with their eyes closed; that’s 973 - 1,460 days; 2.7 - 4 years! What’s happening in all that time? Are we simply doomed to miss out on those years of our life? Worry no more, FOMO glasses are (hopefully) here to help! These high tech and stylish glasses made to be wearable by the public will use Electrooculography (EOG) signals to detect blinks from the wearer and take photos in real time of all the life being missed out on. Say goodbye to the FOMO from that concert you had to blink through, and worry no more about missing frames from your favorite movie you claim to have seen the entirety of. Now with FOMO glasses, you can live your life to the fullest, and be present for every moment of it.';
            
        elseif object_scores(2) > qi * 2
            superflag = 40;
            xx = rand;
            if xx <= 0.5 % if object_scores(6) > qi * 2
                prompt_b = 'Dr. Harris, your AI maintenance guy. This is a short description of his Summer Project: ';
                summer_project = 'Cook meat. Summer Fellowship. Grants. Stop aging. Treat the missus.';
            elseif xx > 0.5 % elseif object_scores(7) > qi * 2
                prompt_b = 'Dr. Gage, who runs the Summer Fellowship. This is a short description of his Summer Project: ';
                summer_project = horzcat('Cookouts. Baseball. Summer Fellowship. Grants. Treat the missus.');
            end
            
        elseif object_scores(3) > qi * 2
            superflag = 40;
            prompt_b = horzcat('Nour, a Fellow at the Summer Course. This is a short ', ...
                'description of her Summer Project: ');
            summer_project = 'In my project, I will develop a small touch screen to show a series of playing cards while measuring EEGs. The subject chooses a card and AI determines which one it was. I will be training a machine learning algorithm to recognize the steady state visual evoked potentials (SSVEP) and/or the P300 surprise signal to give a guess on the run.';
            
        elseif object_scores(4) > qi * 2
            superflag = 40;
            prompt_b = horzcat('Sarah, a Fellow at the Summer Course. This is a short ', ...
                'description of her Summer Project: ');
            summer_project = 'Hi everyone! I am working on a lie detection device using TinyML that will hopefully be multimodal. I am currently working on assembling a base model using skin galvanic response before I move forward into considering EEG and other modalities.';
            
        elseif object_scores(5) > qi * 2
            superflag = 40;
            prompt_b = 'Wenbo, an Engineer at Backyard Brains. This is a short description of his Summer Project: ';
            summer_project = horzcat('Engineering. Engineering. Engineering. Car. Treat the missus.');
            %                elseif object_scores(6) > qi * 2
            %                     prompt_b = 'It is Dr. Harris, your AI maintenance guy. This is a short description of his Summer Project: ';
            %                     summer_project = 'Cook meat. Summer Fellowship. Grants. Stop aging. Treat the missus.';
            %                elseif object_scores(7) > qi * 2
            %                     prompt_b = 'It is Dr. Gage, who runs the Summer Fellowship. This is a short description of his Summer Project: ';
            %                     summer_project = horzcat('Cookouts. Baseball. Summer Fellowship. Grants. Treat the missus.');
        end
        
        prompt = horzcat(prompt_a, prompt_b, summer_project, prompt_c, dialog); % prompt needs to go in here...
        % switching between people complicates
        
    end
    
    
    
    try
        answer = bybai2(prompt); % When should answer be integrated?
        keyboard
    catch
        disp('Failed to run gpt3_play')
        soundsc(hello_wav, 16000);
    end

    if superflag
        superflag = superflag - 1;
    end

    writeVideo(vidWrite, frame);

end
stop_flag = 1;
close(vidWrite)
close(fig1)
stop(cam)

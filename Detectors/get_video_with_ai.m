
%% Settings
net_input_size = [227 227];
fps = 10;
raw_video_filename = 'garden1.mp4';
cam_id = 1;
qi = 0.4;

%% Prepare
tic
if exist('cam', 'var') && strcmp(cam.Running, 'off')
    start(cam)
elseif ~exist('cam', 'var')
    delete(imaqfind)
    cam = videoinput('winvideo', cam_id);
    triggerconfig(cam, 'manual');
    cam.TriggerRepeat = Inf;
    cam.FramesPerTrigger = 1;
    cam.ReturnedColorspace = 'rgb';
end
nappends = 0;
cmap = cool;
if ~exist('trainedDetector', 'var')
    load('rcnn5heads')
end
prepare_word

%% Prompt
prompt_a = horzcat('You are a helpful artificial intelligence, specifically a text completion ', ...
    'engine similar to GPT-3. You are assisting at Summer Fellowship exploring how embedded ', ...
    'neural networks can be used in research and education.\n\nThe following is a conversation ', ...
    'between you and ');
                
prompt_c = horzcat('(The description of the Summer Project ends here.)\n\n--- The dialog begins here ---', ...
    '\nHuman: Hello, who are you?\nAI: I am an artificial intelligence created by OpenAI and Backyard Brains. ', ...
    'How can I help you today?');

prompt = '';

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
plot(xlim, [qi qi], 'color', [0 0 0], 'linestyle', '--')
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
this_person = '';
zi = [];
clear pl
nframe = 0;
record_flag = 0;

while ~stop_flag
    tic
    nframe = nframe + 1;
    trigger(cam)
    frame = getdata(cam, 1);
    frame = frame(:, 281:1000, :);
    frame = imresize(frame, net_input_size);
    im.CData = frame;
%     disp(horzcat('Time to get and display frame: ', num2str(toc)))
    
    tic
    [bbox, score, label] = detect(trainedDetector, frame, 'NumStrongestRegions', 500, ...
        'threshold', 0, 'ExecutionEnvironment', 'gpu', 'MiniBatchSize', 128);
    [mscore, midx] = max(score);
    mbbox = bbox(midx, :);
    mlabel = char(label(midx));
%     disp(horzcat('Time to run inference: ', num2str(toc)))
    
    tic
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
    
%     disp(horzcat('Time to do misc: ', num2str(toc)))
    
    if talk_flag
        tic
        talk_flag = 0;
        record_flag = 30;
        record(recObj)
    end
    
    if record_flag
        record_flag = record_flag - 1;
        ti1.String = horzcat('nframe = ', num2str(nframe), ', label = ', mlabel, ...
            ', confidence = ', num2str(round(mscore * 100)/100), ', talking to ', this_person, ...
            ', nappends = ', num2str(nappends), ' RECORDING AUDIO (', num2str(record_flag), ')');    
    else
        ti1.String = horzcat('nframe = ', num2str(nframe), ', label = ', mlabel, ...
            ', confidence = ', num2str(round(mscore * 100)/100), ', talking to ', this_person, ...
            ', nappends = ', num2str(nappends));
    end
    
    drawnow
    
    if record_flag == 1
        record_flag = 0;
        
        ti1.String = 'Processing recorded audio...';
        drawnow
        stop(recObj)
        data = getaudiodata(recObj);
        disp(horzcat('Time to record audio: ', num2str(toc)))     

        tic
        ti1.String = 'Converting speech to text...';
        drawnow
        tableOut = speech2text(speechObject, data, 16000);
        cellOut = table2cell(tableOut(:,1));
        human_says = cellOut{1};
        human_says = char(human_says);
        disp(horzcat('Time to do speech-to-text: ', num2str(toc)))

        if ~strcmp(human_says, 'NoResult')
            tic
            disp(horzcat('Human says: ', human_says))
            vocalize_this(horzcat('I heard you say: ', human_says))
            disp(horzcat('Time to echo = ', num2str(toc)))

            if strcmp(this_person, '')
                [i, this_person] = max(object_scores);
                if this_person == 1
                    this_person = 'Ariyana';
                    prompt_b = horzcat(', a Fellow at the Summer Course. This is a short description of her Summer Project: ');
                    summer_project = 'Humans blink an average of 28,800 times a day. That means that a person who lives to 80 blinks around 840,960,000 times in their lifetime. The average blink lasts around 0.1 - 0.15 seconds, meaning that humans spend 126,144,000 seconds of their awake time on Earth with their eyes closed; that’s 973 - 1,460 days; 2.7 - 4 years! What’s happening in all that time? Are we simply doomed to miss out on those years of our life? Worry no more, FOMO glasses are (hopefully) here to help! These high tech and stylish glasses made to be wearable by the public will use Electrooculography (EOG) signals to detect blinks from the wearer and take photos in real time of all the life being missed out on. Say goodbye to the FOMO from that concert you had to blink through, and worry no more about missing frames from your favorite movie you claim to have seen the entirety of. Now with FOMO glasses, you can live your life to the fullest, and be present for every moment of it.';
                elseif this_person == 2
                    this_person = 'Dr. Harris';
                    prompt_b = ', your AI maintenance guy. This is a short description of his Summer Project: ';
                    summer_project = 'Cook meat. Summer Fellowship. Grants. Stop aging. Treat the missus.';            
                elseif this_person == 3
                    this_person = 'Nour';
                    prompt_b = horzcat('Nour, a Fellow at the Summer Course. This is a short description of her Summer Project: ');
                    summer_project = 'In my project, I will develop a small touch screen to show a series of playing cards while measuring EEGs. The subject chooses a card and AI determines which one it was. I will be training a machine learning algorithm to recognize the steady state visual evoked potentials (SSVEP) and/or the P300 surprise signal to give a guess on the run.';
                elseif this_person == 4
                    this_person = 'Sarah';
                    prompt_b = horzcat(', a Fellow at the Summer Course. This is a short description of her Summer Project: ');
                    summer_project = 'Hi everyone! I am working on a lie detection device using TinyML that will hopefully be multimodal. I am currently working on assembling a base model using skin galvanic response before I move forward into considering EEG and other modalities.';            
                elseif this_person == 5
                    this_person = 'Wenbo';
                    prompt_b = ', an Engineer at Backyard Brains. This is a short description of his Summer Project: ';
                    summer_project = horzcat('Engineering. Engineering. Engineering. Car. Treat the missus.');
                end
                prompt = horzcat(prompt_a, this_person, prompt_b, summer_project, prompt_c);
            end
            
            prompt = append(prompt, '\nHuman: ', human_says);
            nappends = nappends + 1;

            tic
            ti1.String = 'Generating dialog...';
    %         clear classes; m = py.importlib.import_module('ai'); py.importlib.reload(m);
            prompt = append(prompt, '\nAI:');
            py_str = py.ai.gpt3(prompt);
            ai_says = strtrim(char(py_str));
            linebreaks = strfind(ai_says, '\n');
            if ~isempty(linebreaks)
                ai_says(linebreaks(1):end) = [];
            end
            disp(horzcat('AI says: ', ai_says))
            disp(horzcat('Time to generate dialog = ', num2str(toc)))
            human_says = 'NoResult';
            tic
            vocalize_this(ai_says)
            prompt = append(prompt, ai_says);
            nappends = nappends + 1;
            disp(horzcat('Time to vocalize: ', num2str(toc)))
        end
        
    end

    drawnow
    writeVideo(vidWrite, frame);

end

sprintf(prompt)

stop_flag = 1;
close(vidWrite)
close(fig1)
stop(cam)

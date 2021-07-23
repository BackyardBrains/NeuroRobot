
%% Input video
input_video = 'office23.mp4';

%% Input classifier
if ~exist('trainedDetector', 'var'); load('rcnn5heads'); end

%% Input deep labels
load people

%% Output file
output_file = 'office23_bbox_labels.mp4';

%% Settings
qi = 0.7;

%% Prepare
vidRead = VideoReader(input_video);
nframes = vidRead.NumFrames;
if vidRead.Width > 300
    error('Video is too large')
end
randframes = randsample(vidRead.NumFrames,vidRead.NumFrames);


%% Prepare figure
fig1 = figure(1);
clf
fig1.UserData = 0;
frame = read(vidRead, 1);
image_ax = axes('position', [0.05 0.25 0.9 0.7]);
image_frame = image(frame);
set(gca, 'xtick', [], 'ytick', [])
hold on
t1 = title('Preparing...');
image_bbox = rectangle('position', [1 1 1 1], 'linewidth', 3, 'edgecolor', [0 0 0]);
npeps = length(people.names);
fsize = 11;

button_1a = uicontrol('Style', 'pushbutton', 'String', people.names{1}, 'units', 'normalized', 'position', [0.05+(0.13*0) 0.16 0.1 0.05], 'Callback', 'fig1.UserData = 1; label_flag = 1;', 'FontSize', fsize, 'FontName', 'Comic Book');
button_1b = uicontrol('Style', 'pushbutton', 'String', people.names{2}, 'units', 'normalized', 'position', [0.05+(0.13*1) 0.16 0.1 0.05], 'Callback', 'fig1.UserData = 1; label_flag = 2;', 'FontSize', fsize, 'FontName', 'Comic Book');
button_1c = uicontrol('Style', 'pushbutton', 'String', people.names{3}, 'units', 'normalized', 'position', [0.05+(0.13*2) 0.16 0.1 0.05], 'Callback', 'fig1.UserData = 1; label_flag = 3;', 'FontSize', fsize, 'FontName', 'Comic Book');
button_1d = uicontrol('Style', 'pushbutton', 'String', people.names{4}, 'units', 'normalized', 'position', [0.05+(0.13*3) 0.16 0.1 0.05], 'Callback', 'fig1.UserData = 1; label_flag = 4;', 'FontSize', fsize, 'FontName', 'Comic Book');
button_1e = uicontrol('Style', 'pushbutton', 'String', people.names{5}, 'units', 'normalized', 'position', [0.05+(0.13*4) 0.16 0.1 0.05], 'Callback', 'fig1.UserData = 1; label_flag = 5;', 'FontSize', fsize, 'FontName', 'Comic Book');
button_1f = uicontrol('Style', 'pushbutton', 'String', people.names{6}, 'units', 'normalized', 'position', [0.05+(0.13*5) 0.16 0.1 0.05], 'Callback', 'fig1.UserData = 1; label_flag = 6;', 'FontSize', fsize, 'FontName', 'Comic Book');

button_2a = uicontrol('Style', 'pushbutton', 'String', people.names{7}, 'units', 'normalized', 'position', [0.05+(0.13*0) 0.09 0.1 0.05], 'Callback', 'fig1.UserData = 1; label_flag = 7;', 'FontSize', fsize, 'FontName', 'Comic Book');
button_2b = uicontrol('Style', 'pushbutton', 'String', people.names{8}, 'units', 'normalized', 'position', [0.05+(0.13*1) 0.09 0.1 0.05], 'Callback', 'fig1.UserData = 1; label_flag = 8;', 'FontSize', fsize, 'FontName', 'Comic Book');
button_2c = uicontrol('Style', 'pushbutton', 'String', people.names{9}, 'units', 'normalized', 'position', [0.05+(0.13*2) 0.09 0.1 0.05], 'Callback', 'fig1.UserData = 1; label_flag = 9;', 'FontSize', fsize, 'FontName', 'Comic Book');
button_2d = uicontrol('Style', 'pushbutton', 'String', people.names{10}, 'units', 'normalized', 'position', [0.05+(0.13*3) 0.09 0.1 0.05], 'Callback', 'fig1.UserData = 1; label_flag = 10;', 'FontSize', fsize, 'FontName', 'Comic Book');
button_2e = uicontrol('Style', 'pushbutton', 'String', people.names{11}, 'units', 'normalized', 'position', [0.05+(0.13*4) 0.09 0.1 0.05], 'Callback', 'fig1.UserData = 1; label_flag = 11;', 'FontSize', fsize, 'FontName', 'Comic Book');
button_2f = uicontrol('Style', 'pushbutton', 'String', people.names{12}, 'units', 'normalized', 'position', [0.05+(0.13*5) 0.09 0.1 0.05], 'Callback', 'fig1.UserData = 1; label_flag = 12;', 'FontSize', fsize, 'FontName', 'Comic Book');
button_2g = uicontrol('Style', 'pushbutton', 'String', people.names{13}, 'units', 'normalized', 'position', [0.05+(0.13*6) 0.09 0.1 0.05], 'Callback', 'fig1.UserData = 1; label_flag = 13;', 'FontSize', fsize, 'FontName', 'Comic Book');

button_3a = uicontrol('Style', 'pushbutton', 'String', '-- skip --', 'units', 'normalized', 'position', [0.05 0.02 0.425 0.05], 'Callback', 'fig1.UserData = 1; skip_flag = 1;', 'FontSize', fsize, 'FontName', 'Comic Book');
button_3b = uicontrol('Style', 'pushbutton', 'String', '-- stop --', 'units', 'normalized', 'position', [0.525 0.02 0.425 0.05], 'Callback', 'fig1.UserData = 1; stop_flag = 1;', 'FontSize', fsize, 'FontName', 'Comic Book');

clear final_labels
stop_flag = 0;
final_step = 0;
label_flag = 0;
skip_flag = 0;
for nstep = 1:nframes
    
    frame = read(vidRead, randframes(nstep));
    
    [bbox, score, label] = detect(trainedDetector, frame, 'NumStrongestRegions', 2000, ...
        'threshold', 0, 'ExecutionEnvironment', 'gpu', 'MiniBatchSize', 128);
    
    x = bbox(:,1) + bbox(:,3)/2;
    y = bbox(:,2) + bbox(:,4)/2;
    nboxes = length(x);
    
    [mscore, midx] = max(score);
    mbbox = bbox(midx, :);
    mlabel = char(label(midx));    
    mx = mbbox(:,1) + mbbox(:,3)/2;
    my = mbbox(:,2) + mbbox(:,4)/2;
        
    dist_from_main = sqrt((x - mx).^2 + (y - my).^2);
    
    image_frame.CData = frame;
    
    counter = 0;
    for nbox = 1:nboxes
        if dist_from_main(nbox) > 50
            counter = counter + 1;
            pl(counter).plt = plot(x(nbox), y(nbox), 'linestyle', 'none', 'color', 'r', 'marker', 'o', 'markersize', 8, 'linewidth', 2);
        end
    end   
    drawnow
    
    if ~isempty(mscore)
        disp_str = horzcat('nframe = ', num2str(nstep), ' of ', num2str(nframes), ...
            ', xframe = ', num2str(randframes(nstep)), ', mscore = ', num2str(mscore));
        t1_str = horzcat('nlabels = ', num2str(final_step), ', nframes = ', num2str(nstep), ' of ', num2str(nframes), ' (', num2str((round((nstep/nframes) * 100))), '%)');
        image_bbox.Position = mbbox;
        image_bbox.EdgeColor = [0.9 0 0];
    else
        disp_str = 'mscore is empty';
        t1.String = t1_str;
        image_bbox.Position = [1 1 1 1];
        image_bbox.EdgeColor = [0 0 0];        
    end
    disp(disp_str)
    t1.String = t1_str;
        
    if strcmp(mlabel, 'head') && double(mscore) > qi
        final_step = final_step + 1;
        image_bbox.EdgeColor = [0 0.9 0];
        
        waitfor(fig1, 'UserData', 1)
        fig1.UserData = 0;
        if label_flag
            this_deep_label = people.names{label_flag};
            final_labels{final_step, 1} = input_video; % File name
            final_labels{final_step, 2} = randframes(nstep); % Frame number
            final_labels{final_step, 3} = mbbox; % BBox
            final_labels{final_step, 4} = this_deep_label; % Deep label
            label_flag = 0;
        elseif skip_flag
            skip_flag = 0;
            final_step = final_step - 1;
        elseif stop_flag
            break
        end
    end    
    for jj = 1:counter
        delete(pl(jj).plt)
    end    
end

clc
clf

% Save to gtruth

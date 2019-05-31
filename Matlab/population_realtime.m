
clear
% what about appending laptop-specific file name extensions to recorded data?

%% Load shared data
% load('neurorobot_data.mat');

neurorobot_data = struct;
neurorobot_data(1).computer_name = '';
neurorobot_data(1).stop_time = '';
neurorobot_data(1).nneurons = [];
neurorobot_data(1).nsteps = [];

%% Load local data and add to shared data if new
available_data = dir('.\Data\*.mat');
nnews = 0;
nexists = 0;
for ndatafile_local = 1:size(available_data, 1)
    load(strcat('.\Data\', available_data(ndatafile_local).name))
    n = size(neurorobot_data, 2);
    this_ind = 0;
    for ndatafile_shared = 1:n
        
        % if entry is new
        if isfield(data, 'computer_name') ...
                && isfield(data, 'firing') ...
                && ~(strcmp(data.computer_name, neurorobot_data(ndatafile_shared).computer_name) ...
                && strcmp(data.start_time, neurorobot_data(ndatafile_shared).start_time))
            
            this_ind = ndatafile_shared;
        elseif isfield(data, 'computer_name') ...
                && isfield(data, 'firing') ...
                && (strcmp(data.computer_name, neurorobot_data(ndatafile_shared).computer_name) ...
                && strcmp(data.start_time, neurorobot_data(ndatafile_shared).start_time))
            
        end
        
    end
    
    if this_ind
        nnews = nnews + 1;
        neurorobot_data(n + nnews).computer_name = data.computer_name;
        neurorobot_data(n + nnews).start_time = data.start_time;
        neurorobot_data(n + nnews).stop_time = data.stop_time;
        neurorobot_data(n + nnews).nneurons = size(data.firing, 1);
        neurorobot_data(n + nnews).nsteps = size(data.firing, 2);
        disp(horzcat('new data file found, nnews = ', num2str(nnews)))
    else
        nexists = nexists + 1;
        disp(horzcat('data file already exists, nexists = ', num2str(nexists)))
    end
end

%% Save and finish
save('neurorobot_data.mat', 'neurorobot_data')
disp(horzcat('added ', num2str(nnews), ' new neurorobot datafiles from this computer to the database'))
disp(horzcat(num2str(nexists), ' files already in data base'))


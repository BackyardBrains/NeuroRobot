
close all
clear

tic

t1 = datetime(2019,10,4,9,30,00);
t2 = datetime(2019,10,4,12,00,00);

n = 0;
a = [];
b = [];

local_database = dir('.\Data\*.mat');
for n_local_data = 1:size(local_database, 1)
    load(strcat('.\Data\', local_database(n_local_data).name))
    if isfield(data, 'start_time')
        start_time_chars = char(data.start_time);
        end_time_chars = char(data.stop_time);
        t = datetime(start_time_chars(1:22), 'InputFormat', 'yyyy-MM-dd-hh-mm-ss-ms');
        tx = datetime(end_time_chars(1:22), 'InputFormat', 'yyyy-MM-dd-hh-mm-ss-ms');
        if isbetween(t,t1,t2) && isfield(data, 'firing')
            n = n + 1;
            nx = rand;
            disp(horzcat('lifetimes: ', num2str(n)))
            firing = data.firing;
            nneurons = size(firing, 1);
            nsteps = size(firing, 2);
%             plot(linspace(t, tx, nsteps), mean(firing))
            plot([t tx], [nx nx], 'linewidth', 5, 'color', 'k')
            hold on
            drawnow

        end
    end
end
toc
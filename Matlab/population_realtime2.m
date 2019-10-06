
clear

tic

t1 = datetime(2019,10,4,9,30,00);
t2 = datetime(2019,10,4,12,00,00);

n = 0;
a = [];

local_database = dir('.\Data\*.mat');
for n_local_data = 1:size(local_database, 1)
    load(strcat('.\Data\', local_database(n_local_data).name))
    if isfield(data, 'start_time')
        start_time_chars = char(data.start_time);
        end_time_chars = char(data.stop_time);
        t = datetime(start_time_chars(1:22), 'InputFormat', 'yyyy-MM-dd-hh-mm-ss-ms')
        if isbetween(t,t1,t2)
            n = n + 1;
            firing = data(n_local_data).firing;
            nsteps = size(firing);
    %         scatter(linspace(data(n_local_data).start_time, data(n_local_data).stop_time
    %         a = [a; data(n_local_data).
            t
        end
    end
end
toc
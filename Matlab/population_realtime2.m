
close all
clear

t1 = datetime(2019,10,4,11,10,00);
t2 = datetime(2019,10,4,12,20,00);

n = 0;
a = [];
b = [];

local_database = dir('.\Command\*.mat');
n_local_datas = size(local_database, 1);
for n_local_data = 1:n_local_datas
    disp(horzcat(num2str(n_local_data), ' of ', num2str(n_local_datas)))
    load(strcat('.\Command\', local_database(n_local_data).name))
    stop_time = char(command_log.stop_time);
    yyyy = str2double(stop_time(1:4));
    MM = str2double(stop_time(6:7));
    DD = str2double(stop_time(9:10));
    hh = str2double(stop_time(12:13));
    mm = str2double(stop_time(15:16));
    ss = str2double(stop_time(18:19));
    ms = str2double(stop_time(21:22));
    t = datetime(yyyy, MM, DD, hh, mm, ss, ms);
    
    if isbetween(t,t1,t2) && isfield(command_log, 'stop_event')
        disp('During Friday lesson')
        n = n + 1;
        if strcmp(command_log.stop_event, 'stop button')
            a = [a; t];
            disp('Stop button')
        elseif strcmp(command_log.stop_event, 'rak fail')
            b = [b; t];
            disp('RAK fail')
        end
    end
end

scatter(a, ones(1,length(a)), 'filled', 'markerfacecolor', [0.1 0.8 0.1])
hold on
scatter(b, ones(1,length(b)) + 1, 'filled', 'markerfacecolor', [1 0.3 0.3])
ylim([0 3])
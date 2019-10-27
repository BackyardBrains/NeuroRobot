
clc
clear

% t1 = datetime(2019,10,8,12,45,00);
% t2 = datetime(2019,10,8,13,45,00);

t1 = datetime(2019,10,27,0,0,00);
% t1 = datetime - hours(2);
t2 = datetime;

n = 0;
a = [];
b = [];
c = [];
d = [];

fig1 = figure(1);
clf
set(fig1, 'color', 'w', 'position', [100 100 800 580])
hold on

local_database = dir('.\Command\*.mat');
n_local_datas = size(local_database, 1);
for n_local_data = 1:n_local_datas
    
    disp(horzcat(num2str(n_local_data), ' of ', num2str(n_local_datas)))
    load(strcat('.\Command\', local_database(n_local_data).name))
    
    start_time = char(command_log.start_time);
    yyyy = str2double(start_time(1:4));
    MM = str2double(start_time(6:7));
    DD = str2double(start_time(9:10));
    hh = str2double(start_time(12:13));
    if hh < 12
        hh = hh + 12;
    end
    mm = str2double(start_time(15:16));
    ss = str2double(start_time(18:19));
    ms = str2double(start_time(21:22));
    t_start = datetime(yyyy, MM, DD, hh, mm, ss, ms);    
    
    if isfield(command_log, 'stop_time')
        stop_time = char(command_log.stop_time);
        yyyy = str2double(stop_time(1:4));
        MM = str2double(stop_time(6:7));
        DD = str2double(stop_time(9:10));
        hh = str2double(stop_time(12:13));
        if hh < 12
            hh = hh + 12;
        end
        mm = str2double(stop_time(15:16));
        ss = str2double(stop_time(18:19));
        ms = str2double(stop_time(21:22));
        t_stop = datetime(yyyy, MM, DD, hh, mm, ss, ms);
    end
    
    if isbetween(t_start,t1,t2)
        disp('During Tuesday testing')
        n = n + 1;
        
        command_log
        
        a = [a; t_start];
        b = [b; t_stop];
        
        if strcmp(command_log.computer_name, 'laptop-purple')
            c = [c; 1];
        elseif strcmp(command_log.computer_name, 'laptop-yellow')
            c = [c; 2];
        elseif strcmp(command_log.computer_name, 'laptop-white')    
            c = [c; 3];
        elseif strcmp(command_log.computer_name, 'laptop-red')
            c = [c; 4];
        elseif strcmp(command_log.computer_name, 'laptop-orange')
            c = [c; 5];
        elseif strcmp(command_log.computer_name, 'laptop-main')
            c = [c; 6];
        elseif strcmp(command_log.computer_name, 'laptop-green')  
            c = [c; 7];
        else
            c = [c; 8];
        end
        if isfield(command_log, 'stop_event')
            if strcmp(command_log.stop_event, 'stop button')
                d = [d; 0];
                disp('Stop button')
                col = [0.1 0.8 0.1];
            elseif strcmp(command_log.stop_event, 'rak fail')
                d = [d; 1]; 
                disp('RAK fail')
                col = [1 0.3 0.3];
            end
        else
            d = [d; 2]; % Battery?
            col = [0.7 0.7 0.7];
        end
        
        % Plot
        plot([a(end) b(end)], [c(end) c(end)], 'linewidth', 10, 'color', 'k')
        plot(b(end), c(end), 'marker', '.', 'markersize', 36, 'color', col)
        
        dt = t_stop - t_start;
        t_mid = t_start + dt/2;        
        
        if dt > minutes(1)
            text(t_mid, c(end) + 0.4, 'Brain name', 'horizontalalignment', 'center', 'verticalalignment', 'middle')
        end
        
    end
end

if isempty(c)
    error('no neurorobot data found')
end
ylim([0 max(c) + 1])
xlim([t1 t2])
box on
title('Neurorobot on-time')
ylabel('Laptop-robot pair')
xlabel('Time')

% scatter(a, c, 'filled', 'markerfacecolor', [0.1 0.8 0.1])
% hold on
% scatter(b, c, 'markerfacecolor', [1 0.3 0.3])
% xlim([t1 t2])

export_fig(gcf, 'ontimes', '-r150', '-jpg', '-nocrop')

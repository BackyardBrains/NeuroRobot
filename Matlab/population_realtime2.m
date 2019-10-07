
close all
clear

tic

t1 = datetime(2019,10,4,9,30,00);
t2 = datetime(2019,10,4,13,00,00);

n = 0;
a = [];
b = [];

local_database = dir('.\Command\*.mat');
n_local_datas = size(local_database, 1);
for n_local_data = 1:n_local_datas
    disp(horzcat(num2str(n_local_data), ' of ', num2str(n_local_datas)))
    load(strcat('.\Command\', local_database(n_local_data).name))
    yyyy = str2double(local_database(n_local_data).name(1:4));
    MM = str2double(local_database(n_local_data).name(6:7));
    DD = str2double(local_database(n_local_data).name(9:10));
    hh = str2double(local_database(n_local_data).name(12:13));
    mm = str2double(local_database(n_local_data).name(15:16));
    ss = str2double(local_database(n_local_data).name(18:19));
    ms = str2double(local_database(n_local_data).name(21:22));
    t = datetime(yyyy, MM, DD, hh, mm, ss, ms);
    
    if isbetween(t,t1,t2)
        disp('During Friday lesson')
        n = n + 1;

%         end_time_chars = char(data.stop_time);
%         yyyy = str2double(end_time_chars(1:4));
%         MM = str2double(end_time_chars(6:7));
%         DD = str2double(end_time_chars(9:10));
%         hh = str2double(end_time_chars(12:13));
%         mm = str2double(end_time_chars(15:16));
%         ss = str2double(end_time_chars(18:19));
%         ms = str2double(end_time_chars(21:22));     
%         tx = datetime(yyyy, MM, DD, hh, mm, ss, ms);

%         disp(horzcat('lifetimes: ', num2str(n)))
        
%             firing = data.firing;
%             nneurons = size(firing, 1);
%             nsteps = size(firing, 2);
%             plot(linspace(t, tx, nsteps), mean(firing))

%         plot([t tx], [n n], 'linewidth', 5, 'color', 'k')
%         hold on
%         drawnow
        
        nentrys = command_log.n - 1;
        for nentry = 1:nentrys
            
            entry_chars = char(command_log.entry(nentry).time);
            yyyy = str2double(entry_chars(1:4));
            MM = str2double(entry_chars(6:7));
            DD = str2double(entry_chars(9:10));
            hh = str2double(entry_chars(12:13));
            mm = str2double(entry_chars(15:16));
            ss = str2double(entry_chars(18:19));
            ms = str2double(entry_chars(21:22));        
            ty = datetime(yyyy, MM, DD, hh, mm, ss, ms);
            
            if strcmp(command_log.entry(nentry).action, 'stop button')
                b = [b; ty 1];
                disp('Stop button')
            elseif strcmp(command_log.entry(nentry).action, 'rak fail')
                b = [b; ty 0];
                disp('RAK fail')
            end
        end
        
    end
end

toc
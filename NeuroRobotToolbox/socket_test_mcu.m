
try
    fclose(t);
catch
end

clear all
close all

maxtime = 20; %seconds

t = tcpip('10.0.0.1', 80, 'NetworkRole', 'client');
t.OutputBufferSize = 4096;

fopen(t);

message = 'r:+155;l:-155;';

% message = ['d:111;d:121;d:131;d:211;d:221;d:231;' ... 
%     'd:311;d:321;d:331;d:411;d:421;d:431;' ...
%     'd:511;d:521;d:531;d:611;d:621;d:631;'];

fwrite(t,message);

% char(fread(t,t.BytesAvailable,'uint8')')
% fclose(t);

left_encoder_data = zeros(1,maxtime*10)*NaN;
right_encoder_data = zeros(1,maxtime*10)*NaN;
ultrasound_data = zeros(1,maxtime*10)*NaN;

bat_current_data = zeros(1,maxtime*10)*NaN;
bat_voltage_data = zeros(1,maxtime*10)*NaN;
bat_cap_data = zeros(1,maxtime*10)*NaN;
bat_time_data = zeros(1,maxtime*10)*NaN;

t1 = tic;
i = 1;

t_x = linspace(0,maxtime,length(ultrasound_data));

received = [];

while (toc(t1) < maxtime)
    if(t.BytesAvailable > 100)
        received = [received fread(t,t.BytesAvailable,'uint8')'];
        tmpstr = strsplit(char(received),char(10));
        last_index = 0;
        %%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d\r\n
        for i1 = 1:length(tmpstr)
            tmpstr1 = strsplit(tmpstr{i1},',');
            if(length(tmpstr1) ~= 11)
                last_index = i1;
            else
                left_encoder_data(1,i) = str2num(tmpstr1{1});
                right_encoder_data(1,i) = str2num(tmpstr1{2});
                ultrasound_data(1,i) = str2num(tmpstr1{3});
                
                bat_current_data(1,i) = str2num(tmpstr1{8});
                bat_voltage_data(1,i) = str2num(tmpstr1{9});
                bat_cap_data(1,i) = str2num(tmpstr1{10});
                bat_time_data(1,i) = str2num(tmpstr1{11});
                i = i + 1;                
            end
        end
        
        tmp_rec = [];
        
        for i2 = last_index:length(tmpstr)
            tmp_rec = [tmp_rec char(10) tmpstr{i2}];
        end

        received = tmp_rec;
        
        subplot(4,2,1)
        plot(t_x,left_encoder_data);
        title('Left encoder data')
        xlabel('Time [s]')
        ylabel('Left encoder')
        grid on

        subplot(4,2,3)
        plot(t_x,right_encoder_data);
        title('Right encoder data')
        xlabel('Time [s]')
        ylabel('Right encoder')
        grid on

        subplot(4,2,5)
        plot(t_x,ultrasound_data);
        title('Ultrasound sensor data')
        xlabel('Time [s]')
        ylabel('Ultrasound sensor [mm]')
        grid on
        
        subplot(4,2,2)
        plot(t_x,bat_current_data);
        title('Batt current data')
        xlabel('Time [s]')
        ylabel('Batt current [mA]')
        grid on

        subplot(4,2,4)
        plot(t_x,bat_voltage_data);
        title('Batt voltage data')
        xlabel('Time [s]')
        ylabel('Batt voltage [V]')
        grid on

        subplot(4,2,6)
        plot(t_x,bat_cap_data);
        title('Remaining capacity data')
        xlabel('Time [s]')
        ylabel('Remaining capacity [%]')
        grid on
        
        subplot(4,2,8)
        plot(t_x,bat_time_data/60);
        title('Remaining time data')
        xlabel('Time [s]')
        ylabel('Remaining time [mins]')
        grid on

        drawnow
    end
end

message = 'r:0;l:0;';
fwrite(t,message);
fclose(t);




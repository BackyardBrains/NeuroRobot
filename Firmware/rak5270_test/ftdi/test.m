
%%
clear
clc
ftdi = serialport("COM8", 115200)
% configureTerminator(ftdi,"CR/LF");




%%
counter = 0;
this_distance = 300;
incomming_line = string;

while counter < 1000
    counter = counter + 1;
    disp(horzcat(' step ', num2str(counter), ' of 100, distance = ', num2str(this_distance))) 
    while ftdi.NumBytesAvailable
        incomming_line = readline(ftdi);
    end
    these_vals = str2num(incomming_line);
    if ~isempty(these_vals)
        this_duration = these_vals(3);
        this_distance = (this_duration/2) / 29.1;
        this_distance(this_distance == 0) = 300;    
    end
    pause(0.05)
    if rand < 0.1
        l = 200; r = -100; s = 334;
    else
        l = 0; r = 0; s = 0;
    end
    outgoing_line = horzcat('l:', num2str(l), ';', 'r:', num2str(r),';', 's:', num2str(s), ';');
    writeline(ftdi, outgoing_line)
        
end


        
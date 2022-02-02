
% This is part of the hippocampus/SLAM simulation. Not currently active.


stop(rak_pulse)

clearvars  total_dist rak_readout
total_rev=zeros(4,2);  %%will only work for rectangular rooms, but that should be fine

for jj=1:4
    for ii=1:10000 %%how to bound this?
        if total_rev(jj,1)>0
            rak_cam.writeSerial('l:0;r:0;s:0;')
        else 
            
            rak_cam.writeSerial('l:50;r:50;s:0;')%% can adjust speed for larger rooms
            
            pause(0.1)
            rak_readout(ii,:)=str2num(rak_cam.readSerial);
            total_dist(ii,1)=sum(rak_readout(:,1));total_dist(ii,2)=sum(rak_readout(:,2));
            if rak_readout(ii,3)<500%%stop the robot from running into walls
                rak_cam.writeSerial('l:0;r:0;s:0;')
                pause(0.5)
                
                total_rev(jj,:)=total_dist(end,:);
                clearvars total_dist 
                rak_cam.writeSerial('l:-50;r:50;s:0;')
                pause(.5)
            end
        end
    end
end

rak_cam.writeSerial('l:0;r:0;s:0;')
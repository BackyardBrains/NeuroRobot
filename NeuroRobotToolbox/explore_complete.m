

% This is part of the hippocampus/SLAM simulation. Not currently active.


%% script for compiling memory bank of images to then use to navigate
close all

%% this will be much easier if we have the approximate dimensions of the room- maybe start with that?
RoomDim %%get dimensions of the room for the robot

dim1=mean(total_rev(1,:));
dim2=mean(total_rev(2,:));

xfiring=zeros(dim1*dim2,1);
spikes_loop=zeros(dim1,dim2);
draw_placecell_brain

%%how to do this with the encoder values

    xfiring=zeros(dim1*dim2,1);
    spikes_loop=zeros(dim1,dim2);
    
    total_dist(:,1:2)=zeros(floor(dim1*dim2/10),2);
    
    %%how to do this using while
for jj=1:10:floor(dim1*dim2/10)
    
    for ii=1:10
        rak_cam.writeSerial('l:50;r:50;s:0;')%% can adjust speed for larger rooms
        pause(0.1)
        rak_readout(ii,:)=str2num(rak_cam.readSerial);
    end
    %%add up total distance moved forward
    total_dist(jj,1)=sum(rak_readout(:,1));total_dist(jj,2)=sum(rak_readout(:,2));
    
    
    rak_cam.writeSerial('l:0;r:0;s:0;')
    

    rak_cam.writeSerial('l:50;r:50;s:0;')
    pause(0.5)
    rak_cam.writeSerial('l:0;r:0;s:0;')
    pause(0.5)
    
    [large_frame, ~] = get_rak_frame(rak_cam, use_webcam, rak_only);
    memory_images{ii,1}=large_frame;
    
    %for this visualization we can just drive spiking in neuron ii
    xfiring(jj) = 1;
    draw_neuron_core.CData = [1 - xfiring 1 - (xfiring * 0.25) 1 - xfiring] .* neuron_cols;
    %         draw_neuron_edge.CData = [zeros(nneurons, 1) xfiring * 0.5 zeros(nneurons, 1)] .* neuron_cols;
    draw_neuron_edge.CData = [zeros(nneurons, 1) zeros(nneurons, 1) zeros(nneurons, 1)] .* neuron_cols;
    
    sl=reshape(spikes_loop,[],1);
    sl(jj)=1000;spikes_loop=reshape(sl,dim1,dim2);
    
    [y, x] = find(spikes_loop);
    vplot.XData = x;
    vplot.YData = y;
    
    pause(1)
    
    for kk=2:4
        rak_cam.writeSerial('l:-50;r:50;s:0;')
        pause(.5)
        rak_cam.writeSerial('l:0;r:0;s:0;')
        pause(0.5)
        
        xfiring(jj) = 1;
        draw_neuron_core.CData = [1 - xfiring 1 - (xfiring * kk*0.2) 1 - xfiring] .* neuron_cols;
        %         draw_neuron_edge.CData = [zeros(nneurons, 1) xfiring * 0.5 zeros(nneurons, 1)] .* neuron_cols;
        draw_neuron_edge.CData = [zeros(nneurons, 1) zeros(nneurons, 1) zeros(nneurons, 1)] .* neuron_cols;
        
        
        [large_frame, ~] = get_rak_frame(rak_cam, use_webcam, rak_only);
        memory_images{ii,kk}=large_frame;
        
    end
    
    %%how to make this turn the other way every other
    if rak_readout(ii,3)<500 %%stop the robot from running into walls
        if rem(length(find(rak_readout(:,3)),2))==0
            
            rak_cam.writeSerial('l:0;r:0;s:0;')%% can adjust speed for larger rooms
            pause(.5) %%make sure this works
            rak_cam.writeSerial('l:50;r:-50;s:0;')
            pause(.5)
            rak_cam.writeSerial('l:50;r:50;s:0;')%% can adjust speed for larger rooms
            pause(1)
            rak_cam.writeSerial('l:50;r:-50;s:0;')
            pause(.5)
        else
            rak_cam.writeSerial('l:0;r:0;s:0;')%% can adjust speed for larger rooms
            pause(.5) %%make sure this works
            rak_cam.writeSerial('l:-50;r:50;s:0;')
            pause(.5)
            rak_cam.writeSerial('l:50;r:50;s:0;')%% can adjust speed for larger rooms
            pause(1)
            rak_cam.writeSerial('l:-50;r:50;s:0;')
            pause(.5)
        end
        
    end
    

end


rak_cam.writeSerial('l:0;r:0;s:0;')

if ~exist('MemoryImages','dir')
mkdir('MemoryImages')
end
cd('MemoryImages')
if ~exist(date,'dir')
mkdir(date)
else
    delete(date,'*.png')
end
cd(date)

for ii=1:length(memory_images)
   for jj=1:4
   imagename=strcat('mem_image',num2str(ii),'_',num2str(jj),'.png');
   imwrite(memory_images{1,ii}, imagename)
   end
end

imgSet = imageSet(pwd);
MemImages_tocall = indexImages(imgSet);

cd ..
cd ..


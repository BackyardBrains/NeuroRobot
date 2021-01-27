%% where is the robot in space?
%% Probably need to tell Chris that the computer vision toolbox needs to be added to this
close all
clear IDs scores closest_match
use_odometry=0;
stop(rak_pulse)

dlgtitle = 'How long should the robot wander around?';
time_nav= str2double(inputdlg({'time'}));

draw_placecell_brain

    xfiring=zeros(dim1*dim2,1);
    spikes_loop=zeros(dim1,dim2);
    
    if exist('memory_images','var')
        for jj=1:time_nav %%make this an input for how long to randomly walk through the room
            xfiring=zeros(dim1*dim2,1);
            spikes_loop=zeros(dim1,dim2);
            %create a random motor output
            l_output=randi([-100 100],1,1);
            r_output=randi([-100 100],1,1);
            
%             if use_odometry==1
%                for kk=1:time*10
%                    pause(0.001)
%                    rak_readout=str2num(rak_cam.readSerial);
%                    dist(kk,:)=[rak_readout(1),rak_readout(2)];
%                end
%             dist_moved(jj,:)=sum(dist);   
%             end
            
            rak_cam.writeSerial(strcat('l:',num2str(l_output),';r:',num2str(r_output),';s:0;'))
            
            pause(2)
            rak_cam.writeSerial('l:0;r:0;s:0;')
            [large_frame, ~] = get_rak_frame(rak_cam, use_webcam, rak_only);
            %%compare images
            
            [IDs,scores]=retrieveImages(large_frame,MemImages_tocall,'NumResults',Inf);
            if ~isempty(IDs)
            closest_match=memory_images{IDs(1)}; %%display this
            
            xfiring(IDs(1)) = 1;
            draw_neuron_core.CData = [1 - xfiring 1 - (xfiring * 0.25) 1 - xfiring] .* neuron_cols;
            draw_neuron_edge.CData = [zeros(nneurons, 1) zeros(nneurons, 1) zeros(nneurons, 1)] .* neuron_cols;
            else
                disp('This environment does not appear similary enough to my memory') %%how to show this on the GUI?
            end
            pause(.5)
            
        end
        
        
    else
        errordlg('No memory of this environment! CP Wonder needs to explore')
        
    end
%% 

%%have neurorobot navigate to an object
%%choose static object (must be in the current memory bank and be an object the robot can recognize) to navigate to
obj=inputdlg('Which object should CP Wonder navigate to?');

%%make sure you have a memory bank to call and make sure 

if exist('memory_images')
    %%make sure object is in memory bank
    mem_linear=reshape(memory_images,[],1);
    for ii=1:length(mem_linear)
        isinmem(ii)=mem_linear(ii); %%how to access the images the robot is trained on? 
    end

else
    errordlg('No memory of this environment! CP Wonder needs to explore')
end
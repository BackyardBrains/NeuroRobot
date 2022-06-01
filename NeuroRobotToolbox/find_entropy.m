
% todays_recording_id = 1;
% if ~exist('Experiences','dir')
%     mkdir('Experiences')
% end
% cd('MemoryImages')
% this_dir = strcat(date, '_', num2str(todays_recording_id));
% if ~exist(this_dir,'dir')
%     mkdir(this_dir)
% else
%     error('This directory exists')
% end
% cd(date)

imgSet = imageSet('.\Experiences\Recording_2-4\');
MemImages_tocall = indexImages(imgSet);

[IDs,scores] = retrieveImages(large_frame, MemImages_tocall, 'NumResults', Inf);
closest_match=memory_images{IDs(1)}; %%display this
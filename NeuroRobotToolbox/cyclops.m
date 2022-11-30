
%%
data_dir_name = 'C:\Users\Christopher Harris\Dataset2\';
image_dir_name = 'C:\Users\Christopher Harris\Dataset2_cyclops\';
image_dir = dir(fullfile(data_dir_name, '**\*.png'));
nimages = length(image_dir);
ntuples = nimages/2;

%%
for ntuple = 1:ntuples

    if ~rem(ntuple, round(ntuples/100))
        disp(horzcat(num2str(round(100*(ntuple/ntuples))), ' %'))
    end

    this_ind = ntuple*2-1;
    left_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));

    this_ind = ntuple*2;
    right_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));

    new_frame = zeros(227, 404, 3, 'uint8');
    new_frame(:, 1:227, :) = left_im;
    new_frame(:, 178:404, :) = right_im;
    
    fname = strcat(image_dir_name, image_dir(this_ind).name(1:end-16), 'uframe.png');

    imwrite(new_frame, fname);    
        
end

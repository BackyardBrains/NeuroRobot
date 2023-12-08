
disp('Getting images...')
if get_images
    image_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*_x.png'));
    save(strcat(nets_dir_name, net_name, '-image_dir'), 'image_dir')
else
    load(strcat(nets_dir_name, net_name, '-image_dir'))
end

nimages = size(image_dir, 1);
ntuples = nimages;
disp(horzcat('nimages / ntuples: ', num2str(ntuples)))


image_dir = dir(fullfile('.\Data_3\', '**\*.mat'));
nfiles = size(image_dir, 1);
for n = 1:nfiles
    n/nfiles
    if n <= 40000
        movefile(strcat('.\Data_3\Rec_2\', image_dir(n).name), '.\Data_3\Rec_3\')
    elseif n <= 80000
        movefile(strcat('.\Data_3\Rec_2\', image_dir(n).name), '.\Data_3\Rec_4\')
    end
end



this_cat = '6W\';
this_rec = 'Rec_2\';
this_root = '.\Data_1\';

dir(this_root)

movefile(strcat(this_root, '*.png'), strcat(this_root, this_rec, this_cat))
movefile(strcat(this_root, '*.mat'), strcat(this_root, this_rec, this_cat))

disp(horzcat('^^^ this data was moved to ', this_root, this_rec, this_cat))
disp(horzcat('vvv this data left in ', this_root))
dir(this_root)


% delete('.\Data_1\*.png')
% delete('.\Data_1\*.mat')
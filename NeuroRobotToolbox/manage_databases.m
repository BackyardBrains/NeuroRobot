


% this_cat = '6W\';
this_rec = 'Rec_1\';
this_root = '.\Data_3\';

dir(this_root)

movefile(strcat(this_root, '*.png'), strcat(this_root, this_rec))
movefile(strcat(this_root, '*.mat'), strcat(this_root, this_rec))

% movefile(strcat(this_root, '*.png'), strcat(this_root, this_rec, this_cat))
% movefile(strcat(this_root, '*.mat'), strcat(this_root, this_rec, this_cat))

% disp(horzcat('^^^ this data was moved to ', this_root, this_rec, this_cat))
disp(horzcat('^^^ this data was moved to ', this_root, this_rec))
disp(horzcat('vvv this data left in ', this_root))
dir(this_root)


% delete('.\Data_1\*.png')
% delete('.\Data_1\*.mat')
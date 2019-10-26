this_time = string(datetime('now', 'Format', 'yyyy-MM-dd-hh-mm-ss-ms'));
annotation_file_name = strcat('.\Annotation\', this_time, '-', 'v', '.mat');
annotation = struct;
annotation.computer_name = computer_name;
annotation.this_time = this_time;
annotation.annotation = 'Text input from human user here';
% save the annotation

% screenshot
annotation_jpg_name = strcat('annotation_', this_time, '-', brain_name, '-', computer_name, '.jpg');
export_fig(gcf, char(annotation_jpg_name), '-r300', '-jpg', '-nocrop')
disp('annotation created')

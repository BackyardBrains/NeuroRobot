

% this_lim = 3000;
this_lim = 150000;

for nrec = 1:nrecs
    this_dir_name = strcat(dataset_dir_name, available_dirs(nrec).name);
    these_files = dir(this_dir_name);
    these_files(1:2) = [];
    nfiles = length(these_files);
    if nfiles > this_lim
        these_files = these_files(1:this_lim);
        this_new_dir_name = strcat(this_dir_name, 'Cut');
        mkdir(this_new_dir_name)
        for nfile = 1:this_lim
            if ~rem(nfile, round(nfiles/20))
                disp(horzcat('Process: ', num2str(round(100 * ((nfile)/this_lim))), ' %'))
            end
            movefile(strcat(these_files(nfile).folder, '\', these_files(nfile).name), this_new_dir_name)            
        end
        disp(horzcat('Cut this large dir in two: ', available_dirs(nrec).name))
    else
        disp(horzcat('This dir was too small to cut: ', available_dirs(nrec).name))
    end
end

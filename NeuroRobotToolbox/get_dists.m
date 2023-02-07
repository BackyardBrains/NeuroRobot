
dists = zeros(nmedium, 1);
disp(horzcat('getting ', num2str(nmedium), ' dists'))

for ntuple = 1:nmedium

    if ~rem(ntuple, round(nmedium/20))
        disp(num2str(ntuple/nmedium))
    end

    this_ind = medium_inds(ntuple);
    serial_fname = horzcat(serial_dir(this_ind).folder, '\', serial_dir(this_ind).name);
    load(serial_fname)
    this_distance = str2double(serial_data{3});
    this_distance(this_distance == Inf) = 0;    

    dists(ntuple, :) = this_distance;

end




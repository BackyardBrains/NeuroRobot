
dists = zeros(ntuples, 1);
disp(horzcat('getting ', num2str(ntuples), ' dists'))

for ntuple = 1:ntuples

    if ~rem(ntuple, round(ntuples/10))
        disp(num2str(ntuple/ntuples))
    end

    serial_fname = horzcat(serial_dir(ntuple).folder, '\', serial_dir(ntuple).name);
    load(serial_fname)
    this_distance = str2double(serial_data{3});
    this_distance(this_distance == Inf) = 0;
    this_distance(this_distance == 4000) = 0;

    dists(ntuple) = this_distance;

end

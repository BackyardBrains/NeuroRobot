
xys = zeros(2, ntuples);
rblob = zeros(2, ntuples);
gblob = zeros(2, ntuples);

disp(horzcat('getting ', num2str(ntuples), ' xyos'))

for ntuple = 1:ntuples

    if ~rem(ntuple, round(ntuples/10))
        disp(num2str(ntuple/ntuples))
    end

    ext_fname = horzcat(ext_dir(ntuple).folder, '\', ext_dir(ntuple).name);
    load(ext_fname)

    robot_xy = ext_data.robot_xy;
    rblob_xy = ext_data.rblob_xy;    
    gblob_xy = ext_data.gblob_xy;    
    
    xys(:, ntuple) = robot_xy;
    rblob(:, ntuple) = rblob_xy;
    gblob(:, ntuple) = gblob_xy;


end

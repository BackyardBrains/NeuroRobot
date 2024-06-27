
thetas = zeros(ntuples, 1);
robot_xys = zeros(ntuples, 2);

x1 = 0;
y1 = 0;
x2 = 1;
y2 = 1;

for ntuple = 1:ntuples

    if ~rem(ntuple, round(ntuples/10))
        disp(horzcat(num2str(round(100*(ntuple/ntuples))), '%'))
    end

    ext_fname = horzcat(ext_dir(ntuple).folder, '\', ext_dir(ntuple).name);
    load(ext_fname)

    robot_xy = ext_data.robot_xy;
    rblob_xy = ext_data.rblob_xy;    
    gblob_xy = ext_data.gblob_xy;    

    x1 = rblob_xy(1);
    y1 = rblob_xy(2);
    x2 = gblob_xy(1);
    y2 = gblob_xy(2);

    robot_xys(ntuple, :) = robot_xy;

    sepx = x1-x2;
    sepy = y1-y2;

    theta = mod(atan2d(sepy,sepx),360); 
    thetas(ntuple) = theta;

end

allx = robot_xys(:,1);
ally = robot_xys(:,2);

xlim1 = prctile(allx, 5);
xlim2 = prctile(allx, 95);
n1 = sum(allx < xlim1 | allx > xlim2);
ns = randsample(xlim1:xlim2, n1, 1);
allx(allx < xlim1 | allx > xlim2) = ns;

ylim1 = prctile(ally, 5);
ylim2 = prctile(ally, 95);
n1 = sum(ally < ylim1 | ally > ylim2);
ns = randsample(ylim1:ylim2, n1, 1);
ally(ally < ylim1 | ally > ylim2) = ns;

xlims = round(linspace(xlim1,xlim2,4));
ylims = round(linspace(ylim1,ylim2,4));
disp(horzcat('xlims: ', num2str(xlims)))
disp(horzcat('ylims: ', num2str(ylims)))


states = zeros(ntuples, 1);
disp(horzcat('Getting ', num2str(ntuples), ' states from camera frames'))

for ntuple = 1:ntuples

    if ~rem(ntuple, round(ntuples/10))
        disp(horzcat('Counter: ', num2str(round(100*(ntuple/ntuples))), '%, ntuple: ', num2str(ntuple)))
    end

    try
        this_im = imread(strcat(image_dir(ntuple).folder, '\',  image_dir(ntuple).name));
    catch
        disp(strcat('Cannot read image ', num2str(ntuple)))
    end
    [this_state, this_score] = classify(net, this_im);
    this_state = find(labels == this_state);
    states(ntuple) = this_state;

end

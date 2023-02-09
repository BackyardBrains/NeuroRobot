
imdim = 100;
states = zeros(ntuples, 1);
disp(horzcat('Getting ', num2str(ntuples), ' states from camera frames (slow, be patient...)'))

for ntuple = 1:ntuples

    if ~rem(ntuple, round(ntuples/100))
        disp(horzcat('Counter: ', num2str(round(100*(ntuple/ntuples))), '%, ntuple: ', num2str(ntuple)))
    end
 
    this_im = imread(strcat(image_dir(ntuple).folder, '\',  image_dir(ntuple).name));
    this_im = imresize(this_im, [imdim round(404*0.44)]);

    [state, scores] = classify(net, this_im);
    this_state = find(unique_states == state);

%     if dists(ntuple) > 0
        states(ntuple) = this_state;
%     else
%         states(ntuple) = this_state + n_unique_states;
%     end

end
% n_unique_states = n_unique_states * 2;


gnet = googlenet;
net_input_size = gnet.Layers(1).InputSize(1:2);
labels = readcell('alllabels.txt');
object_ns = [47, 292, 418, 969, 447, 479, 527, 606, 621, 771, 847, 951, 955];
object_strs = labels(object_ns);
vis_pref_names = [basic_vis_pref_names, object_strs'];  
if use_custom_net % Cant handle regression nets
    load(strcat(nets_dir_name, state_net_name, '-labels'))
    unique_states = unique(labels);
    n_unique_states = length(unique_states);
    vis_pref_names = [vis_pref_names, labels'];
end
regression_flag = 0;
n_vis_prefs = size(vis_pref_names, 2);
trained_nets{1} = 'GoogLeNet';

gnet = googlenet;
net_input_size = gnet.Layers(1).InputSize(1:2);
labels = readcell('alllabels.txt');
object_ns = [47, 292, 418, 969, 447, 479, 527, 606, 621, 771, 847, 951, 955];
object_strs = labels(object_ns);
vis_pref_names = [basic_vis_pref_names, object_strs']; 
n_vis_prefs = size(vis_pref_names, 2);
trained_nets{1} = 'GoogLeNet';
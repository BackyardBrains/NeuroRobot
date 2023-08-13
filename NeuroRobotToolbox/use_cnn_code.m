net = googlenet;
net_input_size = net.Layers(1).InputSize(1:2);
labels = readcell('alllabels.txt');
object_ns = [47, 292, 418, 969, 447, 479, 527, 606, 621, 771, 847, 951, 955];
object_strs = labels(object_ns);
vis_pref_names = [vis_pref_names, object_strs'];  
regression_flag = 0;
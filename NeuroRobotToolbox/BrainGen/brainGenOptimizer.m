

close all
clear
clc

load bursting_brain

this_in = zeros(204, 200);
this_in(1,:) = a;
this_in(2,:) = b;
this_in(3,:) = c;
this_in(4,:) = d;
this_in(5:end,:) = connectome;

nneurons = size(a, 1);

% brainSimOpt(this_in)

options = optimset('MaxIter', 10, 'MaxFunEvals', 10, 'Display', 'Iter','PlotFcns',@optimplotfval, 'FunValCheck', 'on');
[x,fval,exitflag,output] = fminsearch(@brainSimOpt, this_in, options)
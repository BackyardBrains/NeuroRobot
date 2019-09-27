
% Search Optimization
% Multidimensional unconstrained nonlinear minimization (Nelder-Mead)
% Example:
% fun = @(x) 5*x(1)/(3*x(2)-2)
% ans = fminsearch(fun, [4 2])

% This start point in search space
this_point = [2 5];


% Find local minimum
fun = @test_fun;
local_min_point = fminsearch(fun, this_point);




x0 = [0.25,-0.25];
x = fminsearch(@objectivefcn1,x0)
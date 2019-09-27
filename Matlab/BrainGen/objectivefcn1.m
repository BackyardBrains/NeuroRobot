function [s, f] = objectivefcn1(x)
f = (5 * x(1) + 16) + 2 * (x(2) - 20);
s = 3;
% f = 0;
% for k = -10:10
%     f = f + exp(-(x(1)-x(2))^2 - 2*x(1)^2)*cos(x(2))*sin(2*x(2));
% end
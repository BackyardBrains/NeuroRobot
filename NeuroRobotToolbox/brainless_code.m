l = [-100 0 100];
r = [100 0 -100];
x_deg = [-60 0 60];
x_px = [1 202 404];

figure(5)
clf

xx = sigmoid(1:404, 404 / 2, 0.01);
plot(xx)

% plot(x_px, l, 'color', [0.2 0.4 0.8])
% hold on
% plot(x_px, r, 'color', [0.8 0.4 0.2])

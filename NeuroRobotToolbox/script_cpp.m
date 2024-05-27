function [l, r] = script_cpp(x, y, o)

x1 = 300;
y1 = 400;

sepx = x-x1;
sepy = y-y1;

main_angle = mod(atan2d(sepy,sepx),360);
diff_angle = main_angle - o;
disp(num2str(diff_angle))

diff_dist = sqrt((x-x1)^2+(y-y1)^2);

if diff_dist > 10
    if diff_angle > 10 && diff_angle <= 180
        l = -30; % left turn
        r = 30;        
    elseif diff_angle < -10 || diff_angle > 180
        l = 30; % left turn
        r = -30;        
    else
        l = 50; % left turn
        r = 50;
    end
else
    l = 0; % stop, maybe blink and beep
    r = 0;
end

l = l * 2.5;
r = r * 2.5;


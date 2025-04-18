function [l, r] = script_cpp(x, y, o)

this_sec = second(datetime);
if this_sec <= 30
    x1 = 210;
    y1 = 140;
else
    x1 = 460;
    y1 = 360;
end

sepx = x-x1;
sepy = y-y1;

main_angle = mod(atan2d(sepy,sepx),360);
diff_angle = main_angle - o;

diff_dist = sqrt((x-x1)^2+(y-y1)^2);

if diff_dist > 40
    if diff_angle > 20 && diff_angle <= 180
        l = -30; % left turn
        r = 30;        
    elseif diff_angle < -20 || diff_angle > 180
        l = 30; % left turn
        r = -30;        
    else
        l = 50;
        r = 50;
    end
else
    l = 0; % stop, maybe blink and beep
    r = 0;
end

disp(horzcat('x: ', num2str(x), ', y: ', num2str(y), ', o: ', num2str(o), ...
    'diff dist: ', num2str(diff_dist), ', diff angle: ', ...
    num2str(diff_angle), ', left: ', num2str(l), ', right: ', num2str(r)))

l = l * 2.5;
r = r * 2.5;


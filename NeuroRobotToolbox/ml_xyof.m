
goal_x = 300;
goal_y = 300;
goal_o = 180;

% [curr_x, curr_y, curr_o] = predict(xyoNet, double(im));

curr_x = 200;
curr_y = 200;

sepx = curr_x - goal_x;
sepy = curr_y - goal_y;

trav_o = mod(atan2d(sepy,sepx),360)


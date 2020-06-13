amp=0.5;
fs=8000;
duration=2;
freq=200;
values=0:1/fs:duration;
a=amp*sin(2*pi* freq*values);
sound(a)
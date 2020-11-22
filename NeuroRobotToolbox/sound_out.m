amp=0.2;
fs=8000;
duration=2;
freq=2000;
values=0:1/fs:duration;
a=amp*sin(2*pi* freq*values);
sound(a)
amp=10 ;
fs=8000;
duration=2;
freq=500;
values=0:1/fs:duration;
a=amp*sin(2*pi* freq*values);
sound(a)
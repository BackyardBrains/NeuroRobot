amp=0.02 ;
fs=8000;
duration=2;
freq=400;
values=0:1/fs:duration;
a=amp*sin(2*pi* freq*values);
sound(a)
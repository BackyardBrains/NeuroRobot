

recObj = audiorecorder(32000, 16, 1);
recordblocking(recObj,0.5)

doubleArray = getaudiodata(recObj);
plot(doubleArray)
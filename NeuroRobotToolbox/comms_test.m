% googleSpeechClient = speechClient('Google');

[y,fs] = audioread('speech_dft.mp3');

transcript = speech2text(googleSpeechClient,y,fs)
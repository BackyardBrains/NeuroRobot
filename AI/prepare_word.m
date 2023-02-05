this_phrase = 'Hello';
hello_wav_m = tts(this_phrase,'Microsoft David Desktop - English (United States)',[],16000);
hello_wav_f = tts(this_phrase,'Microsoft Zira Desktop - English (United States)',[],16000);
if length(hello_wav_m) > length(hello_wav_f)
    hello_wav_m = hello_wav_m(1:length(hello_wav_f));
else
    hello_wav_f = hello_wav_f(1:length(hello_wav_m));
end
hello_wav = hello_wav_f + hello_wav_m;
hello_wav = hello_wav(find(hello_wav,1,'first'):find(hello_wav,1,'last'));
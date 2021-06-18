this_phrase = 'Hello';
disp(this_phrase)
this_wav_m = tts(this_phrase,'Microsoft David Desktop - English (United States)',[],16000);
this_wav_f = tts(this_phrase,'Microsoft Zira Desktop - English (United States)',[],16000);
if length(this_wav_m) > length(this_wav_f)
    this_wav_m = this_wav_m(1:length(this_wav_f));
else
    this_wav_f = this_wav_f(1:length(this_wav_m));
end
this_wav = this_wav_f + this_wav_m;
this_wav = this_wav(find(this_wav,1,'first'):find(this_wav,1,'last'));
soundsc(this_wav, 16000);
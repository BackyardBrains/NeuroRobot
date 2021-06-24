function vocalize_this(this_phrase)

tic

disp(this_phrase)

this_wav_m = tts(this_phrase,'Microsoft David Desktop - English (United States)',[],16000);
this_wav_f = tts(this_phrase,'Microsoft Zira Desktop - English (United States)',[],16000);

this_wav_m = this_wav_m(find(abs(this_wav_m) > 0.01,1,'first'):find(abs(this_wav_m) > 0.01,1,'last'));
this_wav_f = this_wav_f(find(abs(this_wav_f) > 0.01,1,'first'):find(abs(this_wav_f) > 0.01,1,'last'));

if length(this_wav_m) > length(this_wav_f)
    this_wav_fx = interp1(1:length(this_wav_f), this_wav_f, linspace(1, length(this_wav_f), length(this_wav_m)));
    this_wav_fx = this_wav_fx';
    this_wav = this_wav_fx + this_wav_m;
else
    this_wav_mx = interp1(1:length(this_wav_m), this_wav_m, linspace(1, length(this_wav_m), length(this_wav_f)));
    this_wav_mx = this_wav_mx';
    this_wav = this_wav_f + this_wav_mx;    
end

soundsc(this_wav, 16000);

disp(horzcat('Time to vocalize: ', num2str(round(toc)), ' sec'))

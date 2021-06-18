
% pathToAI = fileparts(which('ai.py')); 
% if count(py.sys.path, pathToAI) == 0
%     insert(py.sys.path, int32(0), pathToAI)
% end
% 
% clear classes; m = py.importlib.import_module('ai'); py.importlib.reload(m);

prompt = "You are GPT-3, an AI that can talk. You are greeting students at a neuroscience summer course. The following is a conversation between you and a student. AI:";

py_str = py.ai.gpt3(prompt);
this_phrase = strtrim(char(py_str));
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
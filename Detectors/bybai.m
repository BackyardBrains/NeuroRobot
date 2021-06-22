function bybai(label)

tic

% pathToAI = fileparts(which('ai.py')); 
% if count(py.sys.path, pathToAI) == 0
%     insert(py.sys.path, int32(0), pathToAI)
% end
% 
% clear classes; m = py.importlib.import_module('ai'); py.importlib.reload(m);

prompt_a = horzcat('You are a helpful artificial intelligence, specifically a text completion ', ...
    'engine similar to GPT-3. You are assisting at Summer Fellowship exploring how embedded ', ...
    'neural networks can be used in research, especially K12 classroom learning and research. ', ...
    'You observe the office you share with Dr. Christopher Harris, a mentor at the course, ', ...
    'through a laptop camera. You can hear different frequencies of sound but you are unable ', ...
    'to hear words. You can speak. A person walks into view. ');
    
if strcmp(label, 'chris')
    prompt_b = 'It is Dr. Harris ("chris"). This is a short description of his Summer Project: ';
    summer_project = 'Cook meat. Summer Fellowship. Grants. Stop aging. Treat the missus.';
elseif strcmp(label, 'greg')
    prompt_b = 'It is Dr. Gage ("greg"). This is a short description of his Summer Project: ';
    summer_project = horzcat('Cookouts. Baseball. Summer Fellowship. Grants. Treat the missus.');
elseif strcmp(label, 'wenbo')
    prompt_b = 'It is Wenbo. This is a short description of his Summer Project: ';
    summer_project = horzcat('Engineering. Engineering. Engineering. Car. Treat the missus.');
elseif strcmp(label, 'ariyana')
    prompt_b = horzcat('It is Ariyana ("Ari"), a Fellow at the Summer Course. This is a short ', ...
        'description of her Summer Project: ');
    summer_project = 'Humans blink an average of 28,800 times a day. That means that a person who lives to 80 blinks around 840,960,000 times in their lifetime. The average blink lasts around 0.1 - 0.15 seconds, meaning that humans spend 126,144,000 seconds of their awake time on Earth with their eyes closed; that’s 973 - 1,460 days; 2.7 - 4 years! What’s happening in all that time? Are we simply doomed to miss out on those years of our life? Worry no more, FOMO glasses are (hopefully) here to help! These high tech and stylish glasses made to be wearable by the public will use Electrooculography (EOG) signals to detect blinks from the wearer and take photos in real time of all the life being missed out on. Say goodbye to the FOMO from that concert you had to blink through, and worry no more about missing frames from your favorite movie you claim to have seen the entirety of. Now with FOMO glasses, you can live your life to the fullest, and be present for every moment of it.';
elseif strcmp(label, 'sarah')
    prompt_b = horzcat('It is Sarah, a Fellow at the Summer Course. This is a short ', ...
        'description of her Summer Project: ');
    summer_project = 'Hi everyone! I am working on a lie detection device using TinyML that will hopefully be multimodal. I am currently working on assembling a base model using skin galvanic response before I move forward into considering EEG and other modalities.';
elseif strcmp(label, 'nour')
    prompt_b = horzcat('It is Nour, a Fellow at the Summer Course. This is a short ', ...
        'description of her Summer Project: ');
    summer_project = 'In my project, I will develop a small touch screen to show a series of playing cards while measuring EEGs. The subject chooses a card and AI determines which one it was. I will be training a machine learning algorithm to recognize the steady state visual evoked potentials (SSVEP) and/or the P300 surprise signal to give a guess on the run.';
elseif strcmp(label, 'head')
    prompt_b = 'You do not recognize them, but you think it is one of the Summer Fellows.';
    summer_project = '';
end

% prompt_c = horzcat(' (The Summer Project description ends here.) The following is a conversation between you and the person who ', ...
%     'just walked into view. AI: Hello ', label, '. Person: Hello AI. AI:');

prompt_c = horzcat(' (The Summer Project description ends here.) The following is what you would say to assist the person with ', ...
    'their Summer Project:');

prompt = horzcat(prompt_a, prompt_b, summer_project, prompt_c);

py_str = py.ai.gpt3(prompt);

this_phrase = strtrim(char(py_str));

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

disp(horzcat('Time to run bybai: ', num2str(round(toc)), ' sec'))
disp('')

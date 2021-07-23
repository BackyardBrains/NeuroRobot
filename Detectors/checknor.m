


%%
this_person = 2;

prompt_a = horzcat('You are a friendly, insightful Artificial Intelligence. You are assisting at a ', ...
    'Summer Fellowship in neuroscience and AI hosted by Backyard Brains. The Fellowship is taking place in ', ...
    'Ann Arbor, Michigan, throughout June and July, 2021. Your goal is to write a helpful 500 word Summer Project Analysis for ');

if this_person == 1
    this_person = 'Ariyana';
    prompt_b = ', a Fellow at the Summer Fellowship. This is a short description of her Summer Project: ';
    summer_project = 'Humans blink an average of 28,800 times a day. That means that a person who lives to 80 blinks around 840,960,000 times in their lifetime. The average blink lasts around 0.1 - 0.15 seconds, meaning that humans spend 126,144,000 seconds of their awake time on Earth with their eyes closed; that’s 973 - 1,460 days; 2.7 - 4 years! What’s happening in all that time? Are we simply doomed to miss out on those years of our life? Worry no more, FOMO glasses are (hopefully) here to help! These high tech and stylish glasses made to be wearable by the public will use Electrooculography (EOG) signals to detect blinks from the wearer and take photos in real time of all the life being missed out on. Say goodbye to the FOMO from that concert you had to blink through, and worry no more about missing frames from your favorite movie you claim to have seen the entirety of. Now with FOMO glasses, you can live your life to the fullest, and be present for every moment of it.';
elseif this_person == 2
    this_person = 'Chris';
    prompt_b = ', a research scientist at Backyard Brains. This is a short description of his Summer Project: ';
    summer_project = '1) develop a production-ready low-cost neurorobot, the SpikerBot, with an associated software application that can run on all platforms and devices, 2) develop teacher onboarding materials, expand our curriculum to 10 lessons (including NGSS-aligned learning objectives, scaffolded activities, and assessments, as well as instructor guidance and demonstrations), and 3) perform teacher professional development workshops in collaboration with 3 science museums to ensure that teachers of all backgrounds and levels of experience are comfortable teaching neuroscience with SpikerBots.';
%     summer_project = 'Cook meat. Help with the Summer Fellowship. Get grants. Stop the aging process. Treat the missus.';
elseif this_person == 3
    this_person = 'Nour';
    prompt_b = ', a Fellow at the Summer Fellowship. This is a short description of her Summer Project: ';
    summer_project = 'In my project, I will develop a small touch screen to show a series of playing cards while measuring EEGs. The subject chooses a card and AI determines which one it was. I will be training a machine learning algorithm to recognize the steady state visual evoked potentials (SSVEP) and/or the P300 surprise signal to give a guess on the run.';
elseif this_person == 4
    this_person = 'Sarah';
    prompt_b = horzcat(', a Fellow at the Summer Fellowship. This is a short description of her Summer Project: ');
    summer_project = 'Hi everyone! I am working on a lie detection device using TinyML that will hopefully be multimodal. I am currently working on assembling a base model using skin galvanic response before I move forward into considering EEG and other modalities.';
elseif this_person == 5
    this_person = 'Wenbo';
    prompt_b = ', an Engineer at Backyard Brains. This is a short description of his Summer Project: ';
    summer_project = 'Engineering. Engineering. Engineering. Car. Treat the missus.';
end

prompt_c = horzcat(' (The description of the Summer Project ends here.) The Summer Project Analysis ', ...
    'should contain creative ideas and advice. A "Stream of Consciousness" writing ', ...
    'style is highly encouraged.\n\n', ...
    '--- The Summer Project Analysis begins here ---\n\n');

prompt = horzcat(prompt_a, this_person, prompt_b, summer_project, prompt_c);

%%
fig1 = figure(1);
clf
c = uicontrol('Style', 'text', 'String', '', 'units', 'normalized', 'position', [0.05 0.05 0.9 0.9], 'fontsize', 11, 'horizontalalignment', 'left');

%%
nstep = 0;
x = 1;
xprompt = '';
clc
while x
    
    nstep = nstep + 1;
%     disp(horzcat('nstep: ', num2str(nstep)))
    
    py_str = py.ai.gpt3(prompt);
    ai_says = strtrim(char(py_str));
    linebreaks = strfind(ai_says, '.');
    if ~isempty(linebreaks) && linebreaks(1) < length(ai_says)
        ai_says = ai_says(1:linebreaks(1));
%         disp('Cropped')
    end
    if nstep > 1
        ai_says = horzcat(' ', ai_says);
    end
        
    if nstep > 1
        x = input('>>> continue? 1 = yes, 0 = no >>> ');
    end
    
    if x
        
        disp(ai_says)
        
        xprompt = append(xprompt, ai_says);        
        c.String = xprompt;
        
        prompt = append(prompt, ai_says);
        
        linebreaks = strfind(ai_says, '\n');
        for ii = length(linebreaks):-1:1
            ai_says(ii:ii+1) = [];
        end
        drawnow
        vocalize_this(ai_says)
        
    end
end


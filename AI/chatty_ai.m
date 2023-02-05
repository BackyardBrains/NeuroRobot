
%%
close all
clear
clc

all_says = "";

prompt = horzcat('You are a friendly, insightful artificial intelligence. The following is a ', ...
    'monologue in which you provide Chris, your AI maintainenance guy, with useful information about koalas.', ...
    '\n\n--- The monologue begins here ---\n\n');

%%

delay = 0;
tic
for ii = 1:3

    py_str = py.ai.gpt3(prompt);
    ai_says = strtrim(char(py_str));
    linebreaks = strfind(ai_says, '\n');
    if ~isempty(linebreaks)
        ai_says(linebreaks(1):end) = [];
    end
    if ~isempty(ai_says)
        while toc < 10
            pause(0.01)
        end
        tic
        vocalize_this(ai_says)
    end
    disp(horzcat('AI says: ', ai_says))
    prompt = append(prompt, ' ', ai_says);
    all_says = append(all_says, ' ', ai_says);

end  


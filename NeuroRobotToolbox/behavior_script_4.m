
% clear classes; m = py.importlib.import_module('ai'); py.importlib.reload(m);

prompt_a = horzcat('You are a helpful artificial intelligence, specifically a text completion ', ...
    'engine similar to GPT-3. You are assisting at a Summer Fellowship exploring how embedded ', ...
    'neural networks can be used in research and education.\n\nThe following is a conversation ', ...
    'between you and ');
                
this_person = 'Dr. Harris';

prompt_b = ', your AI maintenance guy. This is a short description of his Summer Project: ';

summer_project = 'Cook meat. Summer Fellowship. Grants. Stop aging. Treat the missus.';            

prompt_c = horzcat(' (The description of the Summer Project ends here.)\n\n--- The dialog begins ',...
    'here ---\nHuman: Hello, who are you?\nAI: I am an artificial intelligence created by OpenAI ',...
    'and Backyard Brains. How can I help you today?');

human_says = 'Please tell me something interesting about the brain.';

prompt_d = horzcat('\nHuman: ', human_says);

prompt = horzcat(prompt_a, this_person, prompt_b, summer_project, prompt_c, prompt_d, '\nAI:');
                    
py_str = py.ai.gpt3(prompt);
ai_says = strtrim(char(py_str));
linebreaks = strfind(ai_says, '\n');
if ~isempty(linebreaks)
    ai_says(linebreaks(1):end) = [];
end

disp(horzcat('AI says: ', ai_says))
vocalize_this(ai_says)


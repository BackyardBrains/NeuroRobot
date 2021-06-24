function bybai2(prompt)

tic

% clear classes; m = py.importlib.import_module('ai'); py.importlib.reload(m);

py_str = py.ai.gpt3(prompt);

this_phrase = strtrim(char(py_str));

disp(horzcat('Time to run GPT-3: ', num2str(round(toc)), ' sec'))

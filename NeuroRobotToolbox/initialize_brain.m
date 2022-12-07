if ~isempty(brain_edit_name.String)
    new_brain_vars
    brain_name = strcat(brain_edit_name.String);
else
    brain_edit_name.BackgroundColor = [1 0.25 0.25];
    pause(0.75)
    brain_edit_name.BackgroundColor = [0.94 0.94 0.94];
end
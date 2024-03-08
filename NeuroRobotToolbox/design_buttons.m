
button1_pos = [0.02 0.47 0.26 0.05];
button2_pos = [0.02 0.4 0.26 0.05];
button3_pos = [0.02 0.33 0.26 0.05];
button4_pos = [0.02 0.26 0.26 0.05];
button5_pos = [0.02 0.19 0.26 0.05];
button6_pos = [0.02 0.12 0.26 0.05];
button7_pos = [0.02 0.05 0.26 0.05];

% Add neuron
button_add_neuron = uicontrol('Style', 'pushbutton', 'String', 'Neuron', 'units', 'normalized', 'position', button1_pos, 'fontname', gui_font_name, 'fontweight', gui_font_weight);
set(button_add_neuron, 'Callback', 'if fig_design.UserData == 0 button_add_neuron.BackgroundColor = [0.6 0.95 0.6]; neuron_or_network = 1; multi_neuron_opt = 0; end;', 'FontSize', bfsize + 4, 'BackgroundColor', [0.8 0.8 0.8])
    
% Add many neurons
button_add_population = uicontrol('Style', 'pushbutton', 'String', 'Population', 'units', 'normalized', 'position', button2_pos, 'fontname', gui_font_name, 'fontweight', gui_font_weight);
set(button_add_population, 'Callback', 'if fig_design.UserData == 0 button_add_population.BackgroundColor = [0.6 0.95 0.6]; neuron_or_network = 2; multi_neuron_opt = 1; end;', 'FontSize', bfsize + 4, 'BackgroundColor', [0.8 0.8 0.8])

% Add neurons using maths (netalgo)
button_add_algorithm = uicontrol('Style', 'pushbutton', 'String', 'Algorithm', 'units', 'normalized', 'position', button3_pos, 'fontname', gui_font_name, 'fontweight', gui_font_weight);
set(button_add_algorithm, 'Callback', 'if fig_design.UserData == 0 button_add_algorithm.BackgroundColor = [0.6 0.95 0.6]; neuron_or_network = 2; multi_neuron_opt = 2; end;', 'FontSize', bfsize + 4, 'BackgroundColor', [0.8 0.8 0.8])
set(button_add_algorithm, 'enable', 'off')

% Add Trained Networks
button_add_agents = uicontrol('Style', 'pushbutton', 'String', 'Import Trained Network', 'units', 'normalized', 'position', button4_pos, 'fontname', gui_font_name, 'fontweight', gui_font_weight);
set(button_add_agents, 'Callback', 'if fig_design.UserData == 0 button_add_agents.BackgroundColor = [0.6 0.95 0.6]; button_add_neuron.BackgroundColor = [0.8 0.8 0.8]; neuron_or_network = 2; multi_neuron_opt = 3; end;', 'FontSize', bfsize + 4, 'BackgroundColor', [0.8 0.8 0.8])

% Brain 2 Circuit
button_add_brain = uicontrol('Style', 'pushbutton', 'String', 'Import Brain', 'units', 'normalized', 'position', button5_pos, 'fontname', gui_font_name, 'fontweight', gui_font_weight);
set(button_add_brain, 'Callback', 'if fig_design.UserData == 0 button_add_brain.BackgroundColor = [0.6 0.95 0.6]; button_add_neuron.BackgroundColor = [0.8 0.8 0.8]; neuron_or_network = 2; multi_neuron_opt = 4; end;', 'FontSize', bfsize + 4, 'BackgroundColor', [0.8 0.8 0.8])
if nneurons == 0
    set(button_add_brain, 'enable', 'off')
else
    set(button_add_brain, 'enable', 'on')
end

% Save brain
button_save = uicontrol('Style', 'pushbutton', 'String', 'Save', 'units', 'normalized', 'position', button6_pos);
set(button_save, 'Callback', 'save_brain', 'FontSize', bfsize + 4, 'FontName', gui_font_name, 'FontWeight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])

% Return to runtime
button_return_to_runtime = uicontrol('Style', 'pushbutton', 'String', 'Runtime', 'units', 'normalized', 'position', button7_pos);
set(button_return_to_runtime, 'Callback', 'if fig_design.UserData == 0 fig_design.UserData = 10; exit_design; end', 'FontSize', bfsize + 4, 'FontName', gui_font_name, 'FontWeight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])

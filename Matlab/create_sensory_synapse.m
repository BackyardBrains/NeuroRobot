
% If no other design action is in progress
if fig_design.UserData == 0 && ~exist('presynaptic_neuron', 'var') && nneurons
    
    % Set current design action
    fig_design.UserData = 6;

    % Find the current input contact
    mouse_location = get(gca, 'CurrentPoint');
    x = mouse_location(1,1);
    y = mouse_location(1,2);
    for ncontact = [1 2 3 5]
        xdist = contact_xys(ncontact, 1) - x;
        ydist = contact_xys(ncontact, 2) - y;  
        sdist = sqrt(xdist^2 + ydist^2);        
        if sdist < 0.2        
            presynaptic_contact = ncontact;
            contact_h(ncontact).MarkerFaceColor = sel_col_core;
        end
    end
    
    % Text heading
    text_heading = uicontrol('Style', 'text', 'String', 'Select a postsynaptic neuron', 'units', 'normalized', 'position', [0.02 0.92 0.29 0.06], 'backgroundcolor', fig_bg_col, 'fontsize', bfsize, 'horizontalalignment', 'left', 'fontname', gui_font_name, 'fontweight', gui_font_weight);

end
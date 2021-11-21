
if nneurons > 100 || microcircuit
    nma = 1; % small neurons setting
else
    nma = 0;
end
nma_flag = 0; % nma design hack
if nma
    nma_flag = 1;
end
if nneurons > 100 && ~microcircuit
    draw_synapses = 0;
else
    draw_synapses = 1;
end
% draw_synapses = 1;

if exist('fig_print', 'var') && isvalid(fig_print)
    axes(brain_axb)
elseif exist('fig_game', 'var') && isvalid(fig_game)
    axes(brain_multiax(nbrain).ax)
    nma_flag = 1;
else
    axes(brain_ax)
end

if exist('plot_neuron_synapses', 'var')
    delete(plot_neuron_synapses)
end
if exist('plot_contact_synapses', 'var')
    delete(plot_contact_synapses)
end
if exist('draw_neuron_edge', 'var')
    delete(draw_neuron_edge)
end
if exist('draw_neuron_core', 'var')
    delete(draw_neuron_core)
end
if exist('neuron_annotation', 'var')
    delete(neuron_annotation)
end
if exist('plot_bg_lines', 'var')
%     delete(plot_bg_lines)
    clear plot_bg_lines
end
if exist('draw_msn_skylt', 'var')
%     delete(draw_msn_skylt)
    clear draw_msn_skylt
end


% % Draw BG drives
% for p1 = 1:nneurons
%     for p2 = 1:nneurons
%         if bg_neurons(p1) && (network_ids(p1) == network_ids(p2))                
%             x1 = neuron_xys(p1,1);
%             x2 = neuron_xys(p2,1);
%             y1 = neuron_xys(p1,2);
%             y2 = neuron_xys(p2,2); 
%             if bg_colors
%                 plot_bg_lines(p1, p2) = plot([x1 x2], [y1 y2], 'linewidth', 4 - (nma_flag * 2), 'linestyle', ':', 'color', network_colors(network_ids(p1), :));
%             else
%                 plot_bg_lines(p1, p2) = plot([x1 x2], [y1 y2], 'linewidth', 4 - (nma_flag * 2), 'linestyle', ':', 'color', [0.25 0.25 0.25]);
%             end
%         end
%     end
% end


% % Draw synapses
if draw_synapses
    flags = zeros(size(connectome));
    adjust1 = 0.05;
    if exist('fig_design') && isvalid(fig_design) && (length(fig_design.UserData) > 1 || (fig_design.UserData == 0 || fig_design.UserData == 4))
        % If in runtime (not sure why this conditional is so complex)
        if microcircuit
            adjust2 = 0.09;
        else
            adjust2 = 0.22;
        end
    else
        if microcircuit
            adjust2 = 0.12;
        else
            adjust2 = 0.29;
        end
    end                                            
    for p1 = 1:nneurons
%         disp(horzcat(num2str(p1), ' of ', num2str(nneurons)))
        for p2 = 1:nneurons
            w = connectome(p1, p2);
            if w ~= 0
                x1 = neuron_xys(p1,1);
                x2 = neuron_xys(p2,1);
                y1 = neuron_xys(p1,2);
                y2 = neuron_xys(p2,2); 
                slope = (y2-y1)/(x2-x1);
                dx = abs(x1- x2);
                dy = abs(y1- y2);
                rx = dx / (dx + dy);
                ry = dy / (dx + dy);            
                if connectome(p2, p1)
                    if ~flags(p2, p1)
                        if slope > 0
                            x1 = x1 + adjust1 * ry;
                            x2 = x2 + adjust1 * ry;
                            y1 = y1 - adjust1 * rx;
                            y2 = y2 - adjust1 * rx;                    
                        else
                            x1 = x1 + adjust1 * ry;
                            x2 = x2 + adjust1 * ry;
                            y1 = y1 + adjust1 * rx;
                            y2 = y2 + adjust1 * rx;  
                        end
                        flags(p1, p2) = 1;
                    else
                        if slope > 0
                            x1 = x1 - adjust1 * ry;
                            x2 = x2 - adjust1 * ry;
                            y1 = y1 + adjust1 * rx;
                            y2 = y2 + adjust1 * rx;                    
                        else
                            x1 = x1 - adjust1 * ry;
                            x2 = x2 - adjust1 * ry;
                            y1 = y1 - adjust1 * rx;
                            y2 = y2 - adjust1 * rx;  
                        end
                    end
                end
                if bg_neurons(p2)
                    adjust3 = adjust2 * 1.2;
                else
                    adjust3 = adjust2;
                end
                if x1 <= x2 && y1 <= y2
                    x2 = x2 - adjust3 * rx;
                    y2 = y2 - adjust3 * ry;
                elseif x1 > x2 && y1 <= y2
                    x2 = x2 + adjust3 * rx;
                    y2 = y2 - adjust3 * ry;      
                elseif x1 > x2 && y1 > y2
                    x2 = x2 + adjust3 * rx;
                    y2 = y2 + adjust3 * ry; 
                elseif x1 <= x2 && y1 > y2
                    x2 = x2 - adjust3 * rx;
                    y2 = y2 + adjust3 * ry;                 
                end

                if isnan(w)
                    w = 2;
                    connectome(p1, p2) = 2;
                    da_connectome(p1, p2, :) = [2 2 2];
                else
                    plot_neuron_synapses(p1, p2, 1) = plot([x1 x2], [y1 y2], 'linewidth', ((abs(w) / 12) + 1) / (1 + microcircuit * 2), 'color', [0 0 0]);
                end
                if connectome(p1, p2) > 0
                    lw = 2 - microcircuit;
                    s = 9 - (nma_flag * 9);
                    m = 'square';
                    if da_connectome(p1, p2) == 1
                        mf = [1 0.7 0.4];
                    elseif da_connectome(p1, p2) == 2
                        mf = [0.6 0.7 1];
                    else
                        mf = 'w';
                    end
                else
                    lw = 2 - microcircuit;
                    s = 30 - (nma_flag * 9);                
                    m = '.';
                    mf = 'w';
                end
                plot_neuron_synapses(p1, p2, 2) = plot(x2, y2, 'marker', m, 'markersize', s + (abs(w) / 10), 'linewidth', lw, 'markerfacecolor', mf, 'markeredgecolor', 'k');
                if draw_synapse_strengths && ~nma_flag
                    w = round(w);
                    plot_neuron_synapses(p1, p2, 3) = text(x2, y2 + 0.1, num2str(w), 'fontsize', bfsize - 6, 'verticalalignment', 'middle', 'horizontalalignment', 'center', 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'color', [0.5 0.2 0]);
                end
            end
        end
    end
end

if ~isempty(neuron_contacts) % This is until I've figured out the contacts for two_spiking_neurons
    % Draw connections from sensors and to motors
    for nneuron = 1:nneurons
        for ncontact = 1:ncontacts

            % Plot synapse if it exists
            w = neuron_contacts(nneuron, ncontact);
            if w ~= 0
                if sum(ncontact == [1 2 3 5])
                    x1 = contact_xys(ncontact, 1);
                    y1 = contact_xys(ncontact, 2);
                    x2 = neuron_xys(nneuron,1);
                    y2 = neuron_xys(nneuron,2);  
                    w = 50;
                else
                    x2 = contact_xys(ncontact, 1);
                    y2 = contact_xys(ncontact, 2);
                    x1 = neuron_xys(nneuron,1);
                    y1 = neuron_xys(nneuron,2);   
                end
                slope = (y2-y1)/(x2-x1);
                dx = abs(x1- x2);
                dy = abs(y1- y2);
                rx = dx / (dx + dy);
                ry = dy / (dx + dy);  
                if x1 < x2 && y1 < y2
                    x2 = x2 - 0.25 * rx;
                    y2 = y2 - 0.25 * ry;
                    x2b = x2 - 0.3 * rx;
                    y2b = y2 - 0.3 * ry;
                elseif x1 > x2 && y1 < y2
                    x2 = x2 + 0.25 * rx;
                    y2 = y2 - 0.25 * ry;
                    x2b = x2 + 0.3 * rx;
                    y2b = y2 - 0.3 * ry;                    
                elseif x1 > x2 && y1 > y2
                    x2 = x2 + 0.25 * rx;
                    y2 = y2 + 0.25 * ry; 
                    x2b = x2 + 0.3 * rx;
                    y2b = y2 + 0.3 * ry;                     
                elseif x1 < x2 && y1 > y2
                    x2 = x2 - 0.25 * rx;
                    y2 = y2 + 0.25 * ry;
                    x2b = x2 - 0.3 * rx;
                    y2b = y2 + 0.3 * ry;                    
                end
                lw = 2 - microcircuit;
                s = 7;
                
                if nma_flag
                    fs = 10;
                else
                    fs = 18;
                end
                
                plot_contact_synapses(nneuron, ncontact, 1) = plot([x1 x2], [y1 y2], 'linewidth', (abs(w) / 100), 'color', [0.5 0.5 0.5]);
                plot_contact_synapses(nneuron, ncontact, 2) = plot(x2, y2, 'marker', 'square', 'markersize', s, 'linewidth', lw, 'markerfacecolor', 'w', 'markeredgecolor', 'k');

                % Indicate synapse filter (add rich neuron symbols here)
                if sum(ncontact == [1 2]) && sum(vis_prefs(nneuron, :, ncontact))  
                    this_vis_pref = find(vis_prefs(nneuron, :, ncontact));
                    plot_contact_synapses(nneuron, ncontact, 3) = plot(x2b, y2b, 'marker', 'd', 'markerfacecolor', [0.8 0.8 0.8], 'markeredgecolor', [0.8 0.8 0.8], 'markersize', fs);
                    plot_contact_synapses(nneuron, ncontact, 4) = text(x2b, y2b, vis_pref_names{this_vis_pref}, 'fontsize', bfsize - 4, 'verticalalignment', 'middle', 'horizontalalignment', 'center', 'FontWeight', 'bold'); % Seems to give error when drawing object detecting brain without use_cnn
                end
                
                if ncontact == 3 && audio_prefs(nneuron)
                    plot_contact_synapses(nneuron, ncontact, 3) = plot(x2b, y2b, 'marker', 'd', 'markerfacecolor', [0.8 0.8 0.8], 'markeredgecolor', [0.8 0.8 0.8], 'markersize', fs);
                    plot_contact_synapses(nneuron, ncontact, 4) = text(x2b, y2b, horzcat(num2str(audio_prefs(nneuron)), ' Hz'), 'fontsize', bfsize - 4, 'verticalalignment', 'middle', 'horizontalalignment', 'center', 'FontWeight', 'bold');
                end
                
                if ncontact == 4 && neuron_tones(nneuron)
                    plot_contact_synapses(nneuron, ncontact, 3) = plot(x2b, y2b, 'marker', 'd', 'markerfacecolor', [0.8 0.8 0.8], 'markeredgecolor', [0.8 0.8 0.8], 'markersize', fs);
                    if neuron_tones(nneuron) > length(audio_out_names)
                        plot_contact_synapses(nneuron, ncontact, 4) = text(x2b, y2b, horzcat(num2str(neuron_tones(nneuron)), ' Hz'), 'fontsize', bfsize - 4, 'verticalalignment', 'middle', 'horizontalalignment', 'center', 'FontWeight', 'bold');
                    elseif iscell(audio_out_names)
                        plot_contact_synapses(nneuron, ncontact, 4) = text(x2b, y2b, audio_out_names{neuron_tones(nneuron)}, 'fontsize', bfsize - 4, 'verticalalignment', 'middle', 'horizontalalignment', 'center', 'FontWeight', 'bold');
                    else
                        disp('Unable to draw synapse label. Is the brain combining pure tones with custom audio output?')
                    end
                end                
                
            end
        end
    end
end

drawnow

% Draw sensor and motor touch points
if exist('fig_design') && isvalid(fig_design) && (length(fig_design.UserData) > 1 || (fig_design.UserData == 0 || fig_design.UserData == 4))
    contact_size = 23;
else
    contact_size = 15;
end
for ncontact = 1:13
    contact_h(ncontact) = plot(contact_xys(ncontact,1), contact_xys(ncontact,2), 'markeredgecolor', 'k', 'markerfacecolor', [0.9 0.6 0.3], 'marker', 'square', 'markersize', contact_size);
    if exist('fig_design', 'var') && isvalid(fig_design) && (fig_design.UserData == 0 || fig_design.UserData == 4)
        if sum(ncontact == [1 2 3 5])
            contact_h(ncontact).ButtonDownFcn = 'create_sensory_synapse';
        elseif sum(ncontact == 4)
            contact_h(ncontact).ButtonDownFcn = 'receive_speaker_synapse';
        elseif sum(ncontact == [6:13])
            contact_h(ncontact).ButtonDownFcn = 'receive_motor_synapse';
        end
    end
end

drawnow

% Draw cell bodies
if exist('neuron_xys', 'var') && ~isempty(neuron_xys)
    
    if exist('fig_design', 'var') && isvalid(fig_design) && (length(fig_design.UserData) > 1 || (fig_design.UserData == 0 || fig_design.UserData == 4))
        edge_size = 700;
        core_size = 400;
    else
        edge_size = 500;
        core_size = 300;
    end  
    if nma
        if microcircuit
            edge_size = 160;
            core_size = 110;
        else
            edge_size = 70;
            core_size = 45;
        end
    end
    edge_size = (bg_neurons + 1) * edge_size;
    core_size = (bg_neurons + 1) * core_size;  
    
    if exist('fig_design', 'var') && isvalid(fig_design)
        for nneuron = 1:nneurons
            if bg_colors && bg_neurons(nneuron)
                this_col = network_colors(network_ids(nneuron), :);
            else
                this_col = [1 0.9 0.8];
            end
            if ~bg_neurons(nneuron) && network_ids(nneuron) > 1
                this_neuron = find(bg_neurons & network_ids == network_ids(nneuron), 1);
                x1 = neuron_xys(this_neuron,1);
                x2 = neuron_xys(nneuron,1);
                y1 = neuron_xys(this_neuron,2);
                y2 = neuron_xys(nneuron,2);
                draw_msn_skylt(nneuron, 3) = plot([x1 x2], [y1 y2+0.13], 'color', this_col, 'linewidth', 2 - microcircuit, 'linestyle', '--');
            end
        end
    end  
    
    % Neuron colors
    draw_neuron_edge = scatter(neuron_xys(:,1), neuron_xys(:,2), edge_size, zeros(size(neuron_xys,1), 3), 'filled');
    draw_neuron_core = scatter(neuron_xys(:,1), neuron_xys(:,2), core_size, neuron_cols, 'filled');
    
    if exist('fig_design', 'var') && isvalid(fig_design) && (length(fig_design.UserData) > 1 || (fig_design.UserData == 0 || fig_design.UserData == 4))
        draw_neuron_edge.ButtonDownFcn = 'neuron_selected';
        draw_neuron_core.ButtonDownFcn = 'neuron_selected';
    end
    if draw_neuron_numbers && ~nma_flag
        for nneuron = 1:nneurons
            neuron_annotation(nneuron, 1) = text(neuron_xys(nneuron,1), neuron_xys(nneuron,2), num2str(nneuron), 'fontsize', bfsize - 6, 'verticalalignment', 'middle', 'horizontalalignment', 'center', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            if exist('fig_design', 'var') && isvalid(fig_design) && (length(fig_design.UserData) > 1 || (fig_design.UserData == 0 || fig_design.UserData == 4))
                neuron_annotation(nneuron).ButtonDownFcn = 'neuron_selected';
            end
        end
    end
    
    if exist('fig_design', 'var') && isvalid(fig_design)
        for nneuron = 1:nneurons
            if bg_colors && bg_neurons(nneuron)
                this_col = network_colors(network_ids(nneuron), :);
            else
                this_col = [1 0.9 0.8];
            end            
            if ~bg_neurons(nneuron) && network_ids(nneuron) > 1
                draw_msn_skylt(nneuron, 1) = plot(neuron_xys(nneuron,1), neuron_xys(nneuron,2)+0.13, 'markeredgecolor', this_col, 'markerfacecolor', this_col, 'marker', 'o', 'markersize', 10, 'linewidth', 2);  
                draw_msn_skylt(nneuron, 2) = text(neuron_xys(nneuron,1), neuron_xys(nneuron,2)+0.13, letters(network_ids(nneuron)), 'fontsize', bfsize - 6, 'verticalalignment', 'middle', 'horizontalalignment', 'center', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            elseif bg_neurons(nneuron) && network_ids(nneuron) > 1
                draw_msn_skylt(nneuron, 2) = text(neuron_xys(nneuron,1), neuron_xys(nneuron,2), letters(network_ids(nneuron)), 'fontsize', bfsize - 4, 'verticalalignment', 'middle', 'horizontalalignment', 'center', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            end                
        end
    end     
    
%     if exist('da_rew_neurons', 'var')
%         for nneuron = 1:nneurons
%             if da_rew_neurons(nneuron)
%                 neuron_annotation(nneuron, 1) = text(neuron_xys(nneuron,1), neuron_xys(nneuron,2), '*', 'fontsize', bfsize + 11, 'verticalalignment', 'middle', 'horizontalalignment', 'center', 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'color', [0 0.3 0]);
%             end
%         end
%     end
    if exist('neuron_scripts', 'var')
        for nneuron = 1:nneurons
            if neuron_scripts(nneuron)
                neuron_annotation(nneuron, 1) = text(neuron_xys(nneuron,1), neuron_xys(nneuron,2) - 0.2, num2str(script_strs(neuron_scripts(nneuron)).name), 'fontsize', bfsize - 6, 'verticalalignment', 'middle', 'horizontalalignment', 'center', 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8], 'color', [0 0 0]);
            end
        end
    end
end

drawnow

% Adjust brain axes
axis([-3 3 -3 3])

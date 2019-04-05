

axes(brain_ax)

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
    delete(plot_bg_lines)
end
if exist('draw_msn_skylt', 'var')
    delete(draw_msn_skylt)
end


% Draw BG drives
if exist('fig_design', 'var') && isvalid(fig_design)
    for p1 = 1:nneurons
        for p2 = 1:nneurons
            if bg_neurons(p1) && (network_ids(p1) == network_ids(p2))
                
                
                x1 = neuron_xys(p1,1);
                x2 = neuron_xys(p2,1);
                y1 = neuron_xys(p1,2);
                y2 = neuron_xys(p2,2); 
                plot_bg_lines(p1, p2) = plot([x1 x2], [y1 y2], 'linewidth', 4, 'linestyle', ':', 'color', [0 0 0]);
            end
        end
    end
end


% Draw synapses
flags = zeros(size(connectome));
adjust1 = 0.05;
if exist('fig_design') && isvalid(fig_design) && (length(fig_design.UserData) > 1 || (fig_design.UserData == 0 || fig_design.UserData == 4))
    % If in runtime (not sure why this conditional is so complex)
    adjust2 = 0.22;
else
    adjust2 = 0.29;
end                                            
for p1 = 1:nneurons
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
            
            
            plot_neuron_synapses(p1, p2, 1) = plot([x1 x2], [y1 y2], 'linewidth', (abs(w) / 12) + 1, 'color', [0 0 0]);
            if connectome(p1, p2) > 0
                lw = 2;
                s = 9;
                m = 'square';
                if da_connectome(p1, p2)
                    mf = [0.7 0.7 1];
                else
                    mf = 'w';
                end
            else
                lw = 2;
                s = 30;                
                m = '.';
                mf = 'k';
            end
            plot_neuron_synapses(p1, p2, 2) = plot(x2, y2, 'marker', m, 'markersize', s + (abs(w) / 10), 'linewidth', lw, 'markerfacecolor', mf, 'markeredgecolor', 'k');
            if draw_synapse_strengths
%                 w = round(w * 100) / 100;
                w = round(w);
                plot_neuron_synapses(p1, p2, 3) = text(x2, y2 + 0.1, num2str(w), 'fontsize', bfsize - 6, 'verticalalignment', 'middle', 'horizontalalignment', 'center', 'fontname', gui_font_name, 'fontweight', gui_font_weight, 'color', [0.5 0.2 0]);
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
                    w = 250;
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
                elseif x1 > x2 && y1 < y2
                    x2 = x2 + 0.25 * rx;
                    y2 = y2 - 0.25 * ry;      
                elseif x1 > x2 && y1 > y2
                    x2 = x2 + 0.25 * rx;
                    y2 = y2 + 0.25 * ry; 
                elseif x1 < x2 && y1 > y2
                    x2 = x2 - 0.25 * rx;
                    y2 = y2 + 0.25 * ry;                 
                end
                lw = 2;
                s = 9;
                fs = 18;
                
                
                plot_contact_synapses(nneuron, ncontact, 1) = plot([x1 x2], [y1 y2], 'linewidth', (abs(w) / 100), 'color', [0 0 0]);
                plot_contact_synapses(nneuron, ncontact, 2) = plot(x2, y2, 'marker', 'square', 'markersize', s, 'linewidth', lw, 'markerfacecolor', 'w', 'markeredgecolor', 'k');

                % Indicate synapse filter (add rich neuron symbols here)
                if sum(ncontact == [1 2]) && sum(vis_prefs(nneuron, :, ncontact))  
                    if find(vis_prefs(nneuron, :, ncontact)) == 1 || find(vis_prefs(nneuron, :, ncontact)) == 4
                        plot_contact_synapses(nneuron, ncontact, 3) = plot(x2, y2, 'marker', 'd', 'markerfacecolor', 'r', 'markeredgecolor', 'k', 'markersize', fs);
                    elseif find(vis_prefs(nneuron, :, ncontact)) == 2 || find(vis_prefs(nneuron, :, ncontact)) == 5
                        plot_contact_synapses(nneuron, ncontact, 3) = plot(x2, y2, 'marker', 'd', 'markerfacecolor', [0 0.8 0], 'markeredgecolor', 'k', 'markersize', fs);
                    elseif find(vis_prefs(nneuron, :, ncontact)) == 3 || find(vis_prefs(nneuron, :, ncontact)) == 6
                        plot_contact_synapses(nneuron, ncontact, 3) = plot(x2, y2, 'marker', 'd', 'markerfacecolor', 'b', 'markeredgecolor', 'k', 'markersize', fs);
                    else
                        plot_contact_synapses(nneuron, ncontact, 3) = plot(x2, y2, 'marker', 'd', 'markerfacecolor', 'w', 'markeredgecolor', 'k', 'markersize', fs);
                        plot_contact_synapses(nneuron, ncontact, 4) = text(x2, y2, '?', 'fontsize', bfsize - 6, 'verticalalignment', 'middle', 'horizontalalignment', 'center', 'FontWeight', 'bold');
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
for ncontact = [1 2 3 4 5:13] % Skipping microphone
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
    edge_size = (bg_neurons + 1) * edge_size;
    core_size = (bg_neurons + 1) * core_size;  
    
	draw_neuron_edge = scatter(neuron_xys(:,1), neuron_xys(:,2), edge_size, zeros(size(neuron_xys,1), 3), 'filled');
    draw_neuron_core = scatter(neuron_xys(:,1), neuron_xys(:,2), core_size, neuron_cols, 'filled');
    if exist('fig_design') && isvalid(fig_design) && (length(fig_design.UserData) > 1 || (fig_design.UserData == 0 || fig_design.UserData == 4))
        draw_neuron_edge.ButtonDownFcn = 'neuron_selected';
        draw_neuron_core.ButtonDownFcn = 'neuron_selected';
    end
    if draw_neuron_numbers
        for nneuron = 1:nneurons
            neuron_annotation(nneuron, 1) = text(neuron_xys(nneuron,1), neuron_xys(nneuron,2), num2str(nneuron), 'fontsize', bfsize - 6, 'verticalalignment', 'middle', 'horizontalalignment', 'center', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            if exist('fig_design') && isvalid(fig_design) && (length(fig_design.UserData) > 1 || (fig_design.UserData == 0 || fig_design.UserData == 4))
                neuron_annotation(nneuron).ButtonDownFcn = 'neuron_selected';
            end
        end
    end
    
    
    
    
    
    
    if exist('fig_design', 'var') && isvalid(fig_design) && sum(bg_neurons)
        for nneuron = 1:nneurons
            if bg_neurons(nneuron)
                draw_msn_skylt(nneuron, 1) = plot(neuron_xys(nneuron,1), neuron_xys(nneuron,2)-0.13, 'markeredgecolor', 'k', 'markerfacecolor', [0.9 0.2 0.2], 'marker', 'square', 'markersize', contact_size);  
                draw_msn_skylt(nneuron, 2) = text(neuron_xys(nneuron,1), neuron_xys(nneuron,2)-0.13, num2str(network_ids(nneuron) - 1), 'fontsize', bfsize - 6, 'verticalalignment', 'middle', 'horizontalalignment', 'center', 'fontname', gui_font_name, 'fontweight', gui_font_weight);
            end
        end
    end
end

drawnow

% Adjust brain axes
axis([-3 3 -3 3])

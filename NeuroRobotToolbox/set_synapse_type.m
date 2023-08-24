
if exist('postsynaptic_neuron', 'var')
    if button_w1.Value == 1
        edit_w.String = num2str(base_weight);
        button_w1.BackgroundColor = [0.6 0.95 0.6];
        button_w2.BackgroundColor = [0.8 0.8 0.8];
    elseif button_w2.Value == 1
        edit_w.String = num2str(-base_weight);
        button_w1.BackgroundColor = [0.8 0.8 0.8];
        button_w2.BackgroundColor = [0.6 0.95 0.6];    
    end
elseif speaker_selected
    if button_w1.Value == 1
        edit_w.String = num2str(round(rand * 800 + 200));
        button_w1.BackgroundColor = [0.6 0.95 0.6];
        button_w2.BackgroundColor = [0.8 0.8 0.8];
    elseif button_w2.Value == 1
        edit_w.String = num2str(0);
        button_w1.BackgroundColor = [0.8 0.8 0.8];
        button_w2.BackgroundColor = [0.6 0.95 0.6];    
    end    
% elseif exist('postsynaptic_contact', 'var')
%     if button_w1.Value == 1
%         edit_w.String = num2str(100);
%         button_w1.BackgroundColor = [0.6 0.95 0.6];
%         button_w2.BackgroundColor = [0.8 0.8 0.8];
%     elseif button_w2.Value == 1
%         edit_w.String = num2str(0);
%         button_w1.BackgroundColor = [0.8 0.8 0.8];
%         button_w2.BackgroundColor = [0.6 0.95 0.6];    
%     end    
end
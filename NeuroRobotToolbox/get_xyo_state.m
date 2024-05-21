function xyo_state = get_xyo_state(this_x, this_y, this_o, xyo_state_transform)

if xyo_state_transform == 1
elseif xyo_state_transform == 2
    if this_y <= 134
        if this_x < 167
            this_o_state = get_o_state(this_o);
            xyo_state = 0 + this_o_state;
        elseif this_x < 333
            this_o_state = get_o_state(this_o);
            xyo_state = 1 + this_o_state;            
        else
            this_o_state = get_o_state(this_o);
            xyo_state = 2 + this_o_state;      
        end
    elseif this_y < 267
        if this_x < 167
            this_o_state = get_o_state(this_o);
            xyo_state = 3 + this_o_state;
        elseif this_x < 333
            this_o_state = get_o_state(this_o);
            xyo_state = 4 + this_o_state;            
        else
            this_o_state = get_o_state(this_o);
            xyo_state = 5 + this_o_state;      
        end
    else
        if this_x < 167
            this_o_state = get_o_state(this_o);
            xyo_state = 6 + this_o_state;
        elseif this_x < 333
            this_o_state = get_o_state(this_o);
            xyo_state = 7 + this_o_state;            
        else
            this_o_state = get_o_state(this_o);
            xyo_state = 8 + this_o_state;      
        end
    end
end
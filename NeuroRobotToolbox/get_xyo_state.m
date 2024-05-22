function xyo_state = get_xyo_state(this_x, this_y, this_o, xyo_state_transform)

x2 = 331;
x3 = 427;

y2 = 170;
y3 = 261;

if xyo_state_transform == 1
elseif xyo_state_transform == 2
    if this_y <= y2
        if this_x < x2
            this_o_state = get_o_state(this_o);
            xyo_state = this_o_state;
        elseif this_x < x3
            this_o_state = get_o_state(this_o);
            xyo_state = 8*1 + this_o_state;            
        else
            this_o_state = get_o_state(this_o);
            xyo_state = 8*2 + this_o_state;      
        end
    elseif this_y < y3
        if this_x < x2
            this_o_state = get_o_state(this_o);
            xyo_state = 8*3 + this_o_state;
        elseif this_x < x3
            this_o_state = get_o_state(this_o);
            xyo_state = 8*4 + this_o_state;            
        else
            this_o_state = get_o_state(this_o);
            xyo_state = 8*5 + this_o_state;      
        end
    else
        if this_x < x2
            this_o_state = get_o_state(this_o);
            xyo_state = 8*6 + this_o_state;
        elseif this_x < x3
            this_o_state = get_o_state(this_o);
            xyo_state = 8*7 + this_o_state;            
        else
            this_o_state = get_o_state(this_o);
            xyo_state = 8*8 + this_o_state;      
        end
    end
end

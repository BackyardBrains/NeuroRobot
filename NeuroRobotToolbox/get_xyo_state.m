function xyo_state = get_xyo_state(this_x, this_y, this_o, xlims, ylims, n_unique_states)

if n_unique_states == 32
    if this_y <= mean(ylims(2:3))
        if this_x < mean(xlims(2:3))
            this_o_state = get_o_state(this_o);
            xyo_state = this_o_state;        
        else
            this_o_state = get_o_state(this_o);
            xyo_state = 8*1 + this_o_state;      
        end
    else
        if this_x < mean(xlims(2:3))
            this_o_state = get_o_state(this_o);
            xyo_state = 8*2 + this_o_state;            
        else
            this_o_state = get_o_state(this_o);
            xyo_state = 8*3 + this_o_state;      
        end
    end    
elseif n_unique_states == 72
    if this_y <= ylim(2)
        if this_x < xlim(2)
            this_o_state = get_o_state(this_o);
            xyo_state = this_o_state;
        elseif this_x < xlim(3)
            this_o_state = get_o_state(this_o);
            xyo_state = 8*1 + this_o_state;            
        else
            this_o_state = get_o_state(this_o);
            xyo_state = 8*2 + this_o_state;      
        end
    elseif this_y < ylim(3)
        if this_x < xlim(2)
            this_o_state = get_o_state(this_o);
            xyo_state = 8*3 + this_o_state;
        elseif this_x < xlim(3)
            this_o_state = get_o_state(this_o);
            xyo_state = 8*4 + this_o_state;            
        else
            this_o_state = get_o_state(this_o);
            xyo_state = 8*5 + this_o_state;      
        end
    else
        if this_x < xlim(2)
            this_o_state = get_o_state(this_o);
            xyo_state = 8*6 + this_o_state;
        elseif this_x < xlim(3)
            this_o_state = get_o_state(this_o);
            xyo_state = 8*7 + this_o_state;            
        else
            this_o_state = get_o_state(this_o);
            xyo_state = 8*8 + this_o_state;      
        end
    end
end

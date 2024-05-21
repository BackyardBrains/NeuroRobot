function xyo_state = get_xyo_state(this_x, this_y, this_o, xyo_state_transform)

if xyo_state_transform == 1
    if this_y <= 200
        if this_x < 250
            if this_o >= 0 && this_o < 90
                xyo_state = 1;
            elseif this_o >= 90 && this_o < 180
                xyo_state = 2;
            elseif this_o >= 180 && this_o < 270
                xyo_state = 3;                    
            elseif this_o >= 270 && this_o <= 360
                xyo_state = 4;                    
            end
        else
            if this_o >= 0 && this_o < 90
                xyo_state = 5;
            elseif this_o >= 90 && this_o < 180
                xyo_state = 6;
            elseif this_o >= 180 && this_o < 270
                xyo_state = 7;                    
            elseif this_o >= 270 && this_o <= 360
                xyo_state = 8;                    
            end
        end
    else
        if this_x < 250
            if this_o >= 0 && this_o < 90
                xyo_state = 9;
            elseif this_o >= 90 && this_o < 180
                xyo_state = 10;
            elseif this_o >= 180 && this_o < 270
                xyo_state = 11;                    
            elseif this_o >= 270 && this_o <= 360
                xyo_state = 12;                    
            end
        else
            if this_o >= 0 && this_o < 90
                xyo_state = 13;
            elseif this_o >= 90 && this_o < 180
                xyo_state = 14;
            elseif this_o >= 180 && this_o < 270
                xyo_state = 15;                    
            elseif this_o >= 270 && this_o <= 360
                xyo_state = 16;                    
            end
        end          
    end
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
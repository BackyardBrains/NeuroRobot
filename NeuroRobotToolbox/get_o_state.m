function o_state = get_o_state(this_o)

padding = 22;

if this_o > 0 + padding && this_o < 45 + padding
    o_state = 1;
elseif this_o >= 45 + padding && this_o < 90 + padding
    o_state = 2;
elseif this_o >= 90 + padding && this_o < 135 + padding
    o_state = 3;                    
elseif this_o >= 135 + padding && this_o < 180 + padding
    o_state = 4;         
elseif this_o >= 180 + padding && this_o < 225 + padding
    o_state = 5;
elseif this_o >= 225 + padding && this_o < 270 + padding
    o_state = 6;                
elseif this_o >= 270 + padding && this_o < 315 + padding
    o_state = 7;                    
elseif this_o >= 315 + padding || this_o < padding
    o_state = 8;
end
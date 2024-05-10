function [state, label] = ml_roast(x1, y1, o1, medx, medy)

if y1 <= medy
    if x1 < medx
        if o1 >= 0 && o1 < 90
            state = 1;
            label = horzcat('state ', num2str(state));
        elseif o1 >= 90 && o1 < 180
            state = 2;
            label = horzcat('state ', num2str(state));                  
        elseif o1 >= 180 && o1 < 270
            state = 3;   
            label = horzcat('state ', num2str(state));                  
        elseif o1 >= 270 && o1 <= 360
            state = 4; 
            label = horzcat('state ', num2str(state));                  
        end
    else
        if o1 >= 0 && o1 < 90
            state = 5;
            label = horzcat('state ', num2str(state));                 
        elseif o1 >= 90 && o1 < 180
            state = 6;
            label = horzcat('state ', num2str(state));               
        elseif o1 >= 180 && o1 < 270
            state = 7;   
            label = horzcat('state ', num2str(state));              
        elseif o1 >= 270 && o1 <= 360
            state = 8;  
            label = horzcat('state ', num2str(state));               
        end
    end
else
    if x1 < medx
        if o1 >= 0 && o1 < 90
            state = 9;
            label = horzcat('state ', num2str(state));            
        elseif o1 >= 90 && o1 < 180
            state = 10;
            label = horzcat('state ', num2str(state));                
        elseif o1 >= 180 && o1 < 270
            state = 11;  
            label = horzcat('state ', num2str(state));                 
        elseif o1 >= 270 && o1 <= 360
            state = 12;    
            label = horzcat('state ', num2str(state));                  
        end
    else
        if o1 >= 0 && o1 < 90
            state = 13;
            label = horzcat('state ', num2str(state));                 
        elseif o1 >= 90 && o1 < 180
            state = 14;
            label = horzcat('state ', num2str(state));               
        elseif o1 >= 180 && o1 < 270
            state = 15;    
            label = horzcat('state ', num2str(state));                
        elseif o1 >= 270 && o1 <= 360
            state = 16;  
            label = horzcat('state ', num2str(state));                 
        end
    end          
end
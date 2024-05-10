function [state, label] = ml_roast2(x1, y1, o1, prcx33, prcy33, prcx66, prcy66)

if y1 <= prcy33
    if x1 < prcx33
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
    elseif x1 < prcx66
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
    else
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
    end
elseif y1 <= prcy66
    if x1 < prcx33
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
    elseif x1 < prcx66
        if o1 >= 0 && o1 < 90
            state = 17;
            label = horzcat('state ', num2str(state));                 
        elseif o1 >= 90 && o1 < 180
            state = 18;
            label = horzcat('state ', num2str(state));               
        elseif o1 >= 180 && o1 < 270
            state = 19;    
            label = horzcat('state ', num2str(state));                
        elseif o1 >= 270 && o1 <= 360
            state = 20;  
            label = horzcat('state ', num2str(state));                 
        end
    else          
        if o1 >= 0 && o1 < 90
            state = 21;
            label = horzcat('state ', num2str(state));                 
        elseif o1 >= 90 && o1 < 180
            state = 22;
            label = horzcat('state ', num2str(state));               
        elseif o1 >= 180 && o1 < 270
            state = 23;    
            label = horzcat('state ', num2str(state));                
        elseif o1 >= 270 && o1 <= 360
            state = 24;  
            label = horzcat('state ', num2str(state));                 
        end
    end
else
    if x1 < prcx33
        if o1 >= 0 && o1 < 90
            state = 25;
            label = horzcat('state ', num2str(state));            
        elseif o1 >= 90 && o1 < 180
            state = 26;
            label = horzcat('state ', num2str(state));                
        elseif o1 >= 180 && o1 < 270
            state = 27;  
            label = horzcat('state ', num2str(state));                 
        elseif o1 >= 270 && o1 <= 360
            state = 28;    
            label = horzcat('state ', num2str(state));                  
        end
    elseif x1 < prcx66
        if o1 >= 0 && o1 < 90
            state = 29;
            label = horzcat('state ', num2str(state));                 
        elseif o1 >= 90 && o1 < 180
            state = 30;
            label = horzcat('state ', num2str(state));               
        elseif o1 >= 180 && o1 < 270
            state = 31;    
            label = horzcat('state ', num2str(state));                
        elseif o1 >= 270 && o1 <= 360
            state = 32;  
            label = horzcat('state ', num2str(state));                 
        end
    else
        if o1 >= 0 && o1 < 90
            state = 33;
            label = horzcat('state ', num2str(state));                 
        elseif o1 >= 90 && o1 < 180
            state = 34;
            label = horzcat('state ', num2str(state));               
        elseif o1 >= 180 && o1 < 270
            state = 35;    
            label = horzcat('state ', num2str(state));                
        elseif o1 >= 270 && o1 <= 360
            state = 36;  
            label = horzcat('state ', num2str(state));                 
        end
    end
end

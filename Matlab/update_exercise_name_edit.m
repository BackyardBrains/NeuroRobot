
if popup_select_exercise.Value == 1 % If create new exercise

else 
    
    load(strcat('./exercises/', popup_select_exercise.String{popup_select_exercise.Value}, '.mat'))
    
    description_text = 
    
    practises_text
    coreideas_text
    cconcepts_text 
    
    
    nlines = length(exercise.text);
    for nexercise = 1:nlines
        ex_text_line(nexercise) = text(-0.5, 10 - nexercise, exercise.text(nexercise).str, 'FontSize', bfsize - 2, 'FontName', gui_font_name, 'FontWeight', gui_font_weight);
    end
    for nexercise = nlines+1:10
        ex_text_line(nexercise) = text(-0.5, 10 - nexercise, '');
    end
    
  
end


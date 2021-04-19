if popup_select_word.Value > 1
    word_edit_name.String = popup_select_word.String{popup_select_word.Value};
else
    word_edit_name.String = [];
end
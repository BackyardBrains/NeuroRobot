function key_fcn(src, event)
    hGUIData = guidata(src);
    hGUIData.outputVar = event.Key;
    disp(hGUIData.outputVar)
    guidata(src, hGUIData);
end

function bluetooth_modem = connect_bluetooth(bluetooth_name, button_bluetooth, text_title, text_load, popup_select_brain, edit_name, button_camera, button_startup_complete, camera_present, bluetooth_present)

disp('Connecting bluetooth...')
button_bluetooth.BackgroundColor = [0.94 0.78 0.62];
text_title.String = 'Connecting bluetooth...';
text_load.String = '';
set(button_bluetooth, 'enable', 'off')
set(popup_select_brain, 'visible', 'off')
set(edit_name, 'enable', 'off')
set(button_camera, 'enable', 'off')
set(button_startup_complete, 'enable', 'off')
drawnow

if exist('bluetooth_modem', 'var')
    try
        fwrite(bluetooth_modem, [0 0 0 0 0])
    catch
        disp('Cannot send stop command to bluetooth modem')
    end
end

tic
try
    delete(instrfind)
    bluetooth_modem = Bluetooth(bluetooth_name, 1);
    pause(1)
    fopen(bluetooth_modem);
    disp(horzcat('Bluetooth connected in ', num2str(round(toc)), ' s'))
    button_bluetooth.BackgroundColor = [0.6 0.95 0.6];
    drawnow
catch
    disp('Bluetooth failed to connect. Are you paired and connecting to the correct RNBT tag?')
    button_bluetooth.BackgroundColor = [1 0.5 0.5];
    drawnow
end

text_title.String = 'Neurorobot Startup';
text_load.String = 'Select brain';
if bluetooth_present
    set(button_bluetooth, 'enable', 'on')
end
set(popup_select_brain, 'visible', 'on')
set(edit_name, 'enable', 'on')
if camera_present
    set(button_camera, 'enable', 'on')
end
set(button_startup_complete, 'enable', 'on')


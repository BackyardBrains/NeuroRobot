try
    fwrite(bluetooth_modem, motor_command)
catch
    disp('Bluetooth failed. Attempting reconnect...')
    try
        bluetooth_modem = connect_bluetooth(bluetooth_name, button_bluetooth);
        pause(0.05)
        fwrite(bluetooth_modem, motor_command)       
    catch
        disp('Bluetooth reconnection failed')
    end
end
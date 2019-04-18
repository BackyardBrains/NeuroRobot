
try
    if bluetooth_modem.BytesAvailable
        this_distance = get_distance(bluetooth_modem);
    end
catch
    disp('Bluetooth failed. Attempting reconnect...')
    try
        bluetooth_modem = connect_bluetooth(bluetooth_name, button_bluetooth);
        if bluetooth_modem.BytesAvailable
            this_distance = get_distance(bluetooth_modem);
        end    
    catch
        disp('Bluetooth reconnection failed')
        this_distance = 300;         
    end
end

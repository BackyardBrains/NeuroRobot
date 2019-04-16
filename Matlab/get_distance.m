function this_distance = get_distance(bluetooth_modem)
    while bluetooth_modem.BytesAvailable
        distance_read = fgetl(bluetooth_modem);
    end
    this_distance = str2double(distance_read);
    this_distance(this_distance > 300) = 300;
end
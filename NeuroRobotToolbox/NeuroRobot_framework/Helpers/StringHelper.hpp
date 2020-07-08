//
//  StringHelper.hpp
//  NeuroRobot-Framework
//
//  Created by Djordje Jovic on 15/02/2020.
//  Copyright © 2020 Backyard Brains. All rights reserved.
//

#ifndef StringHelper_hpp
#define StringHelper_hpp

#include <iostream>
#include <iomanip>
#include <sstream>
#include <chrono>

/// Helper for strings
class StringHelper
{
    
public:
    
    /// Create string from current date.
    /// @return Current date
    static std::string getDate()
    {
        std::stringstream ss;
        std::time_t now = std::chrono::system_clock::to_time_t(std::chrono::system_clock::now());
        ss << std::put_time(localtime(&now), "%F_%H-%M-%S");
        return ss.str();
    }
    
    /// Create url for rtsp.
    /// @param userName User name for rtsp
    /// @param password Password for rtsp
    /// @param ipAddress IP address of rtsp
    /// @return URL
    static std::string createUrl(std::string userName, std::string password, std::string ipAddress)
    {
        // rtsp://admin:admin@192.168.100.1:554/cam1/h264
        std::string url = std::string();
        url.append("rtsp://");
        url.append(userName);
        url.append(":");
        url.append(password);
        url.append("@");
        url.append(ipAddress);
        url.append(":554/cam1/h264");
        return url;
    }
};
#endif /* StringHelper_hpp */

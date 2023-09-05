//
//  Log.h
//  Neurorobot-Framework
//
//  Created by Djordje Jovic on 6/16/19.
//  Copyright © 2019 Backyard Brains. All rights reserved.
//

#ifndef Log_h
#define Log_h

#include "Macros.h"
#include <string>
#include <mutex>

#ifdef DEBUG
    #include <fstream>
#endif

/// Derived class for logging system
class Log
{
    
private:
    
#ifdef DEBUG
    std::ofstream logFile;
#endif
    
    /// Class name relevant for log file name
    std::string className = "No_name";
    
    /// Data for sync mechanism
    std::mutex loggingMutex;
    
    /// Open log file.
    /// Be sure that `className` is defined like you want. Use provided constructor.
    void openLogFile();
    
    /// Create directory for logs.
    void createLogsDirectory();
    
    /// Closes log file.
    void closeLogFile();
    
protected:
    
    Log(std::string className);
    ~Log();
    
    /// Write forwarded message to log file.
    /// @param message Message to log
    /// @warning Working only if the macro #DEBUG is defined in Macros.h.
    void logMessage(std::string message);
};

#endif /* Log_h */

//
//  Log.h
//  RAK-Framework
//
//  Created by Djordje Jovic on 6/16/19.
//  Copyright © 2019 Backyard Brains. All rights reserved.
//

#ifndef Log_h
#define Log_h

#include "Macros.h"
#include <string>

#ifdef DEBUG
    #include <fstream>
#endif


class Log
{
private:
    
public:
    
    std::string className = "No_name";
    
    ~Log();
    
#ifdef DEBUG
    std::ofstream logFile;
#endif
    
    /**
     Opens log file.
     Be sure that `className` is defined like you want. If not, the name of log file will be predefined name.
     */
    void openStreams();
     
    /**
     Closes log file.
     */
    void closeStreams();
    
    /**
     Writes forwarded message to log file.
     Only working if is defined #DEBUG macro in Macros.h
     
     @see Macros.h file have to have defiend #DEBUG macro
     
     @param message Message to log
     */
    void logMessage(std::string message);
};

#endif /* Log_h */

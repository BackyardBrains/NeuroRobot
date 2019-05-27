//
//  Created by Djordje Jovic on 5/16/19.
//  Copyright © 2019 Backyard Brains. All rights reserved.
//

#ifndef _Log_cpp
#define _Log_cpp

#include "Macros.h"
#include <iostream>

#ifdef DEBUG
#include <fstream>
#include <ctime>
#include <chrono>
#include <typeinfo>
#include <string>
#endif

class Log
{
private:
    
public:
    
    std::string className = "No_name";
    
    ~Log()
    {
        closeStreams();
    }
    
#ifdef DEBUG
    std::ofstream logFile;
#endif
    
    void openStreams() {
#ifdef DEBUG
        char logFileName[50];
        strcpy(logFileName, "logFile_");
        strcat(logFileName, className.c_str());
        strcat(logFileName, ".txt");
        
        logFile.open(logFileName);
        logMessage("openStreams >> Socket >>> opened");
#endif
    }
    void closeStreams() {
#ifdef DEBUG
        logMessage("closeStreams >>> closed");
        logFile.close();
#endif
    }
    
    void logMessage(std::string message) {
#ifdef DEBUG
        std::time_t end_time = std::chrono::system_clock::to_time_t(std::chrono::system_clock::now());
        std::string t(std::ctime(&end_time));
        logFile << t.substr( 0, t.length() -1) << " : " << message << std::endl;
        std::cout << message << std::endl;
#endif
    }
};

#endif // ! _Log_cpp

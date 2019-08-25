//
//  Created by Djordje Jovic on 5/16/19.
//  Copyright © 2019 Backyard Brains. All rights reserved.
//

#ifndef _Log_cpp
#define _Log_cpp

#include "Log.h"
#include <stdio.h>
#include <iostream>

#ifdef DEBUG
    #include <ctime>
    #include <chrono>
    #include <typeinfo>
    #include <string>
#endif

Log::~Log()
{
    closeStreams();
}
void Log::openStreams() {
#ifdef DEBUG
    char logFileName[50];
    strcpy(logFileName, "logFile_");
    strcat(logFileName, className.c_str());
    strcat(logFileName, ".txt");
    
    logFile.open(logFileName);
    logMessage("openStreams >> " + className + " >>> opened");
#endif
}
void Log::closeStreams() {
#ifdef DEBUG
    logMessage("closeStreams >> " + className + " >>> closed");
    logFile.close();
#endif
}
void Log::logMessage(std::string message) {
#ifdef DEBUG
    std::time_t end_time = std::chrono::system_clock::to_time_t(std::chrono::system_clock::now());
    std::string t(std::ctime(&end_time));
    logFile << t.substr( 0, t.length() -1) << " : " << message << std::endl;
    std::cout << message << std::endl;
#endif
}

#endif // ! _Log_cpp

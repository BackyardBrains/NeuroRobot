//
//  Log.cpp
//  Neurorobot-Framework
//
//  Created by Djordje Jovic on 5/16/19.
//  Copyright © 2019 Backyard Brains. All rights reserved.
//

#ifndef _Log_cpp
#define _Log_cpp

#include "Log.h"
#ifdef XCODE
    #include "Bridge/Helpers/StringHelper.hpp"
#else
    #include "Helpers/StringHelper.hpp"
#endif

#include <iostream>

#ifdef DEBUG
    #include <ctime>
    #include <chrono>
    #include <typeinfo>
    #include <string>
    #include <boost/filesystem.hpp>
    #include <future>
#endif

static std::string path;

const static std::string codeVersion = "v1.0.5";
const static std::string codeDate = "25/Apr/2020";

Log::Log(std::string className)
{
    this->className = className;
    openLogFile();
}

Log::~Log()
{
    closeLogFile();
}

void Log::openLogFile()
{
#ifdef DEBUG
    createLogsDirectory();
    
    char logFileName[100];
    strcpy(logFileName, path.c_str());
    strcat(logFileName, "/NeuroRobot_logFile_");
    strcat(logFileName, className.c_str());
    strcat(logFileName, ".txt");
    
    logFile.open(logFileName);
    
    logMessage("openLogFile >> path: >> " + std::string(logFileName) + " >>> opened");
    logMessage("code version: " + codeVersion);
    logMessage("code date: " + codeDate);
#endif
}

void Log::closeLogFile()
{
#ifdef DEBUG
    logMessage("closeLogFile >> " + className + " >>> closed");
    if (logFile.is_open()) {
        logFile.close();
    }
#endif
}

void Log::logMessage(std::string message) {
#ifdef DEBUG
    loggingMutex.lock();
    std::time_t now = std::chrono::system_clock::to_time_t(std::chrono::system_clock::now());
    std::string t(std::ctime(&now));
    logFile << t.substr( 0, t.length() -1) << " : " << message << std::endl;
    std::cout << message << std::endl;
    loggingMutex.unlock();
#endif
}

void Log::createLogsDirectory()
{
#ifdef DEBUG
    int counter = 1;
    boost::filesystem::path dir;
    
    if (!boost::filesystem::exists("Logs")) {
        boost::filesystem::create_directory("Logs");
    }
    
    if (path.empty()) {
        auto date = StringHelper::getDate();
        
        do {
            path = "Logs/" + date + "(" + std::to_string(counter) + ")";
            dir = boost::filesystem::path(path);
            counter++;
            
        } while (boost::filesystem::exists(dir));
        boost::filesystem::create_directory(dir);
    }
#endif
}

#endif // ! _Log_cpp

//
//  BackgroundThread.h
//  Neurorobot-Framework
//
//  Created by Djordje Jovic on 11/5/18.
//  Copyright © 2018 Backyard Brains. All rights reserved.
//

#ifndef _BackgroundThread_h
#define _BackgroundThread_h

#include <thread>
#include <iostream>

/// Defines the base class for threading from MEX files.
/// Only run() needs to be overloaded.
class BackgroundThread {
    
private:
    int _running = false;
    
    /// Start `run()` and set flags
    void start()
    {
        if (!isRunning()) {
            _running = true;
            this->run();
        }
    }
    
public:

    /// Overload this. The actual worker thread method
    virtual void run() = 0;

    /// Run `start()` in a background thread
    void startThreaded()
    {
        if (!isRunning()) {
            std::thread processThread(&BackgroundThread::start, this);
            processThread.detach();
        }
    }
    
    /// @return Whether worker is running
    bool isRunning()
    {
        return _running;
    }
    
    /// Stop the worker
    void stop()
    {
        _running = false;
    }
};

#endif // ! _BackgroundThread_h

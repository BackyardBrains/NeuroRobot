//
//  Created by Djordje Jovic on 11/5/18.
//  Copyright © 2018 Backyard Brains. All rights reserved.
//

#ifndef _BackgroundThread_h
#define _BackgroundThread_h

#include <thread>
#include <iostream>
#include <vector>

/// Defines the base class for threading from MEX files.
/// Only run() needs to be overloaded.
class BackgroundThread {
public:

    /// Overload this. The actual worker thread method
    virtual void run() = 0;

    /// Runs this->run and sets flags
    void start()
    {
        _running = true;
        this->run();
    }

    //! Runs this->start() in a background thread
    void startThreaded() {
        std::thread processThread(&BackgroundThread::start, this);
        processThread.detach();
    }

    bool isRunning() {
        return _running;
    }

    void stop() {
        _running = false;
    }

private:
    int _running = false;
};

#endif // ! _BackgroundThread_h

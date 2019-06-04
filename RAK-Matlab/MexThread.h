//
//  Created by Djordje Jovic on 11/5/18.
//  Copyright © 2018 Backyard Brains. All rights reserved.
//

#ifndef _MexThread_h
#define _MexThread_h

#include <thread>
#include <iostream>
#include <vector>

#ifdef MATLAB
    #include <mex.h>
#endif

//! Defines the base class for threading from MEX files.
// Only run() needs to be overloaded.
class MexThread
{
public:
    

    //-----------------------------------
    // Methods that need to be overloaded.
        
    //! Overload this. The actual worker thread method
    virtual void run() = 0;
    
    //----------------------------------
    // Rest of the methods.
#ifdef MATLAB
    //! Process mex call (e.g. handle calls from MexThread.m )
    void processMexCall( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] )
    {
        int i = 0;
        std::string sMethod;
        convert( prhs[i++], sMethod );

        if( sMethod == "init" )
        {
            _running = 0;
            _finished = 0;
        }
        else if ( sMethod == "start" )
        {
            if( _running )
                mexErrMsgTxt( "startThread: Thread is still running!\n" );

            // Get input parameters (if any)
            std::vector<const mxArray*> rhs(prhs+1,prhs+nrhs);
//            this->parseInputParameters( rhs );

            // Start computation
            this->startThreaded( );
        }
        else if( sMethod == "running" )
        {
            // Query whether the thread is still running
            convert( _running, plhs[0] );
        }
        else if( sMethod == "finished" )
        {
            // Query whether the thread has finished
            convert( _finished, plhs[0] );
        }
        else if( sMethod == "stop" )
        {
            this->stop();
        }
        else
            mexErrMsgTxt( std::string( sMethod + " is not a valid method identifier.").c_str() );


    }
#endif
    
    //! Runs this->run and sets flags
    void start( )
    {
        markFinished( false );
        this->run( );
        markFinished( true );
    }
    
    //! Runs this->start() in a background thread
    void startThreaded( )
    {
        std::thread processThread( &MexThread::start, this );
        processThread.detach(); 
    }
        
   
    void markFinished( bool finished ) { _running = !finished; _finished = finished; }
    void init() { _running = 0; _finished = 0; this->init(); }
    bool running() { return _running; }
    bool finished() { return _finished; }
    
#ifdef MATLAB
    //-----------------------------------------------------------------
    // Methods that convert mxArrays to some other types and vice versa

    //! Converts an mxArray to a std::string
    void convert( const mxArray* ma, std::string& sString )
    {
        if( !mxIsChar( ma ) )
            mexErrMsgTxt( "convert<const mxArray*, std::string&>: !mxIsChar(ma)" );
        char *str = mxArrayToString( ma );
        sString = std::string( str );
    }

    //! Converts an mxArray to a int value
    void convert( const mxArray* ma, int& scalar )
    {
        mxClassID classid = mxGetClassID( ma );
        switch( classid )
        {
        case mxUINT8_CLASS:
            scalar = (int) ((unsigned char*)mxGetData(ma))[0];
            break;
        case mxDOUBLE_CLASS:
            scalar = (int) ((double*)mxGetData(ma))[0];
            break;
        case mxSINGLE_CLASS:
            scalar = (int) ((float*)mxGetData(ma))[0];
            break;
        case mxINT32_CLASS:
            scalar = (int) ((int32_t*)mxGetData(ma))[0];
            break;
        case mxINT16_CLASS:
            scalar = (int) ((int16_t*)mxGetData(ma))[0];
            break;
        case mxUINT32_CLASS:
            scalar = (int) ((uint32_t*)mxGetData(ma))[0];
            break;
        case mxUINT16_CLASS:
            scalar = (int) ((uint16_t*)mxGetData(ma))[0];
            break;
        case mxLOGICAL_CLASS:
            scalar = (int) *mxGetLogicals(ma);
            break;
        default:
            mexErrMsgTxt( "Not a supported mxClassID" );
        }
    }

    //! Converts an mxArray to a int value
    void convert( const mxArray* ma, double& scalar )
    {
        mxClassID classid = mxGetClassID( ma );
        switch( classid )
        {
        case mxUINT8_CLASS:
            scalar = (double) ((unsigned char*)mxGetData(ma))[0];
            break;
        case mxDOUBLE_CLASS:
            scalar = (double) ((double*)mxGetData(ma))[0];
            break;
        case mxSINGLE_CLASS:
            scalar = (double) ((float*)mxGetData(ma))[0];
            break;
        case mxINT32_CLASS:
            scalar = (double) ((int32_t*)mxGetData(ma))[0];
            break;
        case mxINT16_CLASS:
            scalar = (double) ((int16_t*)mxGetData(ma))[0];
            break;
        case mxUINT32_CLASS:
            scalar = (double) ((uint32_t*)mxGetData(ma))[0];
            break;
        case mxUINT16_CLASS:
            scalar = (double) ((uint16_t*)mxGetData(ma))[0];
            break;
        case mxLOGICAL_CLASS:
            scalar = (double) *mxGetLogicals(ma);
            break;
        default:
            mexErrMsgTxt( "Not a supported mxClassID" );
        }
    }

    //! Converts a double scalar to mxArray
    void convert( const double& scalar, mxArray*& ma )
    {
        ma = mxCreateDoubleScalar( (double) scalar );
    }
#endif
    
    bool isRunning()
    {
        return _running; 
    }
    
    void stop()
    {
        _running = 0;
    }
    
private:
    
    //---------------------
    // Private member variables
    int _running = 0;
    int _finished = 0;
    
};



#endif // ! _MexThread_h

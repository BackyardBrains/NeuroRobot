classdef MexThread
   
    methods
        
        % Constructor
        function thread = MexThread( threadFunctionHandle )
            thread.threadFunctionHandle = threadFunctionHandle ;
            thread.threadFunctionHandle( 'init' );
        end
        
        % Starts the worker thread in the background
        function start( thread, varargin )
            thread.threadFunctionHandle( 'start', varargin{:} );
        end
        
        function stop( thread )
            thread.threadFunctionHandle( 'stop' );
        end
        
        % Returns the results from the worker thread
        function varargout = result( thread )
            [varargout{1:nargout}] = thread.threadFunctionHandle( 'result' );
        end
        
        % Queries whether the worker thread is running
        function isRunning = running( thread )
            isRunning = thread.threadFunctionHandle( 'running' );
        end
        
        % Queries whether the worker thread is finised with its work
        function isFinished = finished( thread )
            isFinished = thread.threadFunctionHandle( 'finished' );
        end
        
        function audioFrames = readAudio(this)
            audioFrames = this.threadFunctionHandle('readAudio');
        end
        
        function videoFrames = readVideo(this)
            videoFrames = this.threadFunctionHandle('readVideo');
        end
        
        function isAudioObtained = isAudioObtained(this)
            isAudioObtained = this.threadFunctionHandle('isAudioObtained');
        end
                
    end
    
    
    properties
        % Handle to the worker thread mex function
        threadFunctionHandle;
    end
    
    
    
end


classdef RAK5206_matlab
   
    methods
        
        % Constructor
        function rakObject = RAK5206_matlab(ipAddress, port)
            RAK5206( 'init' ,  ipAddress, port);
        end
        
        % Starts all threads
        function start(this)
            RAK5206( 'start' );
        end
        
        % Reads last ~1sec of audio from shared memory
        function audioFrames = readAudio(this)
            audioFrames = RAK5206( 'readAudio' );
        end
        
        % Reads current frame from shared memory
        function videoFrames = readVideo(this)
            videoFrames = RAK5206( 'readVideo' );
        end
        
        % Stops all threads
        function stop(this)
            RAK5206( 'stop' );
        end
        
        % Queries whether the video/audio thread is running
        function isRunning = isRunning(this)
            isRunning = RAK5206( 'isRunning' );
        end
        
        % Writes serial data through socket
        function writeSerial(this, data)
            RAK5206( 'writeSerial' , data);
        end
        
        % Reads all serial data from shared memory
        function data = readSerial(this)
            data = RAK5206( 'readSerial' );
        end
        
        % Sends audio data through socket
        function sendAudio(this, fileName)
            [data, Fs] = audioread(fileName);
            
            % Change sample rate
            if Fs ~= 8000
                [P,Q] = rat(8000/Fs);
                data = resample(data, P, Q);
            end
            
            % Scale to 14bit
            data = int16(data * 8158);
            RAK5206( 'sendAudio' , data);
        end
        
        % Sends audio data through socket
        function sendAudio2(this, data)
            % Scale to 14bit
            data = int16(data * 8158);
            RAK5206( 'sendAudio' , data);
        end
    end
end


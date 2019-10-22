classdef RAK5206_matlab
   
    methods
        
        % Constructor
        function rakObject = RAK5206_matlab(ipAddress, port)
            RAK_MatlabBridge( 'init' ,  ipAddress, port);
        end
        
        % Starts all threads
        function start(this)
            RAK_MatlabBridge( 'start' );
        end
        
        % Reads last ~1sec of audio from shared memory
        function audioFrames = readAudio(this)
            audioFrames = RAK_MatlabBridge( 'readAudio' );
        end
        
        % Reads current frame from shared memory
        function videoFrames = readVideo(this)
            videoFrames = RAK_MatlabBridge( 'readVideo' );
        end
        
        % Stops all threads
        function stop(this)
            RAK_MatlabBridge( 'stop' );
        end
        
        % Queries whether the video/audio thread is running
        function isRunning = isRunning(this)
            isRunning = RAK_MatlabBridge( 'isRunning' );
        end
        
        % Writes serial data through socket
        function writeSerial(this, data)
            RAK_MatlabBridge( 'writeSerial' , data);
        end
        
        % Reads all serial data from shared memory
        function data = readSerial(this)
            data = RAK_MatlabBridge( 'readSerial' );
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
            RAK_MatlabBridge( 'sendAudio' , data);
        end
        
        % Sends audio data through socket
        function sendAudio2(this, data)
            % Scale to 14bit
            data = int16(data * 8158);
            RAK_MatlabBridge( 'sendAudio' , data);
        end
        
        % Reads stream error
        function data = readStreamState(this)
            data = RAK_MatlabBridge( 'readStreamState' );
        end
        
        % Reads socket error
        function data = readSocketState(this)
            data = RAK_MatlabBridge( 'readSocketState' );
        end
    end
end


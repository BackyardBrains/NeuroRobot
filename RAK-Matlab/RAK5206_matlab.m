classdef RAK5206_matlab
   
    methods
        
        % Constructor
        function rakObject = RAK5206_matlab(ipAddress, port)
            RAK5206( 'init' ,  ipAddress, port);
        end
        
        function start(this)
            RAK5206( 'start' );
        end
        
        function ipAddress = getIpAddress(this)
            ipAddress = RAK5206( 'getIp' );
        end
        function ipAddress = getPort(this)
            ipAddress = RAK5206( 'getPort' );
        end
        
        function audioFrames = readAudio(this)
            audioFrames = RAK5206( 'readAudio' );
        end
        
        function videoFrames = readVideo(this)
            videoFrames = RAK5206( 'readVideo' );
        end
        
        function stop(this)
            RAK5206( 'stop' );
        end
        
        function isRunning = isRunning(this)
            isRunning = RAK5206( 'isRunning' );
        end
        
        function writeSerial(this, data)
            RAK5206( 'writeSerial' , data);
        end
        
        function data = readSerial(this)
            data = RAK5206( 'readSerial' );
        end
        
        function sendAudio(this, fileName)
            [data, Fs] = audioread(fileName);
            % Scale to 14bit
            data = int16(data * 8158);
            RAK5206( 'sendAudio' , data);
        end
        
        function sendAudio2(this, data)
            % Scale to 14bit
            data = int16(data * 8158);
            RAK5206( 'sendAudio' , data);
        end
        
    end
    
    
end


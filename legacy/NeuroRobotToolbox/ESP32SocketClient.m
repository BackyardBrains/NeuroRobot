classdef ESP32SocketClient < WebSocketClient
  %CLIENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        incomingBuffer
    end
    
    methods
        function obj = ESP32SocketClient(varargin)
            %Constructor
            obj@WebSocketClient(varargin{:});
            obj.incomingBuffer =[];
        end
        function [buff] = getIncomingBuffer(obj)
            buff = obj.incomingBuffer;
        end
    end
    
    methods (Access = protected)
        function onOpen(obj,message)
            % This function simply displays the message received
            fprintf('%s\n',message);
        end
       
        function onTextMessage(obj,message)
            % This function simply displays the message received
            obj.incomingBuffer =  message;
            %fprintf('Message received:\n%s\n',message);
        end
        
        function onBinaryMessage(obj,bytearray)
            % This function simply displays the message received
            fprintf('Binary message received:\n');
            fprintf('Array length: %d\n',length(bytearray));
        end
        
        function onError(obj,message)
            % This function simply displays the message received
            fprintf('Error: %s\n',message);
        end
        
        function onClose(obj,message)
            % This function simply displays the message received
            fprintf('%s\n',message);
        end
    end
end


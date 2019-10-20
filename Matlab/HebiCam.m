classdef HebiCam < handle
    % HebiCam acquires frames from streaming video sources
    %   cam = HebiCam(uri) returns an object that acquires images
    %   from the specified resource.
    %
    %   cam = HebiCam(uri, 'ImageMode', 'gray') sets the color
    %   mode. Valid inputs are 'GRAY' and 'COLOR'.
    %
    %   cam = HebiCam(uri, 'timeout', value) additionally specifies a
    %   timeout in [seconds] for grabbing a single frame. Defaults to 1s.
    %
    %   The resource can be an URL of an IP camera, a file descriptor
    %   of a local device (e.g. '/dev/video0'), or a the number
    %   of a local usb camera (e.g. 1). Possible sources are limited
    %   to sources that are supported by FFMpeg or OpenCV.
    %
    % HebiCam Properties:
    %    url      - video source, e.g., local device or remote ip camera
    %    width    - width of the gathered image
    %    height   - height of the gathered image
    %    channels - channel, e.g., rgb or grayscale
    %
    % HebiCam Methods:
    %    getsnapshot - acquires a single image
    %
    %   Example:
    %       % Connect to a device (e.g. usb camera) and display images
    %       clear cam; % make sure usb device is not in use
    %       cam = HebiCam(1);
    %       fig = imshow(getsnapshot(cam));
    %       while true
    %           set(fig, 'CData', getsnapshot(cam));
    %           drawnow;
    %       end
    %
    %    Example:
    %       % Connect to an IP camera (e.g. AXIS) with various optional
    %       % stream settings. Note that the available options are
    %       % different for each manufacturer and/or device.
    %       url = 'rtsp://10.10.10.10/axis-media/media.amp?';
    %       url = [url 'videocodec=h264&resolution=640x480']
    %
    %       % Connect to url and get images in grayscale
    %       cam = HebiCam(url, 'ImageMode', 'gray');
    %
    %       % Continuously display acquired images
    %       fig = imshow(getsnapshot(cam));
    %       while true
    %           [img, frame, time] = getsnapshot(cam);
    %           set(fig, 'CData', img);
    %           title(['Frame: ' num2str(frame) ', Time: ' num2str(time)]);
    %           drawnow;
    %       end
    
    % Copyright (c) 2015-2016 HEBI Robotics
    
    properties (SetAccess = private, GetAccess = public)
        url % video source, e.g., local device or remote ip camera
        width % width of the gathered image
        height % height of the gathered image
        channels % channel, e.g., rgb vs grayscale)
    end
    
    properties (Access = private)
        file
        cam
    end
    
    methods (Static, Access = public)
        function loadLibs()
            % Loads the backing Java files and native binaries. This
            % method assumes that the jar file is located in the same
            % directory as this class-script, and that the file name
            % matches the string below.
            jarFileName = './libraries/hebicam-1.2-SNAPSHOT-all-x86_64.jar';
            
            % Load only once
            if ~exist(...
                    'us.hebi.matlab.streaming.BackgroundFrameGrabber',...
                    'class')
%                 javaaddpath(fullfile(jarFileName))
                javaaddpath(...
                    fullfile(fileparts(mfilename('fullpath')), ...
                    jarFileName));
            end
        end
    end
    
    methods (Access = public)
        
        function this = HebiCam(varargin)
            % constructor - connects to the video source
            
            % parse user input
            p = inputParser;
            p.addRequired('URI', @(v) ~isempty(v) && (isscalar(v) || ischar(v)));
            p.addParameter('Timeout', 1, @(v) isnumeric(v) && v > 0.001); % [s]
            p.addParameter('ImageMode', [], @ischar);
            p.parse(varargin{:});
            args = p.Results;
            
            % make sure Java libraries have been loaded
            HebiCam.loadLibs();
            
            % Create an appropriate frame grabber for the requested location
            this.url = args.URI;
            loc = us.hebi.matlab.streaming.DeviceLocation(args.URI);
            
            if loc.isNumber() % 1, 2, 3, etc.
                
                % Java uses zero based indexing
                javaIndex = args.URI-1;
                grabber = us.hebi.matlab.streaming.FixedOpenCVFrameGrabber(javaIndex);
                
            elseif loc.isUrl() % http://<ip>/mjpeg/, rtsp://...
                
                % Some grabbers have issues if the url is valid, but the
                % device is not reachable, e.g., not turned on. This could
                % result in MATLAB hanging forever, so we need to check
                % whether the device is actually on the network.
                timeoutMs = 5000;
                if ~loc.isReachableUrl(timeoutMs)
                    error('remote url is not reachable');
                end
                
                % Create Grabber
                grabber = org.bytedeco.javacv.FFmpegFrameGrabber(args.URI);
                
                % Set 'low-latency' options for RTSP
                % see https://www.ffmpeg.org/ffmpeg-protocols.html#rtp
                grabber.setOption('rtsp_transport', 'udp');
                grabber.setOption('max_delay', '0'); % disable reordering delay
                grabber.setOption('reorder_queue_size', '1');
                
                % Sometimes mjpeg sources complain when the format is not
                % set. For now we assume that http:// urls are mjpeg
                % streams, which has been true for all ip cameras that I've
                % tested so far. However, this may need to be adapted for
                % some more exotic cameras.
                if loc.hasUrlScheme('http')
                    grabber.setFormat('mjpeg');
                end
                
            else
                % file descriptor, e.g., /dev/usb0
                grabber = us.hebi.matlab.streaming.FixedOpenCVFrameGrabber(args.URI);
            end
            
            % Set a timeout in case a camera gets disconnected or shutdown.
            % Note that this only works for grabbing frames and not at
            % start.
            grabber.setTimeout(int32(args.Timeout * 1E3)); % [s] to [ms]
            
            % Set log level (ffmpeg only?)
            logLevel = org.bytedeco.javacpp.avutil.AV_LOG_FATAL;
            org.bytedeco.javacpp.avutil.av_log_set_level(logLevel);
            
            % Force color mode if applicable
            if ~isempty(args.ImageMode)
                
                if strcmpi(args.ImageMode, 'COLOR') == 1
                    enumField = 'COLOR';
                elseif strcmpi(args.ImageMode, 'GRAY') == 1
                    enumField = 'GRAY';
                else
                    error(['Unknown image mode: ' args.ImageMode]);
                end
                
                % Java enums can't be instantiated directly, so we need
                % to workaround using javaMethod()
                enumClass = 'org.bytedeco.javacv.FrameGrabber$ImageMode';
                mode = javaMethod('valueOf', enumClass, enumField);
                grabber.setImageMode(mode);
                
            end
            
            % Create a Java background thread for the FrameGrabber
            this.cam = us.hebi.matlab.streaming.BackgroundFrameGrabber(grabber);
            
            % Get image data and shared memory location
            this.height = this.cam.getHeight();
            this.width = this.cam.getWidth();
            this.channels = this.cam.getChannels();
            path = char(this.cam.getBackingFile());
            
            % Some versions have problems with mapping HxWx1, so we special
            % case grayscale images.
            pixelFormat = [this.height this.width this.channels];
            if this.channels == 1 % grayscale
                pixelFormat(3) = [];
            end
            
            % Map memory to data
            this.file = memmapfile(path, 'Format', { ...
                'uint64' 1 'frame';
                'double' 1 'timestamp';
                'uint8' pixelFormat 'pixels';
                }, 'Repeat', 1);
            
            % start retrieval
            start(this.cam);
        end
        
        function [I,frame,timestamp] = getsnapshot(this)
            %getsnapshot - acquires a single image frame
            hasImage = tryGetNextImageLock(this.cam);
            if hasImage
                % Mapped memory is accessed by reference, so the data
                % needs to be copied manually.
                data = this.file.Data;
                I = data.pixels * 1;
                frame = data.frame * 1;
                timestamp = data.timestamp * 1;
                tryReleaseImageLock(this.cam);
            else
                stop(this.cam);
                error('Connection to video source was lost. Acquisition stopped.');
            end
        end
        
    end
    
    methods (Access = private)
        function delete(this)
            % destructor - frees resources
            this.file = [];
            stop(this.cam);
        end
    end
end
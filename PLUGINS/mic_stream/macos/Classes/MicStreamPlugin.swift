import Cocoa
import FlutterMacOS

//import UIKit
import AVFoundation
import Dispatch


enum AudioFormat : Int { case ENCODING_PCM_8BIT=3, ENCODING_PCM_16BIT=2 }
enum ChannelConfig : Int { case CHANNEL_IN_MONO=16	, CHANNEL_IN_STEREO=12 }
enum AudioSource : Int { case DEFAULT }

public class SwiftMicStreamPlugin: NSObject, FlutterStreamHandler, FlutterPlugin, AVCaptureAudioDataOutputSampleBufferDelegate {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterEventChannel(name:"aaron.code.com/mic_stream", binaryMessenger: registrar.messenger)
        let methodChannel = FlutterMethodChannel(name: "aaron.code.com/mic_stream_method_channel", binaryMessenger: registrar.messenger)
        let instance = SwiftMicStreamPlugin()
        channel.setStreamHandler(instance);
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
    }

    let isRecording:Bool = false;
    var CHANNEL_CONFIG:ChannelConfig = ChannelConfig.CHANNEL_IN_MONO;
    var SAMPLE_RATE:Int = 44100; // this is the sample rate the user wants
    var actualSampleRate:Float64?; // this is the actual hardware sample rate the device is using
    var AUDIO_FORMAT:AudioFormat = AudioFormat.ENCODING_PCM_16BIT; // this is the encoding/bit-depth the user wants
    var actualBitDepth:UInt32?; // this is the actual hardware bit-depth
    var AUDIO_SOURCE:AudioSource = AudioSource.DEFAULT;
    var BUFFER_SIZE = 4096;
    var eventSink:FlutterEventSink?;
    var session : AVCaptureSession!
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
            case "getSampleRate":
                result(self.actualSampleRate)
                break;
            case "getBitDepth":
                result(self.actualBitDepth)
                break;
            case "getBufferSize":
                result(self.BUFFER_SIZE)
                break;
            case "stopListening":
                print("stop Listening");
                self.session?.stopRunning();
                break;
            default:
                result(FlutterMethodNotImplemented)
        }
    }
    
    public func onCancel(withArguments arguments:Any?) -> FlutterError?  {
        print("onCancel");
        self.session?.stopRunning()
        return nil
    }


    func showDeviceName() {
        let idx:UInt32 = 0;

        // load the current default device
        var deviceId = AudioDeviceID(idx);
        var deviceSize = UInt32(MemoryLayout.size(ofValue: deviceId));
        
        print("total devices : \(MemoryLayout.size(ofValue: deviceId))");
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice, 
            mScope: kAudioObjectPropertyScopeGlobal, 
            mElement: kAudioObjectPropertyElementMaster);
            // mSelector:AudioObjectPropertySelector(kAudioHardwarePropertyDevices),
            // mScope:AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
            // mElement:AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))

        var err = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, idx, nil, &deviceSize, &deviceId);

        //Get the Stream Format (Output client side)
        // err = AudioUnitGetProperty(mInputUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 1, &asbd_dev1_in, &propertySize);
        // let engine = AudioEngine()
        // let inUnit = engine.avEngine.inputNode.audioUnit!

        // err = AudioUnitGetProperty(inUnit, kAudioUnitProperty_SupportedNumChannels, kAudioUnitScope_Input, 1, &asbd_dev1_in, &propertySize);

        // var channelAddress = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultInputDevice, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMaster);
        if ( err == 0) {
            // change the query property and use previously fetched details
            address.mSelector = kAudioDevicePropertyDeviceNameCFString;
            var deviceName = "" as CFString;
            deviceSize = UInt32(MemoryLayout.size(ofValue: deviceName));
            err = AudioObjectGetPropertyData( deviceId, &address, idx, nil, &deviceSize, &deviceName);
            if (err == 0) {
                print("### current default mic:: \(deviceName) \(deviceSize)");
            } else {
                // TODO:: unable to fetch device name 
            }
        } else {
            // TODO:: unable to fetch the default input device
        }
    }    

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        NSLog("ON LISTEN CALLED................... *"); 
        if (isRecording) {
            return nil;
        }
        showDeviceName();
        // let finder:AudioDeviceFinder = AudioDeviceFinder();

        AudioDeviceFinder.findDevices();
    
        let config = arguments as! [Int?];
        // Set parameters, if available
        print(config);
        switch config.count {
            case 4:
                AUDIO_FORMAT = AudioFormat(rawValue:config[3]!)!;
                fallthrough
            case 3:
                CHANNEL_CONFIG = ChannelConfig(rawValue:config[2]!)!;
                if(CHANNEL_CONFIG != ChannelConfig.CHANNEL_IN_MONO) {
                    events(FlutterError(code: "-3",
                                                          message: "Currently only ChannelConfig CHANNEL_IN_MONO is supported", details:nil))
                    return nil
                }
                fallthrough
            case 2:
                SAMPLE_RATE = config[1]!;
                fallthrough
            case 1:
                AUDIO_SOURCE = AudioSource(rawValue:config[0]!)!;
                if(AUDIO_SOURCE != AudioSource.DEFAULT) {
                    events(FlutterError(code: "-3",
                                        message: "Currently only default AUDIO_SOURCE (id: 0) is supported", details:nil))
                    return nil
                }
            default:
                events(FlutterError(code: "-3",
                                  message: "At least one argument (AudioSource) must be provided ", details:nil))
                return nil
        }
        NSLog("Setting eventSinkn: \(config.count)");
        self.eventSink = events;
        startCapture();
        return nil;
    }

    func configureCaptureSession(audioOutput : AVCaptureAudioDataOutput) {        
        self.session.beginConfiguration()
        
        #if os(macOS)
        let numberOfChannels:UInt32 = 1;
        // Note than in macOS, you can change the sample rate, for example to
        // `AVSampleRateKey: 22050`. This reduces the Nyquist frequency and
        // increases the resolution at lower frequencies.
        audioOutput.audioSettings = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMBitDepthKey: 16,
            AVNumberOfChannelsKey: numberOfChannels]
        #endif
        
        if self.session.canAddOutput(audioOutput) {
            self.session.addOutput(audioOutput)
        } else {
            fatalError("Can't add `audioOutput`.")
        }
        
        if #available(macOS 10.15, *) {
            guard
                let microphone = AVCaptureDevice.default(.builtInMicrophone,
                                                         for: .audio,
                                                         position: .unspecified
                ),
                let microphoneInput = try? AVCaptureDeviceInput(device: microphone) else {
                fatalError("Can't create microphone.")
            }
            print("microphoneInput");
            print(microphoneInput.ports.count);

            if self.session.canAddInput(microphoneInput) {
                self.session.addInput(microphoneInput)
            }

        } else {
            // Fallback on earlier versions
        }
        
        
        self.session.commitConfiguration()
    }
        
    
    func startCapture() {
        if let audioCaptureDevice : AVCaptureDevice = AVCaptureDevice.default(for:AVMediaType.audio) {

            self.session = AVCaptureSession()
            do {
                try audioCaptureDevice.lockForConfiguration()
                
                // let audioInput = try AVCaptureDeviceInput(device: audioCaptureDevice)
                let audioOutput = AVCaptureAudioDataOutput()
                configureCaptureSession(audioOutput: audioOutput)

                // audioCaptureDevice.unlockForConfiguration()

                // if(self.session.canAddInput(audioInput)){
                //     self.session.addInput(audioInput)
                // }
                
                
                //let numChannels = CHANNEL_CONFIG == ChannelConfig.CHANNEL_IN_MONO ? 1 : 2
                // setting the preferred sample rate on AVAudioSession  doesn't magically change the sample rate for our AVCaptureSession
                // try AVAudioSession.sharedInstance().setPreferredSampleRate(Double(SAMPLE_RATE))
 
                // neither does setting AVLinearPCMBitDepthKey on audioOutput.audioSettings (unavailable on iOS)
                // 99% sure it's not possible to set streaming sample rate/bitrate
                // try AVAudioSession.sharedInstance().setPreferredOutputNumberOfChannels(numChannels)
                audioOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global())
              
                // if(self.session.canAddOutput(audioOutput)){
                //     self.session.addOutput(audioOutput)x
                // }

                DispatchQueue.main.async {
                    self.session.startRunning()
                }
            } catch let e {
                self.eventSink!(FlutterError(code: "-3",
                             message: "Error encountered starting audio capture, see details for more information.", details:e))
            }
        }
    }
    
    public func captureOutput(_            output      : AVCaptureOutput,
                   didOutput    sampleBuffer: CMSampleBuffer,
                   from         connection  : AVCaptureConnection) {	

				let format = CMSampleBufferGetFormatDescription(sampleBuffer)!
				let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(format)!.pointee
				let nChannels = Int(asbd.mChannelsPerFrame) // probably 2
                // print("nChannels");
                // print(connection.audioChannels);

                // NSArray *audioChannels = connection.audioChannels;
            
                // for (AVCaptureAudioChannel *channel in audioChannels) {
                //     float avg = channel.averagePowerLevel;
                //     float peak = channel.peakHoldLevel;
                //     // Update the level meter user interface.
                // }

				let bufferlistSize = AudioBufferList.sizeInBytes(maximumBuffers: nChannels)
				let audioBufferList = AudioBufferList.allocate(maximumBuffers: nChannels)
				for i in 0..<nChannels {
						audioBufferList[i] = AudioBuffer(mNumberChannels: 0, mDataByteSize: 0, mData: nil)
				}

				var block: CMBlockBuffer?
				let status = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, bufferListSizeNeededOut: nil, bufferListOut: audioBufferList.unsafeMutablePointer, bufferListSize: bufferlistSize, blockBufferAllocator: nil, blockBufferMemoryAllocator: nil, flags: 0, blockBufferOut: &block)
				if (noErr != status) {
					NSLog("we hit an error!!!!!! \(status)")
					return;
				}

        if(audioBufferList.unsafePointer.pointee.mBuffers.mData == nil) {
            return
        }
        
        if(self.actualSampleRate == nil) {
            //let fd = CMSampleBufferGetFormatDescription(sampleBuffer)
            //let asbd:UnsafePointer<AudioStreamBasicDescription>? = CMAudioFormatDescriptionGetStreamBasicDescription(fd!)
            self.actualSampleRate = asbd.mSampleRate
            self.actualBitDepth = asbd.mBitsPerChannel
            print("asbd");
            print(asbd);
        }
        
        let data = Data(bytesNoCopy: audioBufferList.unsafePointer.pointee.mBuffers.mData!, count: Int(audioBufferList.unsafePointer.pointee.mBuffers.mDataByteSize), deallocator: .none)
        self.eventSink!(FlutterStandardTypedData(bytes: data))

    }
}



class AudioDevice {
    var audioDeviceID:AudioDeviceID

    init(deviceID:AudioDeviceID) {
        self.audioDeviceID = deviceID
    }

    var hasOutput: Bool {
        get {
            var address:AudioObjectPropertyAddress = AudioObjectPropertyAddress(
                mSelector:AudioObjectPropertySelector(kAudioDevicePropertyStreamConfiguration),
                mScope:AudioObjectPropertyScope(kAudioDevicePropertyScopeOutput),
                mElement:0)

            var propsize:UInt32 = UInt32(MemoryLayout<CFString?>.size);
            var result:OSStatus = AudioObjectGetPropertyDataSize(self.audioDeviceID, &address, 0, nil, &propsize);
            if (result != 0) {
                return false;
            }

            let bufferList = UnsafeMutablePointer<AudioBufferList>.allocate(capacity:Int(propsize))
            result = AudioObjectGetPropertyData(self.audioDeviceID, &address, 0, nil, &propsize, bufferList);
            if (result != 0) {
                return false
            }

            let buffers = UnsafeMutableAudioBufferListPointer(bufferList)
            for bufferNum in 0..<buffers.count {
                if buffers[bufferNum].mNumberChannels > 0 {
                    return true
                }
            }

            return false
        }
    }

    var uid:String? {
        get {
            var address:AudioObjectPropertyAddress = AudioObjectPropertyAddress(
                mSelector:AudioObjectPropertySelector(kAudioDevicePropertyDeviceUID),
                mScope:AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
                mElement:AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))

            var name:CFString? = nil
            var propsize:UInt32 = UInt32(MemoryLayout<CFString?>.size)
            let result:OSStatus = AudioObjectGetPropertyData(self.audioDeviceID, &address, 0, nil, &propsize, &name)
            if (result != 0) {
                return nil
            }

            return name as String?
        }
    }

    var name:String? {
        get {
            var address:AudioObjectPropertyAddress = AudioObjectPropertyAddress(
                mSelector:AudioObjectPropertySelector(kAudioDevicePropertyDeviceNameCFString),
                mScope:AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
                mElement:AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))

            var name:CFString? = nil
            var propsize:UInt32 = UInt32(MemoryLayout<CFString?>.size)
            let result:OSStatus = AudioObjectGetPropertyData(self.audioDeviceID, &address, 0, nil, &propsize, &name)
            if (result != 0) {
                return nil
            }

            return name as String?
        }
    }
}


class AudioDeviceFinder {
    static func findDevices() {
        var propsize:UInt32 = 0

        var address:AudioObjectPropertyAddress = AudioObjectPropertyAddress(
            mSelector:AudioObjectPropertySelector(kAudioHardwarePropertyDevices),
            mScope:AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
            mElement:AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))

        var result:OSStatus = AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, UInt32(MemoryLayout<AudioObjectPropertyAddress>.size), nil, &propsize)

        if (result != 0) {
            print("Error \(result) from AudioObjectGetPropertyDataSize")
            return
        }

        let numDevices = Int(propsize / UInt32(MemoryLayout<AudioDeviceID>.size))

        var devids = [AudioDeviceID]()
        for _ in 0..<numDevices {
            devids.append(AudioDeviceID())
        }

        result = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &propsize, &devids);
        if (result != 0) {
            print("Error \(result) from AudioObjectGetPropertyData")
            return
        }

        for i in 0..<numDevices {
            let audioDevice = AudioDevice(deviceID:devids[i])
            if (audioDevice.hasOutput) {
                if let name = audioDevice.name,
                    let uid = audioDevice.uid {
                    print("Found device \"\(name)\", uid=\(uid)")
                }
            }
        }
    }
}
import Cocoa
import FlutterMacOS

public class WinaudioPlugin: NSObject, FlutterPlugin {
  private var audioSampleChannelHandler: EventChannelHandler?
  private var audioTimer:Timer?;
  let channelName: String = "winaudio.backyardbrains.com/audio_channel";
  var sampleRate:UInt32 = 48000;
  var deviceInfoIdx:UInt32 = 1000000;
  var handleRecord:HRECORD?;

  var channelSum = 1;


  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "winaudio", binaryMessenger: registrar.messenger)
    // let instance = WinaudioPlugin(id:"winaudio", messenger:registrar.messenger)
    let instance = WinaudioPlugin();
    instance.setupChannel(registrar: registrar);
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  private func setupChannel(registrar: FlutterPluginRegistrar){
    self.audioSampleChannelHandler = EventChannelHandler(id:channelName, messenger:registrar.messenger);    
  }  

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    print("call.method");
    print(call.method);
    switch call.method {
      case "getPlatformVersion":
        result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
        break;
      case "stopListening":
        audioTimer?.invalidate();
        audioTimer = nil;
        break;
      case "startRecording":
        print("SWIFT Start Recording");
        // let a : [UInt8] = [0x00];
        // let b:UnsafeMutableRawPointer = UnsafeMutableRawPointer(mutating:a)
        let initStatus = BASS_Init(-1, sampleRate, 0, nil, nil);
        print("initStatus");
        print(initStatus);

        if (initStatus == 0){   
          channelSum = 2; 
          print(BASS_ErrorGetCode());
          deviceInfoIdx = 1;
          let res = BASS_RecordInit(Int32(deviceInfoIdx));

          // var info:BASS_DEVICEINFO = BASS_DEVICEINFO();
          // BASS_RecordGetDeviceInfo(deviceInfoIdx, &info)
          print("RES");
          print(deviceInfoIdx);
          // print( type(of:res) );        
          print(res);
          // res+=0;
          // _handler->on_callback(flutter::EncodableValue(res));
          handleRecord = BASS_RecordStart(sampleRate, UInt32(channelSum), 0, nil, nil);
          //handle = FALSE;
          print("Handle");
          // print( handleRecord );
          print( type(of:handleRecord) );    
          // Handle
          // Optional(2147483649)
          // Optional<UInt32>              
          if (handleRecord == 0) {
            print("BASS_ERROR_HANDLE 5 : multi channels won't work")
            channelSum = 1;
            handleRecord = BASS_RecordStart(sampleRate, UInt32(channelSum), 0, nil, nil);

            // _handler->on_callback(flutter::EncodableValue("H"));

            // continue;
          }       

    
          // DWORD samplesRead = BASS_ChannelGetData(handle, buffer8, 1 * 48000 * sizeof(uint8_t));
          // let myTimer = Timer(timeInterval: 1.0/sampleRate, target: self, selector: #selector(timerDidFire(_:)), userInfo: nil, repeats: true)
          
          // var tempInterval = 1.0/Double(sampleRate);
          // print("tempInterval");
          // print(tempInterval);
          // let numberOfChannels = 2;
          // var tempInterval = Double(1/20/numberOfChannels);//50;
          let tempInterval = Double(1/20);//50;
          self.audioTimer = Timer(timeInterval: tempInterval, target: self, selector: #selector(self.getAudioSampleData), userInfo: nil, repeats: true)
          RunLoop.current.add(self.audioTimer!, forMode: RunLoop.Mode.common)
        }else{
          print("BASS INIT ERROR");
          result(false);
        }
        result(true);
        break;
      case "initBassAudio":
        // print("BASS_RecordInit(-1)");
        // print(BASS_RecordInit(-1));
        // print(call.arguments);
        // var sampleRate = call.arguments["sampleRate"] as? UInt32;
        if let args = call.arguments as? Dictionary<String, Any>,
          let arg = args["sampleRate"] as? UInt32 {
            sampleRate = arg;
        } else {
          result(FlutterError.init(code: "errorSetDebug", message: "data or format error", details: nil))
        }
        print("sampleRate");
        print(sampleRate);

        let initStatus = BASS_Init(-1, sampleRate, 0, nil, nil);
        print("initStatus0");
        print(initStatus);
        // let a:Int;
        var info:BASS_DEVICEINFO = BASS_DEVICEINFO();
        // for (a = 0; BASS_RecordGetDeviceInfo(a, &info); a++){
        var flag:Int32 = 1;
        var i:UInt32 = 0;
        var virtualDevices = [String : Any]();
        var devicesInfo = [BASS_DEVICEINFO]();
        while (flag == 1 && i < 20){
          flag = BASS_RecordGetDeviceInfo(i,&info);
          devicesInfo.append(info);

          print("info 3");
          // print( Int32(info.flags) & BASS_DEVICE_ENABLED );
          // print( BASS_DEVICE_ENABLED );
          let deviceName: String? = String(validatingUTF8: info.name)
          // print( type(of:info.name) );
          print( deviceName! );
          print( info );
          // print(getStringFromLibrary());
          if( (Int32(info.flags) & BASS_DEVICE_ENABLED) == 0 ){
            print("info disabled");
            print(info);      
            continue;
          }
          if (deviceInfoIdx == 1000000){
            deviceInfoIdx = i;
          }
            
          i = i + 1;
          var j = 0;
          for j in stride(from: 0, to:2, by:1){
            // virtualDevice.device = i;
            // virtualDevice.channel = j;
            // virtualDevice.name = std::string(info.name) + ((j == 0) ? " [Left]" : " [Right]");
            // virtualDevice.threshold = 100;
            // virtualDevice.bound = false;
            let mapDevice:[String:Any] = [
              "device" :  i,
              "channel" :  j,
              "threshold" :  100,
              "bound" :  false,
              "name" :  deviceName!+((j == 0) ? " [Right]" : " [Left]"),
            ];
            // print(mapDevice);
            // print(info.name+((j == 0) ? " [Left]" : " [Right]"));
            if (j % 2 == 0){
              virtualDevices[deviceName!+"_R"] = mapDevice;
            }else{
              virtualDevices[deviceName!+"_L"] = mapDevice;
            }
            // virtualDevices.append(mapDevice);
            // _virtualDevices.push_back(virtualDevice);
          } 


          // virtualDevices.map { (a: (String, Any)) -> NSURLQueryItem in
          //   print("a.0");
          //   print(a.0);
          //   print("a.1");
          //   print(a.1);
          //   return NSURLQueryItem(name: a.0, value: a.0)
          // }     

        }


      // https://github.com/BackyardBrains/Spike-Recorder/blob/327cd6ff142238c657a7cb68ff536f65fcbb2b98/src/engine/RecordingManager.cpp#L879
      // let initStatus = NSNumber(value:BASS_RecordInit(-1));
      // if (initStatus != 1) {
      //   print("Can't initialize device");
      // }
        // var jsonData = try JSONSerialization.data(withJSONObject: virtualDevices, options: JSONSerialization.WritingOptions.prettyPrinted)
        // let json =  NSString(data: jsonData as Data, encoding: NSUTF8StringEncoding)! as String
        // result(json);

        // result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
        result(virtualDevices);
        break;
      default:
        result(FlutterMethodNotImplemented)
      }
  }


  @objc func getAudioSampleData() {
    let sizeOf = 1;
      // print("getAudioSampleData");
      // label.text = "\(counter)"
    // var buffer16 = [Int16](repeating: 0, count: Int(sampleRate) )
    var buffer8 = [UInt8](repeating: 0, count: Int(sampleRate ) )
    // print("buffer8");
    // print( type(of:buffer8) );        
    let channelSize = channelSum * Int(sampleRate) * sizeOf;
    let samplesRead = BASS_ChannelGetData(handleRecord!, &buffer8, UInt32(channelSize) );
    //https://stackoverflow.com/questions/34951824/how-can-i-interleave-two-arrays
    // var samplesRead = BASS_ChannelGetData(handleRecord!, &buffer16, channelSum * sampleRate * sizeOf);
    // print("samplesRead");
    // print(samplesRead);
    // print( type(of:samplesRead) );          
    if (samplesRead>0){
      if (samplesRead == 4294967295){
        // print(BASS_ErrorGetCode());

        return;
      }
      // print("samplesRead > 0");
      // print(samplesRead);

      let subarray = Array(buffer8[0...(Int(samplesRead)-1) ]);
      // print("subarray");
      // print(subarray);
      // print(array);
      // let subarray = Array(buffer16[0...Int(samplesRead)]);
      // if (subarray.count < samplesRead){
        // print("subarray.count")
        // print(subarray.count)
        // print(samplesRead)
      // }
      // let evenA = subarray.enumerated().filter { $0.0 % 2 == 0 }.map{ $0.1 }
      // let oddA = subarray.enumerated().filter { $0.0 % 2 != 0 }.map{ $0.1 }
      // print("evenA");
      // print(evenA);
      // print("subarray");
      // print(subarray);
      // for j in stride(from: 0, to:2, by:1){      


      // subarray.count
      // 883
      // 882

      do {
        if (channelSum == 1){
          let size = subarray.count;
          var combine8 = [UInt8](repeating: 0, count: Int( size * 2 ) );
          // let array = zip(subarray, subarray).flatMap({ [$0, $1] })      
          let tempSize = combine8.count;
          for j in stride(from: 0, to: Int(size), by:2){
            // if (j*2 >= subarray.count || j*2+1 >= subarray.count){
              // print("j*2");
              // print(j*2);
              // print("====== subarray.count");
              // print(size);
              // print(tempSize);

            // }
            
            combine8[j*2]=subarray[j];
            combine8[j*2+2]=subarray[j];
            combine8[j*2+1]=subarray[j+1];
            combine8[j*2+3]=subarray[j+1];
            // combine8[j*2+1]=subarray[j+1];
          }

          try self.audioSampleChannelHandler?.success(event: combine8)
        }else{
          try self.audioSampleChannelHandler?.success(event: subarray)              
        }
      } catch {
          self.audioSampleChannelHandler?.error(code: "loginFailure", message: error.localizedDescription)
      }      
    }
  }  


}



public class EventChannelHandler: NSObject, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
      self.eventSink = events
      return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
      eventSink = nil
      return nil
  }

  public init(id: String, messenger: FlutterBinaryMessenger) {
      super.init()
      let eventChannel = FlutterEventChannel(name: id, binaryMessenger: messenger)
      eventChannel.setStreamHandler(self)
  }


  public func success(event: Any?) throws {
      if eventSink != nil {
          eventSink?(event)
      }
  }

  public func error(code: String, message: String?, details: Any? = nil) {
      if eventSink != nil {
          eventSink?(FlutterError(code: code, message: message, details: details))
      }
  }

}
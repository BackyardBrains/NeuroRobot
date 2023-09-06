#import "MfiPlugin.h"
// #import "DemoAccessory.h"
@interface spikestatusStreamHandler : NSObject<FlutterStreamHandler>
@end
@interface devicestatusStreamHandler : NSObject<FlutterStreamHandler>
@end

@implementation MfiPlugin

static NSString* spikeStatusEvent = @"spikestatus/event";
static NSString* deviceStatusEvent = @"devicestatus/event";
FlutterEventChannel* spikeStatusChannel;
FlutterEventSink spikeStatusSink;
FlutterEventChannel* deviceStatusChannel;
FlutterEventSink deviceStatusSink;

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"mfi"
            binaryMessenger:[registrar messenger]];
  MfiPlugin* instance = [[MfiPlugin alloc] init];

  spikeStatusChannel = [FlutterEventChannel eventChannelWithName:spikeStatusEvent binaryMessenger:[registrar messenger]];
  [spikeStatusChannel setStreamHandler: [spikestatusStreamHandler new] ]; 

  deviceStatusChannel = [FlutterEventChannel eventChannelWithName:deviceStatusEvent binaryMessenger:[registrar messenger]];
  [deviceStatusChannel setStreamHandler: [devicestatusStreamHandler new] ];

  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"getPlatformVersion" isEqualToString:call.method]) {
    result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
  } else 
  if ([@"initMfi" isEqualToString:call.method]) {
    NSString *status = call.arguments[@"status"];
    // changeDeviceStatus("connected");
    //init MFI from the

  } else 
  if ([@"setDeviceStatus" isEqualToString:call.method]) {
    NSString *status = call.arguments[@"status"];
    if ([@"disconnect" isEqualToString:status]){
      // tell MFI library to disconnect?
      [self changeDeviceStatus:status];
    }else{
      [self changeDeviceStatus:status];
    }
  } else 
  if ([@"setSpikeStatus" isEqualToString:call.method]) {
    NSString *status = call.arguments[@"status"];
  } else 
  if ([@"getSpikeStatus" isEqualToString:call.method]) {
    NSString *res = @"test getString";
    // Stevanus note :
    // We can do process here to get the data from the device
    //    e.g. getCurrentData()
    //    to return back to the flutter to render please send it using this streamSink : 
    //     spikeStatusSink(res)
    //     Parameter res is a NSString
    spikeStatusSink(res);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

-(void)changeDeviceStatus:(NSString*)str{
  if ( [str isEqualToString:@"connected"] ){
    deviceStatusSink(str);
    //getState p300 or HPF
    //if (some condition){
      // setState p300 gain, hpf
    // }
    // demo
    [self streamSample:str];
    // streamSample(@"string");
  }else
  if ( [str isEqualToString:@"disconnected"] ){
    deviceStatusSink(str);
  }
}

+ (UInt8 *)convertToBytes:(int)i {
    UInt8 *retVal = malloc(sizeof(UInt8) * 4);
    retVal[0] = i >> 24;
    retVal[1] = i >> 16;
    retVal[2] = i >> 8;
    retVal[3] = i >> 0;
    return retVal;
}

-(void)streamSample:(NSString*)str{
  // spikeStatusSink(str);
  // let data = Data(
  //   bytesNoCopy: audioBufferList.unsafePointer.pointee.mBuffers.mData!, 
  //   count: Int(audioBufferList.unsafePointer.pointee.mBuffers.mDataByteSize), 
  //   deallocator: .none)
  // int something = 900;
  // UInt8 *bytesOfInt = [[self class] convertToBytes:something];

  uint8_t theData[] = { 3, 4, 5 };
  NSData *data = [NSData dataWithBytes:&theData length:sizeof(theData)];  

  // const char *cBuffer=[str UTF8String];
  // NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];

  FlutterStandardTypedData* rest = [FlutterStandardTypedData typedDataWithBytes: data];

  spikeStatusSink(rest);

}

@end


@implementation spikestatusStreamHandler
- (FlutterError*)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)eventSink {
    NSLog(@"STATUS SINK");
    spikeStatusSink = eventSink;
  return nil;
}

- (FlutterError*)onCancelWithArguments:(id)arguments {
    spikeStatusSink = nil;
  return nil;
}
@end


@implementation devicestatusStreamHandler
- (FlutterError*)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)eventSink {
    NSLog(@"DEVICE STATUS SINK");
    deviceStatusSink = eventSink;
  return nil;
}

- (FlutterError*)onCancelWithArguments:(id)arguments {
    deviceStatusSink = nil;
  return nil;
}
@end

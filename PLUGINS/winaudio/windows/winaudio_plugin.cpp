//https://betterprogramming.pub/dynamic-theme-settings-change-in-a-flutter-desktop-app-63f137630417
#include <iostream>
#include "winaudio_plugin.h"
#include<thread>
#include <chrono>
#include <vector>
// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/event_channel.h>
#include <flutter/event_sink.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
// #include "flutter/shell/platform/common/cpp/client_wrapper/include/flutter/event_channel.h"
#include <mutex>
#include <string>
#include <memory>
#include <sstream>
// #pragma comment(lib,"bass/bass.lib")
// #import bass.dll
#define BASSDEF(f) (WINAPI *f) // define the functions as pointers
#include "bass/bass.h"

namespace winaudio {
int sampleRate = 44100;
int deviceInfoIdx = 1000000;
HRECORD handleRecord;

int channelSum = 1;
bool isSampling = true;

const flutter::EncodableValue* ValueOrNull(const flutter::EncodableMap& map, const char* key) {
  auto it = map.find(flutter::EncodableValue(key));
  if (it == map.end()) {
    return nullptr;
  }
  return &(it->second);
}
template<typename T = flutter::EncodableValue>
class MyStreamHandler: public flutter::StreamHandler<T> {
public:

	MyStreamHandler () = default;
	virtual ~MyStreamHandler () = default;

	void on_callback (flutter::EncodableValue _data) {
            std::unique_lock<std::mutex> _ul (m_mtx);
            if (m_sink.get ())
    		    m_sink.get ()->Success (_data);
    	}
protected:
	std::unique_ptr<flutter::StreamHandlerError<T>> OnListenInternal (const T *arguments, std::unique_ptr<flutter::EventSink<T>> &&events) override {
        std::unique_lock<std::mutex> _ul (m_mtx);
		m_sink = std::move (events);
        return nullptr;
	}
	std::unique_ptr<flutter::StreamHandlerError<T>> OnCancelInternal (const T *arguments) override {
        std::unique_lock<std::mutex> _ul (m_mtx);
		m_sink.release ();
        return nullptr;
	}
private:
	flutter::EncodableValue m_value;
    std::mutex m_mtx;
	std::unique_ptr<flutter::EventSink<T>> m_sink;
};
MyStreamHandler<> *_handler=new MyStreamHandler<> ();

void getAudioStream(HINSTANCE bass)
{
  // BASS_ChannelGetData = reinterpret_cast<DWORD (__stdcall*)(DWORD handle, void *buffer, DWORD length)> (GetProcAddress(bass,"BASS_ChannelGetData"));
  // BASS_StreamCreate = reinterpret_cast<HSTREAM (__stdcall*)(DWORD freq, DWORD chans, DWORD flags, STREAMPROC *proc, void *user)>(GetProcAddress(bass,"BASS_StreamCreate") );

  // HSTREAM stream = BASS_StreamCreate(48000,2,BASS_STREAM_DECODE, STREAMPROC_PUSH,NULL);
  // std::vector<int16_t> *channels = new std::vector<int16_t>[2];
  // int16_t *buffer = new int16_t[2 * 5 *48000];
  // DWORD samplesRead = BASS_ChannelGetData(stream, buffer, 2 * 5 * 48000 * sizeof(int16_t));
  // if (samplesRead == (DWORD)-1){

  // }
  // samplesRead /= sizeof(int16_t);
  // for (int chan = 0; chan < 2; chan++){
  //   channels[chan].resize(5*48000);

  // }
  int i = 0;
  while(true){
    i++;
    if (i>10){
      break;
    }
    // std::vector<int> msg{1000,2000,3333,4444,5555};
    // _handler->on_callback(flutter::EncodableValue(1234567));
    // std::string c = std::to_string(BASS_ErrorGetCode());
    // if (BASS_ErrorGetCode()>-1){ //END STREAM
    //   _handler->on_callback(flutter::EncodableValue(123));

    // }


  }
    // Do something
}

// static
void WinaudioPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "winaudio",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<WinaudioPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });


  const std::string channel_name("winaudio.backyardbrains.com/audio_channel");
  // bool on_listen_called = false;
  // const StandardMethodCodec& codec = &flutter::StandardMethodCodec::GetInstance();
  // flutter::EventChannel<flutter::EncodableValue> eventChannel(registrar->messenger(), channel_name, &flutter::StandardMethodCodec::GetInstance());  
  // auto eventChannel = std::make_unique<flutter::EventChannel<flutter::EncodableValue>>( (registrar->messenger()), channel_name, &flutter::StandardMethodCodec::GetInstance() );
  // auto eventChannel=( (registrar->messenger()), channel_name, &flutter::StandardMethodCodec::GetInstance() );
  // flutter::EventChannel<flutter::EncodableValue> eventChannel = std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(registrar->messenger(), channel_name, &flutter::StandardMethodCodec::GetInstance());
  std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>> eventChannel;
  
  eventChannel = std::make_unique<flutter::EventChannel<flutter::EncodableValue>> (
    registrar->messenger (), channel_name,
    &flutter::StandardMethodCodec::GetInstance ()
  );

  // auto onListen = [&on_listen_called](const flutter::EncodableValue* arguments,
  //                    flutter::EventSink<flutter::EncodableValue>* event_sink) {
  //   flutter::EncodableList v = {7, 5, 16, 8};
  //   auto message = flutter::EncodableValue(v);
  //   // event_sink->Success();
  //   // auto message = flutter::EncodableValue(flutter::EncodableMap{
  //   //       {flutter::EncodableValue("message"),
  //   //            flutter::EncodableValue("Test from Event Channel")}
  //   //     });
  //   // event_sink->Success(&message);
	//   // event_sink->Error("Event Channel Error Code",
	// 	//               	  "Error Message",
	// 	// 	                nullptr);
  // 	// event_sink->EndOfStream();
	//   event_sink->Success(&message);

  //   on_listen_called = true;
  // };

  // bool on_cancel_called = false;
  // auto onCancel = [&on_cancel_called](const flutter::EncodableValue* arguments) {
  //   on_cancel_called = true;
  
  // };

  
  // plugin->m_handler = _handler;
  // auto _obj_stm_handle = static_cast<flutter::StreamHandler<flutter::EncodableValue>*> (plugin->m_handler);
  auto _obj_stm_handle = static_cast<flutter::StreamHandler<flutter::EncodableValue>*> (_handler);
  std::unique_ptr<flutter::StreamHandler<flutter::EncodableValue>> _ptr {_obj_stm_handle};
  eventChannel->SetStreamHandler (std::move (_ptr));  
  
  registrar->AddPlugin(std::move(plugin));
}

WinaudioPlugin::WinaudioPlugin() {}

WinaudioPlugin::~WinaudioPlugin() {}

void WinaudioPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {

    HINSTANCE bass = LoadLibrary(L"bass.dll");

    BASS_Init=reinterpret_cast<BOOL (__stdcall*)(int device, DWORD freq, DWORD flags, HWND win, const void *dsguid)> (GetProcAddress(bass,"BASS_Init"));
    BASS_ErrorGetCode=reinterpret_cast<int (__stdcall*)(void)> (GetProcAddress(bass,"BASS_ErrorGetCode"));
    // BASS_Init(-1,48000,0,0,NULL);
      BASS_ChannelGetData = reinterpret_cast<DWORD (__stdcall*)(DWORD handle, void *buffer, DWORD length)> (GetProcAddress(bass,"BASS_ChannelGetData"));
      BASS_StreamCreate = reinterpret_cast<HSTREAM (__stdcall*)(DWORD freq, DWORD chans, DWORD flags, STREAMPROC *proc, void *user)>(GetProcAddress(bass,"BASS_StreamCreate") );
      BASS_RecordGetDeviceInfo = reinterpret_cast<BOOL (__stdcall*)(DWORD device, BASS_DEVICEINFO *info)>(GetProcAddress(bass,"BASS_RecordGetDeviceInfo"));
      BASS_RecordSetDevice = reinterpret_cast<BOOL (__stdcall*)(DWORD device)>(GetProcAddress(bass,"BASS_RecordSetDevice"));
      BASS_RecordInit = reinterpret_cast<BOOL (__stdcall*)(int device)>(GetProcAddress(bass,"BASS_RecordInit"));
      BASS_RecordStart = reinterpret_cast<HRECORD (__stdcall*)(DWORD freq, DWORD chans, DWORD flags, RECORDPROC *proc, void *user)>(GetProcAddress(bass,"BASS_RecordStart"));

  if (method_call.method_name().compare("getPlatformVersion") == 0) {
    std::ostringstream version_stream;
    version_stream << "Windows ";
    if (IsWindows10OrGreater()) {
      version_stream << "10+";
    } else if (IsWindows8OrGreater()) {
      version_stream << "8";
    } else if (IsWindows7OrGreater()) {
      version_stream << "7";
    }
  }else
  if (method_call.method_name().compare("stopListening") == 0) {
    // isSampling = false;
  }else
  if (method_call.method_name().compare("initBassAudio") == 0) {
    sampleRate = 44100;
    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!arguments){

    }else{

      sampleRate = *std::get_if<int>(ValueOrNull(*arguments, "sampleRate"));
    }
    // var initStatus = BASS_Init(-1, sampleRate, 0, NULL, NULL);



    
    BASS_Init(-1, sampleRate, 0, 0, NULL);
    // let a:Int;
    // std::cout << sampleRate;
    // flutter::EncodableList virtualDevices;
    //     virtualDevices.push_back(flutter::EncodableMap({
    //       {flutter::EncodableValue("sampleRate"), flutter::EncodableValue(sampleRate)},
    //       {flutter::EncodableValue("device"), flutter::EncodableValue(1)},
    //       {flutter::EncodableValue("channel"), flutter::EncodableValue(2)},
    //       {flutter::EncodableValue("threshold"), flutter::EncodableValue(100)},
    //       {flutter::EncodableValue("bound"), flutter::EncodableValue(false)},
    //       {flutter::EncodableValue("name"), flutter::EncodableValue(" [Right]")},
    //     }));
    // result->Success( ( flutter::EncodableValue(virtualDevices)) );
    // return;
    
    
    // /*
    BASS_DEVICEINFO info;
    // for (a = 0; BASS_RecordGetDeviceInfo(a, &info); a++){
    int flag = 1;
    int i = 0;
    std::vector< BASS_DEVICEINFO > devicesInfo;
    flutter::EncodableList virtualDevices;
    while (flag == 1 && i < 20){
      flag = BASS_RecordGetDeviceInfo(i, &info);
      devicesInfo.push_back(info);

      std::string deviceName = info.name;
      // print(getStringFromLibrary());
      if(!(info.flags & BASS_DEVICE_ENABLED)){
        continue;
      }
      if (deviceInfoIdx == 1000000){
        deviceInfoIdx = i;
      }
        
      i = i + 1;
      int j = 0;
      for (j = 0; j<2; j++){
        virtualDevices.push_back(flutter::EncodableMap({
          {flutter::EncodableValue("device"), flutter::EncodableValue(i)},
          {flutter::EncodableValue("channel"), flutter::EncodableValue(j)},
          {flutter::EncodableValue("threshold"), flutter::EncodableValue(100)},
          {flutter::EncodableValue("bound"), flutter::EncodableValue(false)},
          {flutter::EncodableValue("name"), flutter::EncodableValue(std::string(info.name) + ((j == 0) ? " [Right]" : " [Left]"))},
        }));
      } 
    }
    // result->Success(std::move( flutter::EncodableValue(virtualDevices)) );
    std::cout << 222222;
    std::cout << "virtualDevices";
    result->Success( ( flutter::EncodableValue(virtualDevices)) );
// */
  }else
  if (method_call.method_name().compare("startRecording") == 0) {
    // HINSTANCE bass = LoadLibrary(L"H:\\us\\BYB\\srmobileapp\\PLUGINS\\winaudio\\windows\\bass.dll");
    // BASS_Init = (GetProcAddress(bass,"BASS_Init"));
    
    if (!BASS_Init(-1,sampleRate,0,0,NULL)){
      channelSum = 2; 



      // HSTREAM stream = BASS_StreamCreate(48000,2,BASS_STREAM_DECODE, STREAMPROC_PUSH,NULL);
      // std::vector<int16_t> *channels = new std::vector<int16_t>[2];
      // int16_t *buffer = new int16_t[2 * 5 *48000];
      // DWORD samplesRead = BASS_ChannelGetData(stream, buffer, 2 * 5 * 48000 * sizeof(int16_t));
      // if (samplesRead == (DWORD)-1){

      // }
      // samplesRead /= sizeof(int16_t);
      // for (int chan = 0; chan < 2; chan++){
      //   channels[chan].resize(5*48000);

      // }

      // std::thread thread_object(getAudioStream, bass);
      std::string c = std::to_string(BASS_ErrorGetCode());
      std::thread ([this] () {
        std::vector<uint8_t> msg{100,200,133,144,155};
        // HSTREAM stream = BASS_StreamCreate(48000,1,BASS_STREAM_DECODE, STREAMPROC_PUSH,NULL);
        BASS_DEVICEINFO info;
        
        int a = 0;
        for (a = 0; BASS_RecordGetDeviceInfo(a, &info); a++)
          if (info.flags & BASS_DEVICE_ENABLED) {
            // if(!BASS_RecordSetDevice(a)) {
            // }else{


            // }

            // _handler->on_callback(flutter::EncodableValue("I"));
            int res = BASS_RecordInit(a);
            res+=0;
            // _handler->on_callback(flutter::EncodableValue(res));
            HRECORD handle = BASS_RecordStart(sampleRate, channelSum, 0, NULL, NULL);
            //handle = FALSE;
            if (handle == FALSE) {
              // _handler->on_callback(flutter::EncodableValue("H"));
              channelSum = 1;
              handle = BASS_RecordStart(sampleRate, channelSum, 0, NULL, NULL);
              // continue;
            }       
            // _handler->on_callback(flutter::EncodableValue("O"));

            while (isSampling){
              // _handler->on_callback(flutter::EncodableValue(msg));
              try {
                uint8_t *buffer8 = new uint8_t[channelSum * 48000];
                DWORD samplesRead = BASS_ChannelGetData(handle, buffer8, channelSum * 48000 * sizeof(uint8_t));
                // int16_t *buffer = new int16_t[2 * 5 *48000];
                // DWORD samplesRead = BASS_ChannelGetData(stream, buffer, 2 * 5 * 48000 * sizeof(int16_t));
                // int16_t *buffer = new int16_t[1 * 48000];
                // DWORD samplesRead = BASS_ChannelGetData(handle, buffer, 1 * 48000 * sizeof(int16_t));
                if (samplesRead == (DWORD)-1){
                }
                // std::vector<int16_t> *channels = new std::vector<int16_t>[2];

                // const int channum = 2;
                // const int channum = 1;
                // samplesRead /= sizeof(uint8_t);
                // // samplesRead /= sizeof(int16_t);
                // int countSamplesRead = (int)samplesRead;
                
                // samplesRead /= sizeof(uint8_t);

                // uint8_t *buffer8 = new uint8_t[2 * 48000];
                // for (DWORD i = 0; i < samplesRead/channum; i++) {

                //   int16_t initialVal = buffer[i];
                //   uint8_t arrayofbyte[2];
                //   // int16_t to uint8_t
                //   // medianVal.getBytes(medianVal, sizeof(initialVal));
                //   // uint8_t* finalVal = medianVal;
                //   // uint8_t firstValAbs = firstVal >= 0 ? firstVal : -firstVal;
                //   // uint8_t* secondVal = &firstValAbs;
                //   memcpy( arrayofbyte,&initialVal, 2 );
                //   buffer8[i*2]=arrayofbyte[0];
                //   buffer8[i*2+1]=arrayofbyte[1];
                // }
                // for (DWORD i = 0; i < samplesRead/channum; i++) {
                //     for(int chan = 0; chan < channum; chan++) {
                //         // channels[chan][i] = buffer[i*channum + chan];//sort data to channels

                //         // if(chan ==0)
                //         // {
                //         //     rmsOfOriginalSignal = 0.0001*((float)(channels[chan][i]*channels[chan][i]))+0.9999*rmsOfOriginalSignal;

                //         // }
                //     }
                // }

                // uint8_t *buffers = new uint8_t[4];
                // buffers[0] = 100;
                // buffers[1] = 101;
                // buffers[2] = 102;
                // buffers[3] = 103;
                std::vector<uint8_t> subarray(&buffer8[0], &buffer8[samplesRead]);

                if (channelSum == 1){
                  size_t size = subarray.size();
                  std::vector<uint8_t> combine8;
                  size_t tempSize = size * 2;
                  combine8.reserve(tempSize);
                  for (int j = 0; j < tempSize; j+=2){
                    combine8[j*2]=subarray[j];
                    combine8[j*2+2]=subarray[j];
                    combine8[j*2+1]=subarray[j+1];
                    combine8[j*2+3]=subarray[j+1];
                  }

                  _handler->on_callback(flutter::EncodableValue(combine8));
                }else{
                // if (my_vector.size()/channum == 0){
                //   continue;
                // }
                  _handler->on_callback(flutter::EncodableValue(subarray));

                }
                std::this_thread::sleep_for(std::chrono::milliseconds(50));


              }
              catch (int myNum) {
                // _handler->on_callback(flutter::EncodableValue(-100000));
                myNum+=0;
              }


              // _handler->on_callback(flutter::EncodableValue(msg));
            }            
               
            break;
          }// device is enabled



      }).detach ();


      // _handler->on_callback(flutter::EncodableValue(123));


      // result->Success(flutter::EncodableValue("@"+c));
      result->Success(flutter::EncodableValue(true));

    }else{
      std::string c = std::to_string(BASS_ErrorGetCode());

      std::vector<int> msg{1000,2000,3333,4444,5555};

      _handler->on_callback(flutter::EncodableValue(msg));

      // std::cout << c;
      // std::cout << BASS_ErrorGetCode();
      result->Success(flutter::EncodableValue(c));
    }

  } else {
    result->NotImplemented();
  }
}

}  // namespace winaudio

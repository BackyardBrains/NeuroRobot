#import "NativecPlugin.h"
#if __has_include(<nativec/nativec-Swift.h>)
#import <nativec/nativec-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "nativec-Swift.h"
#endif

@implementation NativecPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftNativecPlugin registerWithRegistrar:registrar];
}
@end

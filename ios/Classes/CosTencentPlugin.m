#import "CosTencentPlugin.h"
#if __has_include(<cos_tencent_plugin/cos_tencent_plugin-Swift.h>)
#import <cos_tencent_plugin/cos_tencent_plugin-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "cos_tencent_plugin-Swift.h"
#endif

@implementation CosTencentPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftCosTencentPlugin registerWithRegistrar:registrar];
}
@end

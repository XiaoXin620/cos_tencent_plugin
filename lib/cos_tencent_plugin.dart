
import 'dart:async';

import 'package:flutter/services.dart';

class CosTencentPlugin {
  static const MethodChannel _channel = MethodChannel('cos_tencent_plugin');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    final String? version1 =await _channel.invokeMethod("uploadFile",<String,dynamic>{
      "localPath": "sss",
      "appid": "add",
      "region": "regionsss",
      "region": "regionsssss",
      "cosPath": "cosPath",
      "bucket":"bucket1122"
    });
    return version1;
  }
}

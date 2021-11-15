import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:cos_tencent_plugin/cos_tencent_plugin.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await CosTencentPlugin.platformVersion ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Image(),
      ),
    );
  }
}

class Image extends StatefulWidget {
  const Image({Key? key}) : super(key: key);

  @override
  _ImageState createState() => _ImageState();
}

class _ImageState extends State<Image> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(onPressed: () async {
        final List<AssetEntity>? assets =
        await AssetPicker.pickAssets(context, maxAssets: 1);
        if (assets != null) {
          AssetEntity asset = assets.first;
          File? file = await asset.originFile;
          CosTencentPlugin.uploadByFile(
              "ap-guangzhou",
              "1300991923",
              "xyiot-1300991923",
              "secretId",
              "secretKey",
              "sessionToken",
              "expiredTime",
              "saas-files/50438161-2734-4eae-89ab-d11d39bb0096",
              file!.path);
        }
      }, child: Text("选择文件上传"),),
    );
  }
}


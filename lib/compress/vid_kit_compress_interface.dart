import 'dart:async';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:vid_kit/compress/vid_kit_compress_controller.dart';
import 'package:vid_kit/compress/vid_kit_compress_method_channel.dart';
import 'package:vid_kit/enums/vid_kit_quality.dart';

abstract base class VidKitCompressInterface extends PlatformInterface {
  static final Object _token = Object();
  VidKitCompressInterface() : super(token: _token);

  static VidKitCompressInterface _instance =
      VidKitCompressMethodChannel.instance;

  static VidKitCompressInterface get instance => _instance;

  static set instance(VidKitCompressInterface instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  VidKitCompressController get controller;

  Future<String> compressVideo({
    required String path,
    required VidKitQuality quality,
    bool? includeAudio,
    required int frameRate,
  });

  Future<void> cancelCompression();

  Future<void> dispose();
}

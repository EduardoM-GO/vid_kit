import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class VidKitPlatform extends PlatformInterface {
  VidKitPlatform() : super(token: _token);

  static final Object _token = Object();

  static set instance(VidKitPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
  }

  Future<Duration> getVideoDuration(String path);

  Future<String> trimVideo({
    required String inputPath,
    required String outputPath,
    required Duration start,
    required Duration end,
  });

  Future<Uint8List> getThumbnail({
    required String path,
    int quality = 100,
    int position = -1,
  });
}

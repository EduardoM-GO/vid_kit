import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:vid_kit/compress/vid_kit_compress_progress.dart';
import 'package:vid_kit/enums/vid_kit_quality.dart';
import 'package:vid_kit/vid_kit_method_channel.dart';

abstract class VidKitPlatform extends PlatformInterface {
  VidKitPlatform() : super(token: _token);

  static final Object _token = Object();

  static VidKitPlatform _instance = MethodChannelVidKit.instance;
  
  static VidKitPlatform get instance => _instance;

  static set instance(VidKitPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
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

  Future<String> compressVideo({
    required String path,
    required VidKitQuality quality,
    bool? includeAudio,
    required int frameRate,
  });

  bool get isCompressing;

  VidKitCompressProgress? get compressProgress;

  Future<void> cancelCompression();

  Future<void> dispose();
}

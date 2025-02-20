import 'dart:typed_data';

import 'package:vid_kit/compress/vid_kit_compress_progress.dart';
import 'package:vid_kit/enums/vid_kit_quality.dart';
import 'package:vid_kit/vid_kit_method_channel.dart';

import 'vid_kit_platform_interface.dart';

class VidKit {
  final VidKitPlatform _vidKitPlatform;

  VidKit() : _vidKitPlatform = MethodChannelVidKit.instance;

  Future<Duration> getVideoDuration(String path) =>
      _vidKitPlatform.getVideoDuration(path);

  Future<String> trimVideo({
    required String inputPath,
    required String outputPath,
    required Duration start,
    required Duration end,
  }) =>
      _vidKitPlatform.trimVideo(
          inputPath: inputPath, outputPath: outputPath, start: start, end: end);

  Future<Uint8List> getThumbnail({
    required String path,
    int quality = 100,
    int position = -1,
  }) =>
      _vidKitPlatform.getThumbnail(
          path: path, quality: quality, position: position);

  Future<String> compressVideo(
    String path, {
    VidKitQuality quality = VidKitQuality.res1280x720Quality,
    bool? includeAudio,
    int frameRate = 30,
  }) =>
      _vidKitPlatform.compressVideo(
        path: path,
        quality: quality,
        includeAudio: includeAudio,
        frameRate: frameRate,
      );

  bool get isCompressing => _vidKitPlatform.isCompressing;

  VidKitCompressProgress? get compressProgress =>
      _vidKitPlatform.compressProgress;

  Future<void> cancelCompression() => _vidKitPlatform.cancelCompression();

  Future<void> dispose() => _vidKitPlatform.dispose();
}

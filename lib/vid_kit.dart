import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:vid_kit/compress/vid_kit_compress_controller.dart';
import 'package:vid_kit/compress/vid_kit_compress_interface.dart';
import 'package:vid_kit/enums/vid_kit_quality.dart';
import 'package:vid_kit/vid_kit_method_channel.dart';

import 'vid_kit_platform_interface.dart';

class VidKit {
  final VidKitPlatform _vidKitPlatform;
  final VidKitCompressInterface _compressProgress;

  VidKit()
      : _vidKitPlatform = MethodChannelVidKit(),
        _compressProgress = VidKitCompressInterface.instance;

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

  FutureOr<String> compressVideo({
    required String path,
    VidKitQuality quality = VidKitQuality.mediumQuality,
    bool? includeAudio,
    int frameRate = 30,
  }) =>
      _compressProgress.compressVideo(
          path: path, quality: quality, frameRate: frameRate);

  VidKitCompressController get compressController =>
      _compressProgress.controller;

  Future<void> cancelCompression() => _compressProgress.cancelCompression();

  Future<void> dispose() => _compressProgress.dispose();
}

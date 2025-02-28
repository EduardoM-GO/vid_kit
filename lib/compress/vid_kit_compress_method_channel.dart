import 'dart:async';

import 'package:flutter/services.dart';
import 'package:vid_kit/compress/vid_kit_compress_controller.dart';
import 'package:vid_kit/compress/vid_kit_compress_interface.dart';
import 'package:vid_kit/enums/vid_kit_quality.dart';

final class VidKitCompressMethodChannel extends VidKitCompressInterface {
  static const _methodChannel = MethodChannel('vid_kit');
  static VidKitCompressMethodChannel? _instance;
  VidKitCompressController? _controller;

  VidKitCompressMethodChannel._();
  static VidKitCompressMethodChannel get instance =>
      _instance ??= VidKitCompressMethodChannel._();

  @override
  Future<String> compressVideo({
    required String path,
    required VidKitQuality quality,
    bool? includeAudio,
    required int frameRate,
  }) async {
    controller.isCompressing = true;

    final result = await _methodChannel.invokeMethod<String>('compressVideo', {
      'path': path,
      'quality': quality.index,
      'includeAudio': includeAudio,
      'frameRate': frameRate,
    });

    controller.isCompressing = false;

    if (result == null) {
      throw ArgumentError.notNull('compressVideo');
    }

    return result;
  }

  @override
  VidKitCompressController get controller =>
      _controller ??= VidKitCompressController(_methodChannel);

  @override
  Future<void> dispose() async {
    if (_controller?.isCompressing ?? false) {
      await cancelCompression();
    }

    _controller?.dispose();
    _controller = null;
  }

  @override
  Future<void> cancelCompression() =>
      _methodChannel.invokeMethod('cancelCompression');
}

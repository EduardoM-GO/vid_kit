import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vid_kit/compress/vid_kit_compress.dart';
import 'package:vid_kit/compress/vid_kit_compress_progress.dart';
import 'package:vid_kit/enums/vid_kit_quality.dart';

import 'vid_kit_platform_interface.dart';

/// An implementation of [VidKitPlatform] that uses method channels.
final class MethodChannelVidKit extends VidKitPlatform {
  static MethodChannelVidKit? _instance;

  /// The method channel used to interact with the native platform.
  @visibleForTesting
  static const methodChannel = MethodChannel('vid_kit');
  final VidKitCompress _compress;

  MethodChannelVidKit._() : _compress = VidKitCompress(methodChannel);

  static MethodChannelVidKit get instance =>
      _instance ??= MethodChannelVidKit._();

  @override
  Future<Duration> getVideoDuration(String path) async {
    final result = await _invokeMethod<double>('getVideoDuration', {
      'path': path,
    });

    if (result == null) {
      throw ArgumentError.notNull('getVideoDuration');
    }
    return Duration(milliseconds: result.toInt());
  }

  @override
  Future<String> trimVideo({
    required String inputPath,
    required String outputPath,
    required Duration start,
    required Duration end,
  }) async {
    final result = await _invokeMethod<String>('trimVideo', {
      'inputPath': inputPath,
      'outputPath': outputPath,
      'startMs': start.inMilliseconds,
      'endMs': end.inMilliseconds,
    });

    if (result == null) {
      throw ArgumentError.notNull('trimVideo');
    }

    return result;
  }

  @override
  Future<Uint8List> getThumbnail(
      {required String path, int quality = 100, int position = -1}) async {
    assert(quality > 0 && quality <= 100, 'quality must be between 1 and 100');

    final result = await _invokeMethod<Uint8List>('getThumbnail', {
      'path': path,
      'quality': quality,
      'position': position,
    });

    if (result == null) {
      throw ArgumentError.notNull('getThumbnail');
    }

    return result;
  }

  @override
  VidKitCompressProgress? get compressProgress => _compress;

  @override
  bool get isCompressing => _compress.isCompressing;

  @override
  Future<String> compressVideo({
    required String path,
    required VidKitQuality quality,
    bool? includeAudio,
    required int frameRate,
  }) async {
    if (isCompressing) {
      throw StateError('''VideoCompress Error: 
      Method: compressVideo
      Already have a compression process, you need to wait for the process to finish or stop it''');
    }

    _compress.isCompressing = true;

    final result = await _invokeMethod<String>('compressVideo', {
      'path': path,
      'quality': quality.index,
      'includeAudio': includeAudio,
      'frameRate': frameRate,
    });

    _compress.isCompressing = false;

    if (result == null) {
      throw ArgumentError.notNull('compressVideo');
    }

    return result;
  }

  @override
  Future<void> cancelCompression() async {
    await _invokeMethod<String>('cancelCompression');
  }

  Future<T?> _invokeMethod<T>(String method,
      [Map<String, dynamic>? arguments]) async {
    try {
      if (arguments != null) {
        return methodChannel.invokeMethod(method, arguments);
      }

      return methodChannel.invokeMethod(method);
    } on PlatformException catch (e, stack) {
      log(
        'Error from Method: $method',
        error: e,
        stackTrace: stack,
        name: 'VidKit',
      );
    }
    return null;
  }

  @override
  Future<void> dispose() async {
    if (_compress.isCompressing) {
      await cancelCompression();
    }
    _compress.dispose();
    _instance = null;
  }
}

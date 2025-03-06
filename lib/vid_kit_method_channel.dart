import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'vid_kit_platform_interface.dart';

/// An implementation of [VidKitPlatform] that uses method channels.
final class MethodChannelVidKit extends VidKitPlatform {
  @visibleForTesting
  static const methodChannel = MethodChannel('vid_kit');

  MethodChannelVidKit();

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
    final fileOutput = File(outputPath);
    if (fileOutput.existsSync()) {
      fileOutput.deleteSync();
    }

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
}

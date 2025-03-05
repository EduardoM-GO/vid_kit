import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vid_kit/vid_kit_platform_interface.dart';

void main() {
  late _MockVidKitPlatform mockPlatform;

  setUp(() {
    mockPlatform = _MockVidKitPlatform();
    VidKitPlatform.instance = mockPlatform;
  });

  group('VidKitPlatform', () {
    test('getVideoDuration returns correct duration', () async {
      final duration = await mockPlatform.getVideoDuration('test.mp4');
      expect(duration, const Duration(seconds: 10));
    });

    test('trimVideo returns output path', () async {
      final result = await mockPlatform.trimVideo(
        inputPath: 'input.mp4',
        outputPath: 'output.mp4',
        start: const Duration(seconds: 0),
        end: const Duration(seconds: 5),
      );
      expect(result, 'output.mp4');
    });

    test('getThumbnail returns bytes with default parameters', () async {
      final thumbnail = await mockPlatform.getThumbnail(path: 'test.mp4');
      expect(thumbnail, isA<Uint8List>());
      expect(thumbnail.length, 4);
    });

    test('getThumbnail accepts custom quality and position', () async {
      final thumbnail = await mockPlatform.getThumbnail(
        path: 'test.mp4',
        quality: 80,
        position: 1000,
      );
      expect(thumbnail, isA<Uint8List>());
      expect(thumbnail.length, 4);
    });
  });
}

class _MockVidKitPlatform extends VidKitPlatform {
  @override
  Future<Duration> getVideoDuration(String path) async {
    return const Duration(seconds: 10);
  }

  @override
  Future<String> trimVideo({
    required String inputPath,
    required String outputPath,
    required Duration start,
    required Duration end,
  }) async {
    return outputPath;
  }

  @override
  Future<Uint8List> getThumbnail({
    required String path,
    int quality = 100,
    int position = -1,
  }) async {
    return Uint8List.fromList([0, 1, 2, 3]);
  }
}

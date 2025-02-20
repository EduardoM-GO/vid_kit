import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:vid_kit/compress/vid_kit_compress_progress.dart';
import 'package:vid_kit/enums/vid_kit_quality.dart';
import 'package:vid_kit/vid_kit.dart';
import 'package:vid_kit/vid_kit_method_channel.dart';
import 'package:vid_kit/vid_kit_platform_interface.dart';

void main() {
  setUp(() {});

  final VidKitPlatform initialPlatform = VidKitPlatform.instance;

  test('vid kit - $MethodChannelVidKit is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelVidKit>());
  });

  group('vid kit -', () {
    late VidKit vidKitPlugin;
    setUp(() {
      vidKitPlugin = VidKit();
      _MockVidKitPlatform fakePlatform = _MockVidKitPlatform();
      VidKitPlatform.instance = fakePlatform;
    });

    test('vid kit - getVideoDuration', () async {
      expect(await vidKitPlugin.getVideoDuration(''),
          equals(Duration(seconds: 1)));
    });

    test('vid kit - trimVideo', () async {
      expect(
          await vidKitPlugin.trimVideo(
              inputPath: '',
              outputPath: '',
              start: Duration(seconds: 1),
              end: Duration(seconds: 2)),
          equals(''));
    });
  });
}

final class _MockVidKitPlatform
    with MockPlatformInterfaceMixin
    implements VidKitPlatform {
  @override
  Future<Duration> getVideoDuration(String path) =>
      Future.value(Duration(seconds: 1));

  @override
  Future<String> trimVideo(
          {required String inputPath,
          required String outputPath,
          required Duration start,
          required Duration end}) =>
      Future.value(outputPath);

  @override
  Future<void> cancelCompression() async {}

  @override
  VidKitCompressProgress? get compressProgress => null;

  @override
  Future<String> compressVideo({
    required String path,
    required VidKitQuality quality,
    int? startTime,
    int? duration,
    bool? includeAudio,
    required int frameRate,
  }) =>
      Future.value('');

  @override
  Future<Uint8List> getThumbnail(
          {required String path, int quality = 100, int position = -1}) =>
      Future.value(Uint8List(0));

  @override
  bool get isCompressing => false;

  @override
  Future<void> dispose() async {}
}

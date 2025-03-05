import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vid_kit/vid_kit_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelVidKit platform = MethodChannelVidKit();
  const MethodChannel channel = MethodChannel('vid_kit');

  group('vid kit method channel - trimVideo -', () {
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async {
          if (methodCall.method == 'trimVideo' &&
              methodCall.arguments['inputPath'] != 'erro') {
            return methodCall.arguments['outputPath'];
          }

          return null;
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });
    test('Ok', () async {
      final result = await platform.trimVideo(
        inputPath: 'inputPath',
        outputPath: 'outputPath',
        start: const Duration(seconds: 1),
        end: const Duration(seconds: 2),
      );

      expect(result, isA<String>());
      expect(result, equals('outputPath'));
    });

    test('Error', () async {
      expect(
          () async => await platform.trimVideo(
                inputPath: 'erro',
                outputPath: 'outputPath',
                start: const Duration(seconds: 1),
                end: const Duration(seconds: 2),
              ),
          throwsA(isA<ArgumentError>()));
    });
  });

  group('vid kit method channel - getVideoDuration -', () {
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async {
          if (methodCall.method == 'getVideoDuration' &&
              methodCall.arguments['path'] == 'inputPath') {
            return 10000.0;
          }

          return null;
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });
    test('Ok', () async {
      final result = await platform.getVideoDuration('inputPath');

      expect(result, isA<Duration>());
      expect(result, equals(Duration(seconds: 10)));
    });

    test('Error', () async {
      expect(() async => await platform.getVideoDuration('erro'),
          throwsA(isA<ArgumentError>()));
    });
  });
}

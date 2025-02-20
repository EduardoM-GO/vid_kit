import 'package:vid_kit/compress/vid_kit_compress_progress.dart';

final class VidKitCompress extends VidKitCompressProgress {
  VidKitCompress(super.methodChannel);

  @override
  double? get progress {
    if (_isCompressing) {
      return super.progress;
    }
    return null;
  }

  bool _isCompressing = false;

  bool get isCompressing => _isCompressing;

  set isCompressing(bool value) {
    _isCompressing = value;
    notifyListeners();
  }
}

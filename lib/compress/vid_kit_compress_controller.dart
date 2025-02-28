import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class VidKitCompressController extends ChangeNotifier {
  final MethodChannel _methodChannel;
  bool _isCompressing;
  double _progress;
  VidKitCompressController(this._methodChannel)
      : _isCompressing = false,
        _progress = 0 {
    _methodChannel.setMethodCallHandler((call) async {
      if (call.method == 'updateProgress') {
        final progress = call.arguments as double?;
        _progress = progress ?? 0;
        notifyListeners();
      }
    });
  }

  bool get isCompressing => _isCompressing;

  set isCompressing(bool value) {
    _isCompressing = value;
    notifyListeners();
  }

  double get progress => _progress;

  @override
  void dispose() {
    _methodChannel.setMethodCallHandler(null);
    super.dispose();
  }
}

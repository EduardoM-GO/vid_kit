import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract base class VidKitCompressProgress extends ChangeNotifier {
  final MethodChannel _methodChannel;

  VidKitCompressProgress(this._methodChannel) {
    _methodChannel.setMethodCallHandler(_updateProgress);
  }

  Future<void> _updateProgress(MethodCall call) async {
    if (call.method == 'updateProgress') {
      final progress = call.arguments as double?;
      _progress = progress ?? 0;
      notifyListeners();
    }
  }

  double? _progress;

  double? get progress => _progress;

  @override
  void dispose() {
    _methodChannel.setMethodCallHandler(null);
    super.dispose();
  }
}

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:vid_kit/vid_kit.dart';

class VideoDetalheWidget extends StatefulWidget {
  final String path;
  const VideoDetalheWidget({super.key, required this.path});

  @override
  State<VideoDetalheWidget> createState() => _VideoDetalheWidgetState();
}

class _VideoDetalheWidgetState extends State<VideoDetalheWidget> {
  late final VidKit _vidKitPlugin;
  bool _isLoading = true;
  Duration? _duration;
  String? tamanhoVideo;

  @override
  void initState() {
    super.initState();
    _vidKitPlugin = VidKit();

    scheduleMicrotask(() {
      getDadosVideo();
    });
  }

  @override
  void didUpdateWidget(covariant VideoDetalheWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    scheduleMicrotask(() {
      getDadosVideo();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 16,
      children: [
        compressVideo,
        Text('Duração: ${_duration?.inSeconds}s'),
        Text('Tamanho: $tamanhoVideo')
      ],
    );
  }

  Widget get compressVideo {
    return AnimatedBuilder(
      animation: _vidKitPlugin.compressController,
      builder: (context, child) =>
          _vidKitPlugin.compressController.isCompressing
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [
                    child!,
                    LinearProgressIndicator(
                      value: _vidKitPlugin.compressController.progress,
                    ),
                  ],
                )
              : SizedBox(),
      child: Text('Compressão ...'),
    );
  }

  Future<void> getDadosVideo() async {
    setState(() {
      _isLoading = true;
    });

    final results = await Future.wait([
      _vidKitPlugin.getVideoDuration(widget.path),
      File(widget.path).length()
    ]);

    setState(() {
      _duration = results[0] as Duration;
      tamanhoVideo = tamanhoFormatado(results[1] as int);
      _isLoading = false;
    });
  }

  String tamanhoFormatado(int tamanho) {
    if (tamanho <= 0) {
      return '0 B';
    }
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    final i = (log(tamanho) / log(1024)).floor();
    return '${(tamanho / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
  }
}

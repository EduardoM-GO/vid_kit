import 'dart:io';

import 'package:flutter/material.dart';
import 'package:vid_kit_example/video_detalhe_widget.dart';
import 'package:video_player/video_player.dart';

class VideoWidget extends StatefulWidget {
  final File file;
  const VideoWidget({super.key, required this.file});

  @override
  State<VideoWidget> createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file);
    _controller.initialize().then(
      (_) {
        setState(() {});
      },
    );
  }

  @override
  void didUpdateWidget(covariant VideoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.dispose();
    _controller = VideoPlayerController.file(widget.file);
    _controller.initialize().then(
      (_) {
        setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        spacing: 16,
        children: [
          Expanded(
              child: _controller.value.isInitialized
                  ? VideoPlayer(_controller)
                  : const Center(child: CircularProgressIndicator())),
          ElevatedButton(
            onPressed: () {
              _controller.value.isPlaying
                  ? _controller.pause()
                  : _controller.play();
            },
            child: Icon(
              _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
            ),
          ),
          if (_controller.value.isInitialized)
            VideoDetalheWidget(path: widget.file.path),
        ],
      );
}

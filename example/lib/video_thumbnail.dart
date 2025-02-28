import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vid_kit/vid_kit.dart';

class VideoThumbnail extends StatefulWidget {
  final String path;
  const VideoThumbnail({super.key, required this.path});

  @override
  State<VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<VideoThumbnail> {
  late final VidKit _vidKit;
  Image? image;

  @override
  void initState() {
    super.initState();
    _vidKit = VidKit();
    scheduleMicrotask(getThumbnail);
  }

  void getThumbnail() async {
    final result = await _vidKit.getThumbnail(
      path: widget.path,
      quality: 100,
      position: -1,
    );
    setState(() {
      image = Image.memory(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('getThumbnail'),
      ),
      body: Center(
        child: image ??
            Center(
              child: CircularProgressIndicator(),
            ),
      ),
    );
  }
}

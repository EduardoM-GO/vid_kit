import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vid_kit/enums/vid_kit_quality.dart';
import 'package:vid_kit/vid_kit.dart';
import 'package:vid_kit_example/video_thumbnail.dart';
import 'package:vid_kit_example/video_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const MyHome(),
    );
  }
}

class MyHome extends StatefulWidget {
  const MyHome({super.key});

  @override
  State<MyHome> createState() => _MyHomeState();
}

class _MyHomeState extends State<MyHome> {
  late final VidKit _vidKitPlugin;
  File? _file;
  late bool isLoading;

  @override
  void initState() {
    super.initState();
    _vidKitPlugin = VidKit();
    isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Video'),
        ),
        body: _file == null
            ? Center(
                child: isLoading
                    ? const CircularProgressIndicator()
                    : Text('Nenhum video selecionado'),
              )
            : VideoWidget(file: _file!),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            FloatingActionButton(
              heroTag: UniqueKey(),
              onPressed: obterVideo,
              child: Icon(Icons.add),
            ),
            if (_file != null) ...[
              FloatingActionButton(
                heroTag: UniqueKey(),
                onPressed: trim,
                child: Icon(Icons.crop_rounded),
              ),
              FloatingActionButton(
                heroTag: UniqueKey(),
                onPressed: compress,
                child: Icon(Icons.compress),
              ),
              FloatingActionButton(
                heroTag: UniqueKey(),
                onPressed: () => Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (context) => VideoThumbnail(
                          path: _file!.path,
                        ),
                      ),
                    )
                    .whenComplete(() => setState(() {})),
                child: Icon(Icons.image),
              ),
            ]
          ],
        ),
      ),
    );
  }

  void obterVideo() async {
    setState(() {
      isLoading = true;
    });
    final file = await ImagePicker().pickVideo(
      source: ImageSource.gallery,
    );

    setState(() {
      isLoading = false;
      if (file != null) {
        _file = File(file.path);
      } else {
        _file = null;
      }
    });
  }

  void trim() async {
    setState(() {
      isLoading = true;
    });
    final String path = _file!.path;

    final result = await _vidKitPlugin.trimVideo(
      inputPath: path,
      outputPath: '${path.substring(0, path.length - 4)}_trim.mp4',
      start: Duration(seconds: 0),
      end: Duration(seconds: 30),
    );
    setState(() {
      isLoading = false;
      _file = File(result);
    });
  }

  void compress() async {
    final String path = _file!.path;
    final result = await _vidKitPlugin.compressVideo(
      path: path,
      quality: VidKitQuality.mediumQuality,
    );
    setState(() {
      _file = File(result);
    });
  }
}

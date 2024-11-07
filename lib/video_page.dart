import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPage extends StatefulWidget {
  final String filePath;

  const VideoPage({Key? key, required this.filePath}) : super(key: key);

  @override
  _VideoPageState createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  late VideoPlayerController _videoPlayerController;

  @override
  void dispose() {
    _videoPlayerController.dispose();
    super.dispose();
  }

  Future _initVideoPlayer() async {
    _videoPlayerController = VideoPlayerController.file(File(widget.filePath));
    await _videoPlayerController.initialize();
    await _videoPlayerController.setLooping(true);
    await _videoPlayerController.play();
  }

  @override
  Widget build(BuildContext context) {
    // var size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(''),
        elevation: 0,
        backgroundColor: Colors.black26,
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left_rounded,
            color: Colors.white,
            size: 40,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.check,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context, File(widget.filePath));
            },
          )
        ],
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: FutureBuilder(
          future: _initVideoPlayer(),
          builder: (context, state) {
            if (state.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else {
              return VideoPlayer(_videoPlayerController);
            }
          },
        ),
      ),
      bottomNavigationBar: Container(
        height: 40,
        width: double.infinity,
        color: Colors.black,
      ),
    );
  }
}

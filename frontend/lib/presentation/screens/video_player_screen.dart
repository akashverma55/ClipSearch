import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:go_router/go_router.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoId;
  final double timestamp;
  final String videoSource;
  final String videoType;

  const VideoPlayerScreen({
    super.key,
    required this.videoId,
    required this.timestamp,
    required this.videoSource,
    required this.videoType,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  YoutubePlayerController? _youtubeController;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.videoType == 'YouTube') {
      _initializeYoutubePlayer();
    }
  }

  void _initializeYoutubePlayer() {
    try {
      final videoId = YoutubePlayer.convertUrlToId(widget.videoSource);
      
      if (videoId == null) {
        setState(() {
          _error = 'Invalid YouTube URL';
          _isLoading = false;
        });
        return;
      }

      print('Video ID: $videoId');

      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
        ),
      );

      _youtubeController!.addListener(() {
        if (_youtubeController == null) return;
        
        final value = _youtubeController!.value;
        
        print('State: ${value.playerState}, Ready: ${value.isReady}');
        
        if (value.isReady && _isLoading) {
          setState(() {
            _isLoading = false;
          });
        }

        if (value.hasError) {
          setState(() {
            _error = 'Error: ${value.errorCode}';
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('YouTube Test'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : _error != null
                ? Text(_error!, style: const TextStyle(color: Colors.white))
                : _youtubeController != null
                    ? YoutubePlayer(
                        controller: _youtubeController!,
                        showVideoProgressIndicator: true,
                      )
                    : const Text('No player', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
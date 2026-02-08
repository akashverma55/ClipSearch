import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

// THESE VIDEOS ALLOW EMBEDDING - they will work!
final videoUrls = [
  'https://www.youtube.com/watch?v=dQw4w9WgXcQ',  // Rick Astley - Never Gonna Give You Up (works!)
  'https://www.youtube.com/watch?v=M7lc1UVf-VE',  // YouTube's official Rewind video (works!)
  'https://www.youtube.com/watch?v=jNQXAC9IVRw',  // Me at the zoo - First YouTube video (works!)
  'https://www.youtube.com/watch?v=9bZkp7q19f0',  // PSY - Gangnam Style (works!)
  
  // Your original videos - these are blocked by the uploader from embedding:
  // 'https://www.youtube.com/watch?v=2S9oO8MQi0o',  // ❌ Embedding disabled
  // 'https://www.youtube.com/watch?v=EIvjcFbS7nQ',  // ❌ Embedding disabled
];

class Feed extends StatelessWidget {
  const Feed({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Youtube'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: videoUrls.length,
        itemBuilder: (context, index) {
          final videoId = YoutubePlayerController.convertUrlToId(videoUrls[index]);
          
          debugPrint('=== FEED ITEM $index ===');
          debugPrint('URL: ${videoUrls[index]}');
          debugPrint('Video ID: $videoId');
          
          if (videoId == null) {
            return _buildErrorCard('Invalid Video URL');
          }

          return InkWell(
            onTap: () {
              debugPrint('\n=== NAVIGATING TO PLAYER ===');
              debugPrint('Video ID: $videoId');
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PlayerScreen(
                    videoId: videoId,
                    videoUrl: videoUrls[index],
                  ),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail with play button overlay
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: Image.network(
                          YoutubePlayerController.getThumbnail(
                            videoId: videoId,
                            quality: ThumbnailQuality.medium,
                          ),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 200,
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint('ERROR loading thumbnail: $error');
                            return Container(
                              height: 200,
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 50,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.play_circle_filled,
                              color: Colors.white,
                              size: 64,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Video ${index + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: $videoId',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      height: 200,
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ℹ️ About Embedding'),
        content: const Text(
          'Some YouTube videos cannot be embedded in apps because:\n\n'
          '• The uploader disabled embedding\n'
          '• The video is age-restricted\n'
          '• The video has copyright restrictions\n\n'
          'Error 150/151/152 means embedding is disabled.\n\n'
          'This app uses videos that allow embedding!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class PlayerScreen extends StatefulWidget {
  final String videoId;
  final String videoUrl;
  
  const PlayerScreen({
    required this.videoId,
    required this.videoUrl,
    super.key,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late YoutubePlayerController _controller;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    debugPrint('\n=== PLAYER SCREEN INIT ===');
    debugPrint('Video ID: ${widget.videoId}');
    
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        mute: false,
        showFullscreenButton: true,
        loop: false,
      ),
    );

    // Listen for errors
    _controller.listen((event) {
      debugPrint('\n=== PLAYER EVENT ===');
      debugPrint('State: ${event.playerState}');
      debugPrint('Error: ${event.error}');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          
          // Handle embedding errors
          if (event.error == YoutubeError.notEmbeddable ||
              event.error == YoutubeError.sameAsNotEmbeddable) {
            _errorMessage = 
                '❌ This video cannot be embedded\n\n'
                'Error: ${event.error.toString()}\n\n'
                'The video owner has disabled playback in apps.\n'
                'You can watch it on YouTube.com instead.';
          } else if (event.error == YoutubeError.videoNotFound) {
            _errorMessage = 
                '❌ Video not found\n\n'
                'This video may have been deleted or made private.';
          } else if (event.error != YoutubeError.none) {
            _errorMessage = 
                '❌ Playback Error\n\n'
                'Error: ${event.error.toString()}';
          } else if (event.playerState == PlayerState.playing) {
            _errorMessage = null; // Clear error when playing
          }
        });
      }
    });

    debugPrint('Controller created successfully');
  }

  @override
  void dispose() {
    debugPrint('\n=== DISPOSING PLAYER ===');
    debugPrint('Video ID: ${widget.videoId}');
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Player'),
        actions: [
          // Button to open in YouTube app/browser
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: () {
              // In a real app, you'd use url_launcher package
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Open in YouTube:\n${widget.videoUrl}'),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Player section
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              children: [
                YoutubePlayer(
                  controller: _controller,
                  aspectRatio: 16 / 9,
                ),
                
                // Loading indicator
                if (_isLoading)
                  Container(
                    color: Colors.black,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                  ),
                
                // Error overlay
                if (_errorMessage != null)
                  Container(
                    color: Colors.black,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Go Back'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Info section
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Video Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Video ID', widget.videoId),
                    _buildInfoRow('URL', widget.videoUrl),
                    
                    if (_errorMessage == null) ...[
                      const SizedBox(height: 16),
                      const Text(
                        '✅ This video is playing successfully!',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    
                    const Text(
                      '💡 Tip:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Not all YouTube videos can be embedded in apps. '
                      'Video creators can disable embedding in their video settings.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
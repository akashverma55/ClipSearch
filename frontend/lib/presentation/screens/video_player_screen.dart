import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/time_formatter.dart';

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
  VideoPlayerController? _videoPlayerController;
  
  bool _isLoading = true;
  bool _isPlaying = false;
  bool _hasEnded = false;
  String? _error;
  
  // For progress tracking
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      if (widget.videoType == 'YouTube') {
        _initializeYoutubePlayer();
      } else {
        await _initializeFilePlayer();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _initializeYoutubePlayer() {
    try {
      final videoId = YoutubePlayer.convertUrlToId(widget.videoSource);
      
      if (videoId == null) {
        setState(() {
          _error = 'Invalid YouTube URL: ${widget.videoSource}';
          _isLoading = false;
        });
        return;
      }

      print('Initializing YouTube player with video ID: $videoId');
      print('Starting at timestamp: ${widget.timestamp}');

      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          enableCaption: false,
          isLive: false,
          forceHD: false,
          hideControls: false,
          controlsVisibleAtStart: true,
          loop: false,
          disableDragSeek: false,
        ),
      );

      bool hasSeenReady = false;
      
      // Add a timeout to detect if player never loads
      Future.delayed(const Duration(seconds: 15), () {
        if (mounted && _isLoading && !hasSeenReady) {
          setState(() {
            _error = 'YouTube player failed to load. Please check your internet connection.';
            _isLoading = false;
          });
        }
      });
      
      _youtubeController!.addListener(() {
        if (_youtubeController == null || !mounted) return;
        
        final value = _youtubeController!.value;
        
        print('YouTube Player State: ${value.playerState}, Ready: ${value.isReady}, Error: ${value.hasError}');
        
        // Handle initial ready state
        if (value.isReady && !hasSeenReady) {
          hasSeenReady = true;
          print('YouTube player is ready! Duration: ${_youtubeController!.metadata.duration}');
          
          if (mounted) {
            setState(() {
              _isLoading = false;
              _totalDuration = _youtubeController!.metadata.duration;
            });
            
            // Seek to timestamp if not at start
            if (widget.timestamp > 0) {
              print('Seeking to timestamp: ${widget.timestamp}');
              _youtubeController!.seekTo(Duration(seconds: widget.timestamp.toInt()));
            }
          }
        }

        // Update position and duration (only when not dragging and ready)
        if (!_isDragging && value.isReady && mounted) {
          final position = value.position;
          final duration = _youtubeController!.metadata.duration;
          
          if (position != _currentPosition || duration != _totalDuration) {
            setState(() {
              _currentPosition = position;
              if (duration.inSeconds > 0) {
                _totalDuration = duration;
              }
            });
          }
        }

        // Track playing state
        if (value.isPlaying != _isPlaying && mounted) {
          setState(() {
            _isPlaying = value.isPlaying;
          });
        }

        // Track ended state
        if (value.playerState == PlayerState.ended && !_hasEnded && mounted) {
          setState(() {
            _hasEnded = true;
            _isPlaying = false;
          });
        }

        // Handle errors
        if (value.hasError && mounted) {
          print('YouTube player error: ${value.errorCode}');
          setState(() {
            _error = 'YouTube playback error: ${value.errorCode}';
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      print('Error initializing YouTube player: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to initialize YouTube player: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _initializeFilePlayer() async {
    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoSource),
    );

    await _videoPlayerController!.initialize();
    
    // Listen to state changes
    _videoPlayerController!.addListener(() {
      if (_videoPlayerController == null) return;
      
      final value = _videoPlayerController!.value;
      
      // Update position and duration
      if (!_isDragging && mounted) {
        setState(() {
          _currentPosition = value.position;
          _totalDuration = value.duration;
        });
      }
      
      // Track playing state
      if (value.isPlaying != _isPlaying) {
        if (mounted) {
          setState(() {
            _isPlaying = value.isPlaying;
          });
        }
      }

      // Track ended state
      if (value.position >= value.duration && value.duration.inSeconds > 0 && !_hasEnded) {
        if (mounted) {
          setState(() {
            _hasEnded = true;
            _isPlaying = false;
          });
        }
      } else if (_hasEnded && value.position < value.duration - const Duration(seconds: 1)) {
        // Reset ended if user seeks back
        if (mounted) {
          setState(() {
            _hasEnded = false;
          });
        }
      }
    });
    
    // Seek to timestamp and start playing
    await _videoPlayerController!.seekTo(Duration(seconds: widget.timestamp.toInt()));
    await _videoPlayerController!.play();
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        _isPlaying = true;
        _totalDuration = _videoPlayerController!.value.duration;
      });
    }
  }

  void _togglePlayPause() {
    if (_hasEnded) {
      _replay();
      return;
    }

    if (_youtubeController != null) {
      if (_isPlaying) {
        _youtubeController!.pause();
      } else {
        _youtubeController!.play();
      }
    } else if (_videoPlayerController != null) {
      if (_isPlaying) {
        _videoPlayerController!.pause();
      } else {
        _videoPlayerController!.play();
      }
    }
  }

  void _replay() {
    setState(() {
      _hasEnded = false;
    });

    if (_youtubeController != null) {
      _youtubeController!.seekTo(const Duration(seconds: 0));
      _youtubeController!.play();
    } else if (_videoPlayerController != null) {
      _videoPlayerController!.seekTo(const Duration(seconds: 0));
      _videoPlayerController!.play();
    }
  }

  void _seekRelative(int seconds) {
    // If video has ended, replay first
    if (_hasEnded) {
      _replay();
      return;
    }

    if (_youtubeController != null) {
      final currentPosition = _youtubeController!.value.position.inSeconds;
      final duration = _youtubeController!.metadata.duration.inSeconds;
      final newPosition = (currentPosition + seconds).clamp(0, duration);
      _youtubeController!.seekTo(Duration(seconds: newPosition));
    } else if (_videoPlayerController != null) {
      final currentPosition = _videoPlayerController!.value.position;
      final duration = _videoPlayerController!.value.duration;
      final newPosition = currentPosition + Duration(seconds: seconds);
      
      // Clamp between 0 and duration
      if (newPosition < Duration.zero) {
        _videoPlayerController!.seekTo(Duration.zero);
      } else if (newPosition > duration) {
        _videoPlayerController!.seekTo(duration);
      } else {
        _videoPlayerController!.seekTo(newPosition);
      }
    }
  }

  void _seekToPosition(Duration position) {
    if (_youtubeController != null) {
      _youtubeController!.seekTo(position);
    } else if (_videoPlayerController != null) {
      _videoPlayerController!.seekTo(position);
    }
    
    // If video has ended and user seeks, reset ended state
    if (_hasEnded) {
      setState(() {
        _hasEnded = false;
      });
    }
  }

  void _seekToTimestamp() {
    final timestampDuration = Duration(seconds: widget.timestamp.toInt());
    _seekToPosition(timestampDuration);
    
    // Show a snackbar to confirm
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Jumped to ${TimeFormatter.formatTimestamp(widget.timestamp)}'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }

  @override
  void dispose() {
    _youtubeController?.pause();
    _videoPlayerController?.pause();
    _youtubeController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Video Player'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: _showVideoInfo,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Loading video...',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Failed to Load Video',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _error = null;
                              _isLoading = true;
                            });
                            _initializePlayer();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Video Player
                    Container(
                      color: Colors.black,
                      child: widget.videoType == 'YouTube' && _youtubeController != null
                          ? YoutubePlayer(
                              controller: _youtubeController!,
                              showVideoProgressIndicator: true,
                              progressIndicatorColor: AppColors.primary,
                              progressColors: ProgressBarColors(
                                playedColor: AppColors.primary,
                                handleColor: AppColors.primary,
                              ),
                              onReady: () {
                                print('YouTube player onReady callback triggered');
                              },
                              onEnded: (metaData) {
                                print('YouTube player ended');
                                if (mounted) {
                                  setState(() {
                                    _hasEnded = true;
                                    _isPlaying = false;
                                  });
                                }
                              },
                            )
                          : _videoPlayerController != null && _videoPlayerController!.value.isInitialized
                              ? AspectRatio(
                                  aspectRatio: _videoPlayerController!.value.aspectRatio,
                                  child: VideoPlayer(_videoPlayerController!),
                                )
                              : const SizedBox(
                                  height: 250,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                    ),
                                  ),
                                ),
                    ),

                    // Video Controls - Right after the player
                    _buildVideoControls(),

                    // Video Info Section
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Timestamp Info - Now Clickable
                            GestureDetector(
                              onTap: _seekToTimestamp,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: AppColors.cardGradient,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.access_time_rounded,
                                          color: AppColors.primary,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'Saved Timestamp',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.touch_app_rounded,
                                                color: AppColors.primary,
                                                size: 16,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Tap to Jump',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      TimeFormatter.formatTimestamp(widget.timestamp),
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Video Type Badge
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: AppColors.cardGradient,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: widget.videoType == 'YouTube'
                                          ? Colors.red.withOpacity(0.2)
                                          : AppColors.primary.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      widget.videoType == 'YouTube'
                                          ? Icons.play_circle_outline
                                          : Icons.file_present,
                                      color: widget.videoType == 'YouTube'
                                          ? Colors.red
                                          : AppColors.primary,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Video Type',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textTertiary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.videoType,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildVideoControls() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Progress Bar
          Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: AppColors.surfaceLight,
                  thumbColor: AppColors.primary,
                  overlayColor: AppColors.primary.withOpacity(0.2),
                ),
                child: Slider(
                  value: _totalDuration.inSeconds > 0
                      ? _currentPosition.inSeconds.toDouble().clamp(0, _totalDuration.inSeconds.toDouble())
                      : 0,
                  min: 0,
                  max: _totalDuration.inSeconds > 0 ? _totalDuration.inSeconds.toDouble() : 1,
                  onChangeStart: (value) {
                    setState(() {
                      _isDragging = true;
                    });
                  },
                  onChanged: (value) {
                    setState(() {
                      _currentPosition = Duration(seconds: value.toInt());
                    });
                  },
                  onChangeEnd: (value) {
                    setState(() {
                      _isDragging = false;
                    });
                    _seekToPosition(Duration(seconds: value.toInt()));
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_currentPosition),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      _formatDuration(_totalDuration),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Control Buttons Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // -10 seconds
              _buildSeekButton(
                icon: Icons.replay_10_rounded,
                onTap: () => _seekRelative(-10),
              ),
              
              const SizedBox(width: 20),
              
              // -5 seconds
              _buildSeekButton(
                icon: Icons.replay_5_rounded,
                onTap: () => _seekRelative(-5),
              ),
              
              const SizedBox(width: 24),
              
              // Play/Pause/Replay Button (Center, Larger)
              GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    _hasEnded
                        ? Icons.replay_rounded
                        : _isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
              
              const SizedBox(width: 24),
              
              // +5 seconds
              _buildSeekButton(
                icon: Icons.forward_5_rounded,
                onTap: () => _seekRelative(5),
              ),
              
              const SizedBox(width: 20),
              
              // +10 seconds
              _buildSeekButton(
                icon: Icons.forward_10_rounded,
                onTap: () => _seekRelative(10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeekButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: AppColors.primary,
          size: 24,
        ),
      ),
    );
  }

  void _showVideoInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
                SizedBox(width: 12),
                Text(
                  'Video Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildInfoRow('Video ID', widget.videoId),
            const Divider(color: AppColors.surfaceLight, height: 32),
            _buildInfoRow('Type', widget.videoType),
            const Divider(color: AppColors.surfaceLight, height: 32),
            _buildInfoRow(
              'Timestamp',
              TimeFormatter.formatTimestamp(widget.timestamp),
            ),
            const Divider(color: AppColors.surfaceLight, height: 32),
            _buildInfoRow('Source', widget.videoSource, maxLines: 2),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {int maxLines = 1}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textTertiary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
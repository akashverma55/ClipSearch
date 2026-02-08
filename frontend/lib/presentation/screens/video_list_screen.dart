import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/route_constants.dart';
import '../bloc/video/video_bloc.dart';
import '../bloc/video/video_event.dart';
import '../bloc/video/video_state.dart';
import '../widgets/video_card.dart';
import '../widgets/loading_indicator.dart';

class VideoListScreen extends StatefulWidget {
  const VideoListScreen({super.key});

  @override
  State<VideoListScreen> createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<VideoBloc>().add(const LoadVideosEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Videos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              context.read<VideoBloc>().add(const LoadVideosEvent());
            },
          ),
        ],
      ),
      body: BlocBuilder<VideoBloc, VideoState>(
        builder: (context, state) {
          if (state is VideoLoading) {
            return const Center(
              child: LoadingIndicator(message: 'Loading videos...'),
            );
          }

          if (state is VideoError) {
            return Center(
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
                    'Failed to load videos',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<VideoBloc>().add(const LoadVideosEvent());
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is VideosLoaded) {
            if (state.videos.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.video_library_rounded,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No videos yet',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Upload your first video to get started',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.push(RouteConstants.upload);
                      },
                      icon: const Icon(Icons.cloud_upload_rounded),
                      label: const Text('Upload Video'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<VideoBloc>().add(const LoadVideosEvent());
              },
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: state.videos.length,
                itemBuilder: (context, index) {
                  final video = state.videos[index];
                  return VideoCard(
                    video: video,
                    onTap: () {
                      context.push(
                        '${RouteConstants.search}?videoId=${video.videoId}',
                      );
                    },
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push(RouteConstants.upload);
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Upload'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}
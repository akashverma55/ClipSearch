import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/route_constants.dart';
import '../../data/models/video_model.dart';
import '../bloc/video/video_bloc.dart';
import '../bloc/video/video_event.dart';
import '../bloc/video/video_state.dart';
import '../bloc/search/search_bloc.dart';
import '../bloc/search/search_event.dart';
import '../bloc/search/search_state.dart';
import '../widgets/search_result_card.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/custom_button.dart';

class SearchScreen extends StatefulWidget {
  final String? preSelectedVideoId;

  const SearchScreen({
    super.key,
    this.preSelectedVideoId,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  VideoModel? _selectedVideo;
  List<VideoModel> _videos = [];

  @override
  void initState() {
    super.initState();
    context.read<VideoBloc>().add(const LoadVideosEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    if (_selectedVideo == null) {
      _showError('Please select a video first');
      return;
    }

    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _showError('Please enter a search query');
      return;
    }

    context.read<SearchBloc>().add(
          SearchVideoEvent(
            videoId: _selectedVideo!.videoId,
            query: query,
          ),
        );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Videos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Search Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.cardGradient,
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
                // Video Selector
                BlocBuilder<VideoBloc, VideoState>(
                  builder: (context, state) {
                    if (state is VideosLoaded) {
                      _videos = state.videos;

                      // Pre-select video if provided
                      if (widget.preSelectedVideoId != null &&
                          _selectedVideo == null) {
                        _selectedVideo = _videos.firstWhere(
                          (v) => v.videoId == widget.preSelectedVideoId,
                          orElse: () => _videos.first,
                        );
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButton<VideoModel>(
                          value: _selectedVideo,
                          hint: const Text('Select a video'),
                          isExpanded: true,
                          underline: const SizedBox(),
                          dropdownColor: AppColors.surface,
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: AppColors.primary,
                          ),
                          items: _videos.map((video) {
                            return DropdownMenuItem<VideoModel>(
                              value: video,
                              child: Text(
                                video.title ?? 'Untitled Video',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (video) {
                            setState(() {
                              _selectedVideo = video;
                            });
                          },
                        ),
                      );
                    }

                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Search Input
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'What are you looking for?',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.primary,
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(
                        Icons.clear_rounded,
                        color: AppColors.textTertiary,
                      ),
                      onPressed: () {
                        _searchController.clear();
                      },
                    ),
                  ),
                  style: const TextStyle(color: AppColors.textPrimary),
                  onSubmitted: (_) => _performSearch(),
                ),
                const SizedBox(height: 16),

                // Search Button
                CustomButton(
                  text: 'Search',
                  icon: Icons.search_rounded,
                  onPressed: _performSearch,
                  width: double.infinity,
                  height: 48,
                ),
              ],
            ),
          ),

          // Search Results
          Expanded(
            child: BlocBuilder<SearchBloc, SearchState>(
              builder: (context, state) {
                if (state is SearchLoading) {
                  return const Center(
                    child: LoadingIndicator(message: 'Searching...'),
                  );
                }

                if (state is SearchError) {
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
                          'Search Failed',
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
                      ],
                    ),
                  );
                }

                if (state is SearchSuccess) {
                  if (state.results.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.search_off_rounded,
                              size: 64,
                              color: AppColors.warning,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'No Results Found',
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
                              'Try different keywords for "${state.query}"',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: state.results.length,
                    itemBuilder: (context, index) {
                      final result = state.results[index];
                      return SearchResultCard(
                        result: result,
                        index: index,
                        onTap: () {
                          context.push(
                            Uri(
                              path: RouteConstants.videoPlayer,
                              queryParameters: {
                                'videoId': _selectedVideo!.videoId,
                                'timestamp': result.timestamp.toString(),
                                'videoSource': result.videoSource,
                                'videoType': result.videoType,
                              },
                            ).toString(),
                          );
                        },
                      );
                    },
                  );
                }

                // Initial State
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
                          Icons.search_rounded,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Search for Moments',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 48),
                        child: Text(
                          'Select a video and enter your search query to find specific moments',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
